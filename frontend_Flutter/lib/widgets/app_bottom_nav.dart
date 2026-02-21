import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_decorations.dart';

enum NavTab { home, data, analysis, settings }

class AppBottomNav extends StatelessWidget {
  final NavTab activeTab;
  final void Function(NavTab tab)? onNavigate;

  const AppBottomNav({super.key, required this.activeTab, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      decoration: ThemeDecorations.bottomNav(context, mode: context.themeMode),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, '🏠', '首页', NavTab.home, colors),
            _buildNavItem(context, '📊', '数据', NavTab.data, colors),
            _buildNavItem(context, '🤖', '分析', NavTab.analysis, colors),
            _buildNavItem(context, '⚙️', '设置', NavTab.settings, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String emoji,
    String label,
    NavTab tab,
    dynamic colors,
  ) {
    final isActive = activeTab == tab;

    return GestureDetector(
      onTap: isActive || onNavigate == null ? null : () => onNavigate!(tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? colors.primary : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
