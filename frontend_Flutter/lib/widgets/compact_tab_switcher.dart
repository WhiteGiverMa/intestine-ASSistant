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
  State<CompactTabContent> createState() => _CompactTabContentState();
}

class _CompactTabContentState extends State<CompactTabContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  int _displayedIndex = 0;
  int _previousIndex = 0;
  bool _isAnimating = false;
  int _pendingIndex = -1;

  @override
  void initState() {
    super.initState();
    _displayedIndex = widget.currentIndex;
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _controller.value = 1.0;
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(CompactTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (_isAnimating) {
        _pendingIndex = widget.currentIndex;
        _controller.stop();
        _controller.value = 1.0;
        setState(() {
          _displayedIndex = _pendingIndex;
          _previousIndex = _pendingIndex;
          _isAnimating = false;
          _pendingIndex = -1;
        });
      } else {
        _animateToPage(widget.currentIndex);
      }
    }
  }

  void _animateToPage(int newIndex) {
    if (_displayedIndex == newIndex) return;

    setState(() {
      _previousIndex = _displayedIndex;
      _displayedIndex = newIndex;
      _isAnimating = true;
    });

    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
        if (_pendingIndex >= 0 && _pendingIndex != _displayedIndex) {
          final pending = _pendingIndex;
          _pendingIndex = -1;
          _animateToPage(pending);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300 && widget.currentIndex < widget.tabs.length - 1) {
      widget.onTabChanged?.call(widget.currentIndex + 1);
    } else if (velocity > 300 && widget.currentIndex > 0) {
      widget.onTabChanged?.call(widget.currentIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goingForward = _displayedIndex > _previousIndex;
    final screenWidth = MediaQuery.of(context).size.width;

    final content = Stack(
      children: [
        if (_isAnimating)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    goingForward
                        ? -screenWidth * _animation.value
                        : screenWidth * _animation.value,
                    0,
                  ),
                  child: widget.tabs[_previousIndex].content,
                );
              },
            ),
          ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              if (!_isAnimating) {
                return widget.tabs[_displayedIndex].content;
              }
              return Transform.translate(
                offset: Offset(
                  goingForward
                      ? screenWidth * (1 - _animation.value)
                      : -screenWidth * (1 - _animation.value),
                  0,
                ),
                child: widget.tabs[_displayedIndex].content,
              );
            },
          ),
        ),
      ],
    );

    if (widget.enableSwipe) {
      return GestureDetector(onHorizontalDragEnd: _handleSwipe, child: content);
    }

    return content;
  }
}

class CompactTabItem {
  final String label;
  final IconData? icon;
  final Widget content;

  const CompactTabItem({required this.label, required this.content, this.icon});
}
