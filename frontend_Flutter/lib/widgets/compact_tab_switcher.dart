import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';

class CompactTabBar extends StatelessWidget {
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

class CompactTabContent extends StatefulWidget {
  final int currentIndex;
  final List<CompactTabItem> tabs;
  final bool enableSwipe;
  final ValueChanged<int>? onTabChanged;

  const CompactTabContent({
    super.key,
    required this.currentIndex,
    required this.tabs,
    this.enableSwipe = false,
    this.onTabChanged,
  });

  @override
  State<CompactTabContent> createState() => CompactTabContentState();
}

class CompactTabContentState extends State<CompactTabContent>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.enableSwipe) {
      _tabController = TabController(
        length: widget.tabs.length,
        vsync: this,
        initialIndex: widget.currentIndex,
      );
      _tabController!.addListener(_onTabControllerChanged);
    }
  }

  @override
  void didUpdateWidget(CompactTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tabController != null &&
        oldWidget.currentIndex != widget.currentIndex) {
      if (_tabController!.index != widget.currentIndex) {
        _tabController!.animateTo(widget.currentIndex);
      }
    }
  }

  void _onTabControllerChanged() {
    if (_tabController!.indexIsChanging) {
      widget.onTabChanged?.call(_tabController!.index);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabControllerChanged);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enableSwipe && _tabController != null) {
      return TabBarView(
        controller: _tabController,
        children: widget.tabs.map((tab) => tab.content).toList(),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(widget.currentIndex),
        child: widget.tabs[widget.currentIndex].content,
      ),
    );
  }
}

class CompactTabItem {
  final String label;
  final IconData? icon;
  final Widget content;

  const CompactTabItem({required this.label, required this.content, this.icon});
}
