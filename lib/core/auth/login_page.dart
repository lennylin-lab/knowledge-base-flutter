import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_sizes.dart';
import 'auth_controller.dart';

/// Full-screen login gate shown instead of the app content while OIDC is
/// enabled and no session exists. The real login UI is the IdP's — this
/// page only launches the browser round trip and reports failures.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key, required this.signingIn, this.errorMessage});

  final bool signingIn;
  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizes = context.sizes;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: sizes.space120 * 3),
          child: Padding(
            padding: EdgeInsets.all(sizes.space24),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(sizes.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: sizes.iconHero,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: sizes.space16),
                    Text(
                      '知识库',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    SizedBox(height: sizes.space8),
                    Text(
                      signingIn ? '已打开登录页面，请在浏览器中完成登录…' : '登录后即可访问文档、搜索与问答',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (signingIn) ...[
                      SizedBox(height: sizes.space16),
                      const Center(child: CircularProgressIndicator()),
                    ] else ...[
                      SizedBox(height: sizes.space24),
                      FilledButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('登录'),
                        onPressed: () => ref
                            .read(authControllerProvider.notifier)
                            .signIn(),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      SizedBox(height: sizes.space16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
