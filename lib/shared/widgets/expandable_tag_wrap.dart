import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';

/// Result of laying out tags within a fixed width and line budget.
typedef TagLayoutResult = ({List<String> visibleTags, bool hasMore});

/// Computes how many `#tag` labels fit in [maxLines].
TagLayoutResult layoutTagsForMaxLines({
  required List<String> tags,
  required double maxWidth,
  required int maxLines,
  required TextStyle tagStyle,
  required double spacing,
  required TextScaler textScaler,
}) {
  if (tags.isEmpty || maxWidth <= 0 || maxLines <= 0) {
    return (visibleTags: <String>[], hasMore: false);
  }

  final tagWidths = [
    for (final tag in tags) _measureText('#$tag', tagStyle, textScaler),
  ];

  if (!_wrapExceedsLineBudget(
    tagWidths: tagWidths,
    maxWidth: maxWidth,
    maxLines: maxLines,
    spacing: spacing,
  )) {
    return (visibleTags: tags, hasMore: false);
  }

  var low = 0;
  var high = tags.length;
  var best = 0;

  while (low <= high) {
    final mid = (low + high) ~/ 2;
    if (_lineCount(
          itemWidths: tagWidths.sublist(0, mid),
          maxWidth: maxWidth,
          spacing: spacing,
        ) <=
        maxLines) {
      best = mid;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }

  return (visibleTags: tags.sublist(0, best), hasMore: true);
}

bool _wrapExceedsLineBudget({
  required List<double> tagWidths,
  required double maxWidth,
  required int maxLines,
  required double spacing,
}) {
  return _lineCount(
        itemWidths: tagWidths,
        maxWidth: maxWidth,
        spacing: spacing,
      ) >
      maxLines;
}

int _lineCount({
  required List<double> itemWidths,
  required double maxWidth,
  required double spacing,
}) {
  if (itemWidths.isEmpty) return 0;

  var line = 1;
  var x = 0.0;
  for (final width in itemWidths) {
    final gap = x > 0 ? spacing : 0;
    if (x + gap + width > maxWidth) {
      line++;
      x = width;
    } else {
      x += gap + width;
    }
  }
  return line;
}

double _measureText(String text, TextStyle style, TextScaler textScaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();
  return painter.width;
}

/// Wraps `#tag` labels, collapsing to [maxLines] with an expand/collapse row below.
class ExpandableTagWrap extends StatefulWidget {
  const ExpandableTagWrap({
    super.key,
    required this.tags,
    this.maxLines = 2,
    this.spacing = 8,
    this.runSpacing = 4,
  });

  final List<String> tags;
  final int maxLines;
  final double spacing;
  final double runSpacing;

  @override
  State<ExpandableTagWrap> createState() => _ExpandableTagWrapState();
}

class _ExpandableTagWrapState extends State<ExpandableTagWrap> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.tags.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final tagStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.primary,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsedLayout = layoutTagsForMaxLines(
          tags: widget.tags,
          maxWidth: constraints.maxWidth,
          maxLines: widget.maxLines,
          tagStyle: tagStyle,
          spacing: widget.spacing,
          textScaler: textScaler,
        );
        final visibleTags = _expanded
            ? widget.tags
            : collapsedLayout.visibleTags;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: widget.spacing,
              runSpacing: widget.runSpacing,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final tag in visibleTags) Text('#$tag', style: tagStyle),
              ],
            ),
            if (collapsedLayout.hasMore)
              _TagToggleButton(
                expanded: _expanded,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
          ],
        );
      },
    );
  }
}

class _TagToggleButton extends StatelessWidget {
  const _TagToggleButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.sizes;
    final label = expanded ? '收起' : '展开';

    return Semantics(
      button: true,
      label: expanded ? '收起全部标签' : '展开全部标签',
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onTap,
          icon: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            size: sizes.iconSm,
          ),
          label: Text(label),
          style: TextButton.styleFrom(
            padding: EdgeInsets.fromLTRB(0, 0, sizes.space4, 0),
            minimumSize: const Size(48, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            foregroundColor: theme.colorScheme.primary,
            textStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
