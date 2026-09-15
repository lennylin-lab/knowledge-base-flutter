import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../network/api_exception.dart';
import '../theme/app_sizes.dart';
import 'auth_controller.dart';

/// Web redirect landing (`/auth/callback?code=…&state=…`): completes the
/// exchange started before the browser left the app, then returns to the
/// saved location. Error state offers a retry via the normal sign-in flow.
class AuthCallbackPage extends ConsumerStatefulWidget {
  const AuthCallbackPage({
    super.key,
    required this.code,
    required this.state,
    this.error,
  });

  final String? code;
  final String? state;
  final String? error;

  @override
  ConsumerState<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<AuthCallbackPage> {
  bool _started = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Complete once per landing — a rebuild (theme switch, gate flip) must
    // not consume the one-shot transaction twice.
    WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  Future<void> _complete() async {
    if (_started || !mounted) return;
    _started = true;
    try {
      final returnTo = await ref
          .read(authControllerProvider.notifier)
          .completeWebCallback(
            code: widget.code,
            state: widget.state,
            error: widget.error,
          );
      if (mounted) context.go(returnTo);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '登录未完成，请重新登录');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage == null) ...[
              const CircularProgressIndicator(),
              SizedBox(height: sizes.space16),
              Text('正在完成登录…', style: theme.textTheme.bodyMedium),
            ] else ...[
              Icon(
                Icons.error_outline,
                size: sizes.iconHero,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: sizes.space16),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: sizes.space16),
              FilledButton(
                onPressed: () => context.go('/documents'),
                child: const Text('返回首页'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
