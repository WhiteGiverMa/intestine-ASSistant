import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';

class CompactTabSwitcher extends StatelessWidget {
  final int currentIndex;
  final List<CompactTabItem> tabs;
  final ValueChanged<int> onTabChanged;

  const CompactTabSwitcher({
    super.key,
    required this.currentIndex,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (index) {
          return _buildTabButton(tabs[index], index, colors);
        }),
      ),
    );
  }

  Widget _buildTabButton(CompactTabItem tab, int index, ThemeColors colors) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: tab.icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 14,
                    color: isSelected
                        ? colors.textOnPrimary
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: isSelected
                          ? colors.textOnPrimary
                          : colors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Text(
                tab.label,
                style: TextStyle(
                  color: isSelected
                      ? colors.textOnPrimary
                      : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
      ),
    );
  }
}

class CompactTabItem {
  final String label;
  final IconData? icon;

  const CompactTabItem({
    required this.label,
    this.icon,
  });
}
