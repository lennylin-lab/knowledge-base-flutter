import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_base_flutter/core/auth/auth_controller.dart';
import 'package:knowledge_base_flutter/core/auth/auth_session.dart';
import 'package:knowledge_base_flutter/core/auth/auth_transaction.dart';
import 'package:knowledge_base_flutter/core/auth/oidc_client.dart';
import 'package:knowledge_base_flutter/core/auth/sign_in_driver.dart';
import 'package:knowledge_base_flutter/core/auth/token_store.dart';
import 'package:knowledge_base_flutter/core/config/oidc_config.dart';
import 'package:knowledge_base_flutter/core/network/api_exception.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';

/// In-memory token store recording every mutation.
class FakeTokenStore implements TokenStore {
  AuthSession? session;
  int writes = 0;
  int clears = 0;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession session) async {
    this.session = session;
    writes++;
  }

  @override
  Future<void> clear() async {
    session = null;
    clears++;
  }
}

class FakeTransactionStore implements AuthTransactionStore {
  AuthTransaction? stashed;
  int taken = 0;

  @override
  Future<void> save(AuthTransaction transaction) async => stashed = transaction;

  @override
  Future<AuthTransaction?> take() async {
    taken++;
    final tx = stashed;
    stashed = null;
    return tx;
  }
}

/// Scripted OidcClient: deterministic PKCE tokens, canned exchange/refresh
/// results, and call counters.
class FakeOidcClient implements OidcClient {
  final endpoints = OidcEndpoints(
    authorization: Uri.parse('https://idp.test/auth'),
    token: Uri.parse('https://idp.test/token'),
  );

  final discoverCalls = <Uri>[];
  final exchanges = <({String code, String verifier})>[];
  final refreshes = <String>[];

  Object? exchangeError;
  Object? refreshError;

  @override
  Future<OidcEndpoints> discover(Uri issuer) async {
    discoverCalls.add(issuer);
    return endpoints;
  }

  @override
  String createVerifier() => 'VERIFIER-1';

  @override
  String createChallenge(String verifier) => 'CHALLENGE-1';

  @override
  String createState() => 'STATE-1';

  @override
  Uri authorizeUrl({
    required OidcEndpoints endpoints,
    required String clientId,
    required String redirectUri,
    required String scopes,
    required String state,
    required String codeChallenge,
  }) {
    return Uri.parse(
      'https://idp.test/auth?client_id=$clientId&state=$state'
      '&code_challenge=$codeChallenge&code_challenge_method=S256',
    );
  }

  @override
  Future<OidcTokenResponse> exchangeCode({
    required OidcEndpoints endpoints,
    required String clientId,
    required String redirectUri,
    required String code,
    required String verifier,
  }) async {
    exchanges.add((code: code, verifier: verifier));
    final error = exchangeError;
    if (error != null) throw error;
    return const OidcTokenResponse(
      accessToken: 'at-1',
      refreshToken: 'rt-1',
      expiresIn: 3600,
    );
  }

  @override
  Future<OidcTokenResponse> refresh({
    required OidcEndpoints endpoints,
    required String clientId,
    required String refreshToken,
  }) async {
    refreshes.add(refreshToken);
    final error = refreshError;
    if (error != null) throw error;
    return OidcTokenResponse(
      accessToken: 'at-${refreshes.length + 1}',
      expiresIn: 3600,
    );
  }
}

/// Scripted browser: hands back whatever redirect URI the test sets.
class FakeDriver implements SignInDriver {
  FakeDriver(this.redirect);

  Uri redirect;

  @override
  Future<Uri> acquire(Uri authorizeUrl) async {
    authorizeUrls.add(authorizeUrl);
    return redirect;
  }

  final authorizeUrls = <Uri>[];
}

/// Mutable clock seam (tests move it past expiry instead of sleeping).
class MutableClock {
  DateTime? fixed;

  DateTime call() => fixed ?? DateTime.now();
}

const _enabledConfig = OidcConfig(
  issuer: 'http://localhost:8180/realms/kb',
  clientId: 'kb-web',
  redirectUri: 'http://localhost:8182/auth/callback',
  scopes: 'openid',
);

Uri _redirectWith({String? code, String? state, String? error}) => Uri(
  path: '/auth/callback',
  queryParameters: {
    'code': ?code,
    'state': ?state,
    'error': ?error,
  },
);

