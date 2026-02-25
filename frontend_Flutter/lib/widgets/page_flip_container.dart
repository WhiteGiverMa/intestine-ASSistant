import 'package:flutter/material.dart';
import '../utils/animations.dart';

class PageFlipContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;
  final Duration duration;

  const PageFlipContainer({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<PageFlipContainer> createState() => PageFlipContainerState();
}

class PageFlipContainerState extends State<PageFlipContainer>
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
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.value = 1.0;
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveEnter,
    );
  }

  @override
  void didUpdateWidget(PageFlipContainer oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final goingForward = _displayedIndex > _previousIndex;

    return Stack(
      children: [
        if (_isAnimating)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    goingForward
                        ? -MediaQuery.of(context).size.width * _animation.value
                        : MediaQuery.of(context).size.width * _animation.value,
                    0,
                  ),
                  child: widget.children[_previousIndex],
                );
              },
            ),
          ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              if (!_isAnimating) {
                return widget.children[_displayedIndex];
              }
              return Transform.translate(
                offset: Offset(
                  goingForward
                      ? MediaQuery.of(context).size.width *
                          (1 - _animation.value)
                      : -MediaQuery.of(context).size.width *
                          (1 - _animation.value),
                  0,
                ),
                child: widget.children[_displayedIndex],
              );
            },
          ),
        ),
      ],
    );
  }
}

class FadePageContainer extends StatelessWidget {
  final int currentIndex;
  final List<Widget> children;

  const FadePageContainer({
    super.key,
    required this.currentIndex,
    required this.children,
    Duration duration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    return IndexedStack(index: currentIndex, children: children);
  }
}
