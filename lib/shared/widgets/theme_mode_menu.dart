import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/theme_preferences.dart';

/// AppBar 主题切换入口：跟随系统 / 浅色 / 深色。
///
/// The button icon mirrors the active mode; picking an entry writes through
/// [themeModeProvider] (persisted, survives restarts).
class ThemeModeMenu extends ConsumerWidget {
  const ThemeModeMenu({super.key});

  static const _labels = {
    ThemeMode.system: '跟随系统',
    ThemeMode.light: '浅色',
    ThemeMode.dark: '深色',
  };

  static const _modeIcons = {
    ThemeMode.system: Icons.brightness_auto_outlined,
    ThemeMode.light: Icons.light_mode_outlined,
    ThemeMode.dark: Icons.dark_mode_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final gap = context.sizes.space12;
    return PopupMenuButton<ThemeMode>(
      tooltip: '主题',
      icon: Icon(_modeIcons[mode]),
      onSelected: (value) => ref.read(themeModeProvider.notifier).setMode(value),
      itemBuilder: (context) => [
        for (final candidate in ThemeMode.values)
          PopupMenuItem(
            value: candidate,
            child: Row(
              children: [
                Icon(_modeIcons[candidate]),
                SizedBox(width: gap),
                Expanded(child: Text(_labels[candidate]!)),
                if (candidate == mode) const Icon(Icons.check),
              ],
            ),
          ),
      ],
    );
  }
}
