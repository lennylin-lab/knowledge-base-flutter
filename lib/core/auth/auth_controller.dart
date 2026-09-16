import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException, PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/oidc_config.dart';
import '../network/api_exception.dart';
import 'auth_session.dart';
import 'auth_transaction.dart';
import 'oidc_client.dart';
import 'sign_in_driver.dart';
import 'token_store.dart';

/// Everything the login gate needs to know. `session == null` ⇒ signed
/// out (compat mode never reaches this gate — see `authEnabledProvider`).
class AuthState {
  const AuthState({this.session, this.signingIn = false, this.errorMessage});

  final AuthSession? session;

  /// The browser round trip is in flight (IdP page open).
  final bool signingIn;
  final String? errorMessage;

  bool get isSignedIn => session != null;

  /// `errorMessage` is cleared whenever null is passed (i.e. omitted or
  /// explicit null); session/signingIn keep their values unless provided.
  AuthState copyWith({AuthSession? session, bool? signingIn, String? errorMessage}) {
    return AuthState(
      session: session ?? this.session,
      signingIn: signingIn ?? this.signingIn,
      errorMessage: errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers (collaborator seams are plain providers so tests override them).
// ---------------------------------------------------------------------------

final tokenStoreProvider = Provider<TokenStore>((ref) => createTokenStore());

final authTransactionStoreProvider = Provider<AuthTransactionStore>(
  (ref) => createAuthTransactionStore(),
);

final oidcClientProvider = Provider<OidcClient>((ref) => OidcClient());

final signInDriverProvider = Provider<SignInDriver>(
  (ref) => createSignInDriver(ref.watch(oidcConfigProvider).redirectUri),
);

/// Injectable clock for expiry math in tests.
final authClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Seed loaded in `main()` from the persisted store.
final authSeedProvider = Provider<AuthState>((ref) => const AuthState());

/// Compat mode flag: auth plumbing exists only when an issuer is set.
final authEnabledProvider = Provider<bool>(
  (ref) => ref.watch(oidcConfigProvider).isEnabled,
);

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Builds the Authorization headers for one outgoing REST/SSE request from
/// a fresh (refreshed-if-needed) access token; null in compat mode, and an
/// empty map when the user is unauthenticated (callers then hit the 401
/// path instead of guessing).
typedef AuthHeadersBuilder = Future<Map<String, String>> Function();

final authHeadersBuilderProvider = Provider<AuthHeadersBuilder?>((ref) {
  if (!ref.watch(authEnabledProvider)) return null;
  return () async {
    final token = await ref
        .read(authControllerProvider.notifier)
        .getValidAccessToken();
    return token == null
        ? const <String, String>{}
        : {'Authorization': 'Bearer $token'};
  };
});

// ---------------------------------------------------------------------------

/// Sign-in / token-lifecycle controller. Owns the persisted session; the
/// REST interceptor and SSE clients consume it through
/// [authHeadersBuilderProvider] and `apiClientProvider`.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => ref.watch(authSeedProvider);

  Future<String?>? _refreshInFlight;

  /// Runs the Authorization Code + PKCE round trip for the current
  /// platform. Errors land in [AuthState.errorMessage] (signed out).
  Future<void> signIn() async {
    if (!ref.read(authEnabledProvider) || state.signingIn) return;
    final config = ref.read(oidcConfigProvider);
    final client = ref.read(oidcClientProvider);
    final issuer = Uri.parse(config.issuer.trim());

    state = state.copyWith(signingIn: true, errorMessage: null);
    try {
      final endpoints = await client.discover(issuer);
      final verifier = client.createVerifier();
      final stateToken = client.createState();
      final authorizeUrl = client.authorizeUrl(
        endpoints: endpoints,
        clientId: config.clientId,
        redirectUri: config.redirectUri,
        scopes: config.scopes,
        state: stateToken,
        codeChallenge: client.createChallenge(verifier),
      );

      if (kIsWeb) {
        // The page navigates away — stash what the callback needs.
        await ref.read(authTransactionStoreProvider).save(
          AuthTransaction(
            state: stateToken,
            verifier: verifier,
            returnTo: '/documents',
          ),
        );
      }

      final redirect = await ref.read(signInDriverProvider).acquire(authorizeUrl);
      final session = await _finishAuthorization(
        redirect: redirect,
        expectedState: stateToken,
        verifier: verifier,
        endpoints: endpoints,
        previousSubject: state.session?.subject,
      );
      await ref.read(tokenStoreProvider).write(session);
      state = AuthState(session: session);
    } on TimeoutException {
      state = const AuthState(errorMessage: '登录超时，请重试');
    } on BrowserLaunchFailure {
      state = const AuthState(errorMessage: '无法打开浏览器，请重试');
    } on ApiException catch (e) {
      state = AuthState(errorMessage: e.message);
    } catch (e, s) {
      // Never swallow the cause silently: short hint in the UI, full
      // detail in the console (browser devtools / flutter run log).
      debugPrint('signIn failed: $e\n$s');
      state = AuthState(errorMessage: '无法完成登录（${_errorHint(e)}），请重试');
    }
  }

  /// Short Chinese hint for unexpected sign-in failures — the UI shows
  /// this; the full stack goes to the console via [debugPrint].
  static String _errorHint(Object error) {
    if (error is MissingPluginException) {
      return '登录组件未注册，请执行 flutter pub get 后重启应用';
    }
    if (error is PlatformException) {
      return '平台异常 ${error.code}: ${error.message ?? ''}';
    }
    final text = error.toString().split('\n').first;
    return '${error.runtimeType}: $text';
  }

  /// Completes the web redirect flow on `/auth/callback`. Returns the
  /// location to navigate to on success; throws [ApiException] on failure
  /// (the callback page renders it). Validates the transaction before any
  /// network call — a stale or replayed callback fails fast.
  Future<String> completeWebCallback({
    required String? code,
    required String? state,
    required String? error,
  }) async {
    if (error != null && error.isNotEmpty) {
      throw ApiException(code: 'unauthorized', message: '登录未完成：$error');
    }
    final transaction = await ref.read(authTransactionStoreProvider).take();
    if (transaction == null) {
      throw const ApiException(
        code: 'unauthorized',
        message: '登录会话已失效，请重新登录',
      );
    }
    if (state != transaction.state) {
      throw const ApiException(
        code: 'unauthorized',
        message: '登录状态校验失败，请重新登录',
      );
    }
    if (code == null || code.isEmpty) {
      throw const ApiException(code: 'unauthorized', message: '登录未完成，请重新登录');
    }
    final config = ref.read(oidcConfigProvider);
    final client = ref.read(oidcClientProvider);
    final session = await _finishAuthorization(
      redirect: Uri(
        queryParameters: {
          'code': code,
          'state': ?state,
          'error': error,
        },
      ),
      expectedState: transaction.state,
      verifier: transaction.verifier,
      endpoints: await client.discover(Uri.parse(config.issuer.trim())),
      previousSubject: this.state.session?.subject,
    );
    await ref.read(tokenStoreProvider).write(session);
    this.state = AuthState(session: session);
    final returnTo = transaction.returnTo;
    return returnTo.startsWith('/') ? returnTo : '/documents';
  }

  /// A usable access token: cached while valid, otherwise one
  /// single-flight refresh. Null ⇒ unauthenticated (and the session, if
  /// any, was cleared).
  Future<String?> getValidAccessToken() async {
    final session = state.session;
    if (session != null &&
        session.isValidAt(ref.read(authClockProvider)())) {
      return session.accessToken;
    }
    return refreshAccessToken();
  }

  /// Forces a refresh (REST 401-retry path). Single-flight: concurrent
  /// callers share one token-endpoint round trip.
  Future<String?> refreshAccessToken() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final future = _doRefresh();
    _refreshInFlight = future;
    future.whenComplete(() => _refreshInFlight = null);
    return future;
  }

  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AuthState();
  }