class _Harness {
  _Harness({OidcConfig config = _enabledConfig}) {
    clock = MutableClock();
    store = FakeTokenStore();
    transactions = FakeTransactionStore();
    oidc = FakeOidcClient();
    driver = FakeDriver(_redirectWith(code: 'CODE-1', state: 'STATE-1'));
    container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        oidcConfigProvider.overrideWithValue(config),
        tokenStoreProvider.overrideWithValue(store),
        authTransactionStoreProvider.overrideWithValue(transactions),
        oidcClientProvider.overrideWithValue(oidc),
        signInDriverProvider.overrideWithValue(driver),
        authClockProvider.overrideWithValue(clock.call),
      ],
    );
    addTearDown(container.dispose);
  }

  late final MutableClock clock;
  late final FakeTokenStore store;
  late final FakeTransactionStore transactions;
  late final FakeOidcClient oidc;
  late final FakeDriver driver;
  late final ProviderContainer container;

  AuthController get controller => container.read(authControllerProvider.notifier);
  AuthState get state => container.read(authControllerProvider);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signIn happy path: exchanges the code, persists, signs in', () async {
    final h = _Harness();
    await h.controller.signIn();

    expect(h.state.isSignedIn, isTrue);
    expect(h.state.session!.accessToken, 'at-1');
    expect(h.state.session!.refreshToken, 'rt-1');
    expect(h.state.signingIn, isFalse);

    expect(h.oidc.exchanges.single.code, 'CODE-1');
    expect(h.oidc.exchanges.single.verifier, 'VERIFIER-1');
    expect(h.store.writes, 1);

    // The authorize URL carries the PKCE material generated by the client.
    final url = h.driver.authorizeUrls.single;
    expect(url.host, 'idp.test');
    expect(url.queryParameters['code_challenge'], 'CHALLENGE-1');
    expect(url.queryParameters['code_challenge_method'], 'S256');
  });

  test('signIn state mismatch → signed out with guidance, nothing persisted',
      () async {
    final h = _Harness();
    h.driver.redirect = _redirectWith(code: 'CODE-1', state: 'EVIL');
    await h.controller.signIn();

    expect(h.state.isSignedIn, isFalse);
    expect(h.state.errorMessage, contains('登录状态校验失败'));
    expect(h.store.writes, 0);
  });

  test('signIn IdP error (access_denied) surfaces the OAuth error', () async {
    final h = _Harness();
    h.driver.redirect = _redirectWith(error: 'access_denied');
    await h.controller.signIn();

    expect(h.state.isSignedIn, isFalse);
    expect(h.state.errorMessage, contains('access_denied'));
  });

  test('getValidAccessToken returns the cached token while fresh, then '
      'refreshes once past expiry', () async {
    final h = _Harness();
    await h.controller.signIn();

    expect(
      await h.controller.getValidAccessToken(),
      'at-1',
      reason: 'expiresIn 3600s — no refresh yet',
    );
    expect(h.oidc.refreshes, isEmpty);

    // Jump past the expiry (the validity skew is one minute).
    h.clock.fixed = DateTime.now().add(const Duration(hours: 2));
    expect(await h.controller.getValidAccessToken(), 'at-2');
    expect(h.oidc.refreshes, ['rt-1']);
    expect(h.state.session!.accessToken, 'at-2');
  });

  test('concurrent refreshes share one token-endpoint round trip', () async {
    final h = _Harness();
    await h.controller.signIn();
    h.clock.fixed = DateTime.now().add(const Duration(hours: 2));

    final results = await Future.wait([
      h.controller.getValidAccessToken(),
      h.controller.getValidAccessToken(),
      h.controller.refreshAccessToken(),
    ]);
    expect(results, everyElement('at-2'));
    expect(h.oidc.refreshes, hasLength(1));
  });

  test('refresh failure clears the session (store cleared, signed out)',
      () async {
    final h = _Harness();
    await h.controller.signIn();
    h.oidc.refreshError = const ApiException(
      code: 'unauthorized',
      message: 'expired',
    );
    h.clock.fixed = DateTime.now().add(const Duration(hours: 2));

    expect(await h.controller.getValidAccessToken(), isNull);
    expect(h.state.isSignedIn, isFalse);
    expect(h.store.clears, 1);
  });

  test('signOut clears the persisted session and state', () async {
    final h = _Harness();
    await h.controller.signIn();
    await h.controller.signOut();
    expect(h.state.isSignedIn, isFalse);
    expect(h.store.session, isNull);
  });

  test('completeWebCallback consumes the stash once and returns returnTo',
      () async {
    final h = _Harness();
    await h.transactions.save(
      const AuthTransaction(
        state: 'STATE-1',
        verifier: 'VERIFIER-1',
        returnTo: '/search',
      ),
    );
    final returnTo = await h.controller.completeWebCallback(
      code: 'CODE-1',
      state: 'STATE-1',
      error: null,
    );

    expect(returnTo, '/search');
    expect(h.state.session!.accessToken, 'at-1');
    expect(h.transactions.taken, 1);
    expect(h.transactions.stashed, isNull, reason: 'one-shot stash');
  });

  test('completeWebCallback rejects a replayed or foreign callback',
      () async {
    final h = _Harness();
    // No stash at all.
    await expectLater(
      h.controller.completeWebCallback(code: 'CODE-1', state: 'STATE-1', error: null),
      throwsA(isA<ApiException>()),
    );

    // State mismatch against a real stash.
    await h.transactions.save(
      const AuthTransaction(
        state: 'STATE-1',
        verifier: 'VERIFIER-1',
        returnTo: '/documents',
      ),
    );
    await expectLater(
      h.controller.completeWebCallback(code: 'CODE-1', state: 'OTHER', error: null),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('登录状态校验失败'),
        ),
      ),
    );
    expect(h.state.isSignedIn, isFalse);
  });

  test('compat mode: signIn is a no-op even if invoked', () async {
    final h = _Harness(
      config: const OidcConfig(
        issuer: '',
        clientId: 'kb-web',
        redirectUri: 'http://localhost:8182/auth/callback',
        scopes: 'openid',
      ),
    );
    await h.controller.signIn();
    expect(h.state.isSignedIn, isFalse);
    expect(h.oidc.exchanges, isEmpty);
    expect(h.oidc.discoverCalls, isEmpty);
  });
}
