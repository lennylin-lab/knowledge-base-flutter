import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';

/// Pull-to-refresh with the app's flat look: primary spinner on a tonal
/// chip, no elevation shadow, displacement following the window scale.
///
/// Wraps [RefreshIndicator] so every refreshable list (documents,
/// sessions — web wheel overscroll included) gets the same indicator
/// instead of Material's elevated white box.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colors.primary,
      backgroundColor: colors.surfaceContainerHighest,
      elevation: 0,
      displacement: sizes.space48,
      strokeWidth: 2.5,
      child: child,
    );
  }
}