  // -----------------------------------------------------------------------

  Future<AuthSession> _finishAuthorization({
    required Uri redirect,
    required String? expectedState,
    required String? verifier,
    required OidcEndpoints endpoints,
    required String? previousSubject,
  }) async {
    final query = redirect.queryParameters;
    final oidcError = query['error'];
    if (oidcError != null && oidcError.isNotEmpty) {
      throw ApiException(
        code: 'unauthorized',
        message: '登录未完成：${query['error_description'] ?? oidcError}',
      );
    }
    if (expectedState == null || verifier == null) {
      throw const ApiException(
        code: 'unauthorized',
        message: '登录会话已失效，请重新登录',
      );
    }
    if (query['state'] != expectedState) {
      throw const ApiException(
        code: 'unauthorized',
        message: '登录状态校验失败，请重新登录',
      );
    }
    final code = query['code'];
    if (code == null || code.isEmpty) {
      throw const ApiException(
        code: 'unauthorized',
        message: '登录未完成，请重新登录',
      );
    }
    final config = ref.read(oidcConfigProvider);
    final response = await ref.read(oidcClientProvider).exchangeCode(
      endpoints: endpoints,
      clientId: config.clientId,
      redirectUri: config.redirectUri,
      code: code,
      verifier: verifier,
    );
    return AuthSession.fromTokenResponse(
      accessToken: response.accessToken,
      expiresIn: Duration(seconds: response.expiresIn),
      refreshToken: response.refreshToken,
      previousSubject: previousSubject,
    );
  }

  Future<String?> _doRefresh() async {
    final session = state.session;
    final refreshToken = session?.refreshToken;
    if (session == null || refreshToken == null) return null;
    try {
      final config = ref.read(oidcConfigProvider);
      final client = ref.read(oidcClientProvider);
      final response = await client.refresh(
        endpoints: await client.discover(Uri.parse(config.issuer.trim())),
        clientId: config.clientId,
        refreshToken: refreshToken,
      );
      final renewed = AuthSession(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken ?? refreshToken,
        expiresAt:
            ref.read(authClockProvider)().add(Duration(seconds: response.expiresIn)),
        subject: session.subject,
      );
      await ref.read(tokenStoreProvider).write(renewed);
      state = state.copyWith(session: renewed, errorMessage: null);
      return renewed.accessToken;
    } on ApiException catch (_) {
      await signOut();
      return null;
    } catch (_) {
      // Network hiccup vs. revoked refresh token is indistinguishable for
      // the MVP — the user signs in again either way.
      await signOut();
      return null;
    }
  }
}
