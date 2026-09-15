import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:knowledge_base_flutter/core/auth/auth_callback_page.dart';
import 'package:knowledge_base_flutter/core/auth/auth_controller.dart';
import 'package:knowledge_base_flutter/core/auth/auth_gate.dart';
import 'package:knowledge_base_flutter/core/auth/auth_session.dart';
import 'package:knowledge_base_flutter/core/auth/login_page.dart';
import 'package:knowledge_base_flutter/core/config/oidc_config.dart';
import 'package:knowledge_base_flutter/core/retry_policy.dart';

const _disabled = OidcConfig(
  issuer: '',
  clientId: 'kb-web',
  redirectUri: 'http://localhost:8182/auth/callback',
  scopes: 'openid',
);

const _enabled = OidcConfig(
  issuer: 'http://localhost:8180/realms/kb',
  clientId: 'kb-web',
  redirectUri: 'http://localhost:8182/auth/callback',
  scopes: 'openid',
);

final _session = AuthSession(
  accessToken: 'at-1',
  refreshToken: 'rt-1',
  expiresAt: DateTime.now().add(const Duration(hours: 1)),
  subject: 'sub-1',
);

/// Mirrors the real wiring in `app.dart`: the gate wraps the app shell
/// (here: the /documents route content), while /auth/callback lives
/// outside it.
GoRouter _router({String initialLocation = '/documents'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/auth/callback',
      builder: (context, state) => AuthCallbackPage(
        code: state.uri.queryParameters['code'],
        state: state.uri.queryParameters['state'],
        error: state.uri.queryParameters['error'],
      ),
    ),
    GoRoute(
      path: '/documents',
      builder: (_, _) => const AuthGate(child: Text('APP-CONTENT')),
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required OidcConfig config,
  AuthSession? session,
  String initialLocation = '/documents',
}) async {
  final goRouter = _router(initialLocation: initialLocation);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        oidcConfigProvider.overrideWithValue(config),
        if (session != null)
          authSeedProvider.overrideWithValue(AuthState(session: session)),
      ],
      child: MaterialApp.router(routerConfig: goRouter),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('compat mode renders the app content, no login gate',
      (tester) async {
    await _pump(tester, config: _disabled);
    expect(find.text('APP-CONTENT'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('enabled + no session → login gate instead of content',
      (tester) async {
    await _pump(tester, config: _enabled);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('APP-CONTENT'), findsNothing);
    expect(find.text('登录'), findsOneWidget);
  });

  testWidgets('enabled + valid session renders the app content',
      (tester) async {
    await _pump(tester, config: _enabled, session: _session);
    expect(find.text('APP-CONTENT'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('cold start at /auth/callback runs the callback page while '
      'signed out (route lives outside the gate)', (tester) async {
    await _pump(
      tester,
      config: _enabled,
      initialLocation: '/auth/callback?code=c1&state=s1',
    );
    expect(find.byType(LoginPage), findsNothing,
        reason: 'the callback route must not be covered by the login gate');
    expect(find.byType(AuthCallbackPage), findsOneWidget);
    expect(find.text('返回首页'), findsOneWidget,
        reason: 'the exchange fails fast without a transaction');
  });
}
