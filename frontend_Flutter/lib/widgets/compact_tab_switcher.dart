import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';

class CompactTabBar extends StatefulWidget {
  final int currentIndex;
  final List<CompactTabItem> tabs;
  final ValueChanged<int> onTabChanged;

  const CompactTabBar({
    super.key,
    required this.currentIndex,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  State<CompactTabBar> createState() => _CompactTabBarState();
}

class _CompactTabBarState extends State<CompactTabBar> {
  final List<GlobalKey> _tabKeys = [];
  double _indicatorWidth = 0;
  double _indicatorLeft = 0;

  @override
  void initState() {
    super.initState();
    _tabKeys.addAll(List.generate(widget.tabs.length, (_) => GlobalKey()));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateIndicatorPosition(),
    );
  }

  @override
  void didUpdateWidget(CompactTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateIndicatorPosition(),
      );
    }
  }

  void _updateIndicatorPosition() {
    if (!mounted || widget.currentIndex >= _tabKeys.length) return;

    final currentKey = _tabKeys[widget.currentIndex];
    final renderBox =
        currentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final containerContext = context.findRenderObject() as RenderBox?;
    if (containerContext == null) return;

    final tabPosition = renderBox.localToGlobal(
      Offset.zero,
      ancestor: containerContext,
    );

    final containerWidth = containerContext.size.width;
    final tabWidth = renderBox.size.width;

    double indicatorLeft = tabPosition.dx;
    final double indicatorWidth = tabWidth;

    if (indicatorLeft + indicatorWidth > containerWidth) {
      indicatorLeft = containerWidth - indicatorWidth;
    }
    if (indicatorLeft < 0) {
      indicatorLeft = 0;
    }

    setState(() {
      _indicatorWidth = indicatorWidth;
      _indicatorLeft = indicatorLeft;
    });
  }

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
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            left: _indicatorLeft,
            top: 0,
            bottom: 0,
            width: _indicatorWidth,
            child: Container(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.tabs.length, (index) {
              return _buildTabButton(widget.tabs[index], index, colors);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(CompactTabItem tab, int index, ThemeColors colors) {
    final isSelected = index == widget.currentIndex;

    return GestureDetector(
      key: _tabKeys[index],
      onTap: () => widget.onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            tab.icon != null
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 14,
                      color:
                          isSelected
                              ? colors.textOnPrimary
                              : colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        color:
                            isSelected
                                ? colors.textOnPrimary
                                : colors.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                )
                : Text(
                  tab.label,
                  style: TextStyle(
                    color:
                        isSelected
                            ? colors.textOnPrimary
                            : colors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
      ),
    );
  }
}

class CompactTabContent extends StatelessWidget {
  final int currentIndex;
  final List<CompactTabItem> tabs;

  const CompactTabContent({
    super.key,
    required this.currentIndex,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex,
      children: tabs.map((tab) => tab.content).toList(),
    );
  }
}

class CompactTabItem {
  final String label;
  final IconData? icon;
  final Widget content;

  const CompactTabItem({required this.label, required this.content, this.icon});
}
