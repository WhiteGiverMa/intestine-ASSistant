import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';

enum NavTab { home, data, analysis, settings }

class AppBottomNav extends StatelessWidget {
  final NavTab activeTab;
  final void Function(NavTab tab)? onNavigate;

  const AppBottomNav({super.key, required this.activeTab, this.onNavigate});

  static const List<_NavItem> _navItems = [
    _NavItem(NavTab.home, Icons.home_rounded, '首页'),
    _NavItem(NavTab.data, Icons.bar_chart_rounded, '数据'),
    _NavItem(NavTab.analysis, Icons.psychology_rounded, '分析'),
    _NavItem(NavTab.settings, Icons.settings_rounded, '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                _navItems.map((item) => _buildNavItem(item, colors)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, ThemeColors colors) {
    final isActive = activeTab == item.tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => onNavigate?.call(item.tab),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? colors.primary.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                color: isActive ? colors.primary : colors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? colors.primary : colors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final NavTab tab;
  final IconData icon;
  final String label;

  const _NavItem(this.tab, this.icon, this.label);
}
