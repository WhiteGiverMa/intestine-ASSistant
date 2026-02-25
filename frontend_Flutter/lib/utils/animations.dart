import 'package:flutter/material.dart';

class AppAnimations {
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationPageTransition = Duration(milliseconds: 300);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curveBounce = Curves.easeOutBack;
  static const Curve curveSmooth = Curves.easeInOutCubic;

  static const double slideOffset = 0.05;
  static const double scaleFrom = 0.95;
  static const int staggerIntervalMs = 50;
}

class FadeSlideTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final Offset offset;

  const FadeSlideTransition({
    super.key,
    required this.animation,
    required this.child,
    this.offset = const Offset(0, 0.03),
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: offset, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: AppAnimations.curveEnter),
        ),
        child: child,
      ),
    );
  }
}

class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset slideOffset;
  final bool fadeIn;
  final bool slideIn;
  final bool scaleIn;
  final bool animate;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.duration = AppAnimations.durationNormal,
    this.delay = Duration.zero,
    this.curve = AppAnimations.curveEnter,
    this.slideOffset = const Offset(0, 0.02),
    this.fadeIn = true,
    this.slideIn = true,
    this.scaleIn = false,
    this.animate = false,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    if (!widget.animate) {
      _controller.value = 1.0;
      return;
    }

    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;

    if (widget.scaleIn) {
      result = ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(_animation),
        child: result,
      );
    }

    if (widget.slideIn) {
      result = SlideTransition(
        position: Tween<Offset>(
          begin: widget.slideOffset,
          end: Offset.zero,
        ).animate(_animation),
        child: result,
      );
    }

    if (widget.fadeIn) {
      result = FadeTransition(opacity: _animation, child: result);
    }

    return result;
  }
}

class AnimatedStaggeredList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Duration itemDuration;
  final Duration staggerDelay;
  final double mainAxisSpacing;

  const AnimatedStaggeredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemDuration = AppAnimations.durationNormal,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.mainAxisSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return AnimatedEntrance(
          duration: itemDuration,
          delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
          child: itemBuilder(context, index),
        );
      }),
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final VoidCallback? onTap;
  final bool enableScaleOnTap;
  final bool animate;

  const AnimatedCard({
    super.key,
    required this.child,
    this.duration = AppAnimations.durationNormal,
    this.delay = Duration.zero,
    this.onTap,
    this.enableScaleOnTap = true,
    this.animate = false,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveEnter,
    );

    if (!widget.animate) {
      _controller.value = 1.0;
      return;
    }

    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enableScaleOnTap && widget.onTap != null) {
      setState(() => _scale = 0.97);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enableScaleOnTap && widget.onTap != null) {
      setState(() => _scale = 1.0);
      widget.onTap?.call();
    }
  }

  void _onTapCancel() {
    if (widget.enableScaleOnTap) {
      setState(() => _scale = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(_animation),
        child: AnimatedScale(
          scale: _scale,
          duration: AppAnimations.durationFast,
          curve: Curves.easeOut,
          child: GestureDetector(
            onTapDown: widget.onTap != null ? _onTapDown : null,
            onTapUp: widget.onTap != null ? _onTapUp : null,
            onTapCancel: widget.onTap != null ? _onTapCancel : null,
            onTap: widget.onTap == null ? null : () {},
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = AppAnimations.durationFast,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = widget.scaleDown);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool slideFromRight;

  FadePageRoute({
    required this.page,
    this.slideFromRight = true,
    super.settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
             CurvedAnimation(
               parent: animation,
               curve: AppAnimations.curveEnter,
             ),
           );

           final slideAnimation = Tween<Offset>(
             begin: slideFromRight ? const Offset(0.1, 0) : Offset.zero,
             end: Offset.zero,
           ).animate(
             CurvedAnimation(
               parent: animation,
               curve: AppAnimations.curveEnter,
             ),
           );

           return FadeTransition(
             opacity: fadeAnimation,
             child: SlideTransition(position: slideAnimation, child: child),
           );
         },
         transitionDuration: AppAnimations.durationPageTransition,
         reverseTransitionDuration: AppAnimations.durationNormal,
       );
}

Future<T?> navigateWithFade<T>(
  BuildContext context,
  Widget page, {
  bool slideFromRight = true,
}) {
  return Navigator.push<T>(
    context,
    FadePageRoute<T>(page: page, slideFromRight: slideFromRight),
  );
}

class AnimatedBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = false,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: AppAnimations.durationNormal,
      )..forward(),
      builder: builder,
    );
  }
}

class AnimatedMessageBubble extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const AnimatedMessageBubble({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
