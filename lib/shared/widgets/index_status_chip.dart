import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../models/document.dart';

/// `index_status` indicator (component-guidelines spec):
///
/// - `pending` — small progress indicator + 索引中；
/// - `done` — nothing (searchable is the normal state);
/// - `failed` — error chip 索引失败 with a retry affordance: the backend has
///   no retry-index endpoint, so the affordance deep-links back to the
///   editor where a re-save re-enqueues indexing (database-guidelines spec).
class IndexStatusChip extends StatelessWidget {
  const IndexStatusChip({super.key, required this.status, this.onRetry});

  final IndexStatus status;

  /// Tapped retry affordance for `failed` (open the editor to re-save).
  /// May be null when no navigation context is available; the chip then
  /// renders as a plain non-interactive badge.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      IndexStatus.done => const SizedBox.shrink(),
      IndexStatus.pending => _pending(context),
      IndexStatus.failed => _failed(context),
    };
  }

  Widget _pending(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: sizes.spinnerXs,
          height: sizes.spinnerXs,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: sizes.space6),
        Text(
          '索引中',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _failed(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    // Generous padding grows the tap area; the decorated box sizes itself
    // to its content (never Center — inside a ListTile trailing an
    // unbounded Center swallows the whole tile width).
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: sizes.space8,
        vertical: sizes.space6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: sizes.iconXs,
            color: theme.colorScheme.onErrorContainer,
          ),
          SizedBox(width: sizes.space4),
          Text(
            '索引失败',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(width: sizes.space4),
            Icon(
              Icons.refresh,
              size: sizes.iconXs,
              color: theme.colorScheme.onErrorContainer,
            ),
          ],
        ],
      ),
    );

    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(sizes.radiusSm),
      ),
      child: onRetry == null
          ? content
          : InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(sizes.radiusSm),
              child: content,
            ),
    );

    return Tooltip(message: '索引失败，点击重新编辑并保存以重试索引', child: chip);
  }
}
