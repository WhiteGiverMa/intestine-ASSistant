import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';

class FeedbackItem {
  final String id;
  final String message;
  final ThemeColors colors;
  final IconData icon;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.message,
    required this.colors,
    required this.icon,
  }) : createdAt = DateTime.now();
}

class TopFeedback {
  static final List<FeedbackItem> _items = [];
  static OverlayEntry? _overlayEntry;
  static BuildContext? _context;
  static const int _maxItems = 3;

  static void init(BuildContext context) {
    _context = context;
  }

  static void show(
    BuildContext context, {
    required String message,
    required ThemeColors colors,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    _context = context;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    if (_items.length >= _maxItems) {
      _items.removeAt(0);
    }

    final item = FeedbackItem(
      id: id,
      message: message,
      colors: colors,
      icon: icon ?? Icons.check_circle_outline,
    );

    _items.add(item);
    _updateOverlay();

    Future.delayed(duration, () {
      removeItem(id);
    });
  }

  static void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _updateOverlay();
  }

  static void hideAll() {
    _items.clear();
    _updateOverlay();
  }

  static void _updateOverlay() {
    if (_context == null) return;

    final overlay = Overlay.of(_context!);

    _overlayEntry?.remove();
    _overlayEntry = null;

    if (_items.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _FeedbackStack(
        items: List.from(_items),
        onItemDismissed: removeItem,
      ),
    );

    overlay.insert(_overlayEntry!);
  }
}

class _FeedbackStack extends StatefulWidget {
  final List<FeedbackItem> items;
  final Function(String) onItemDismissed;

  const _FeedbackStack({
    required this.items,
    required this.onItemDismissed,
  });

  @override
  State<_FeedbackStack> createState() => _FeedbackStackState();
}

class _FeedbackStackState extends State<_FeedbackStack> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = widget.items.length - 1; i >= 0; i--)
            _AnimatedFeedbackItem(
              key: ValueKey(widget.items[i].id),
              item: widget.items[i],
              index: widget.items.length - 1 - i,
              onDismiss: () => widget.onItemDismissed(widget.items[i].id),
            ),
        ],
      ),
    );
  }
}

class _AnimatedFeedbackItem extends StatefulWidget {
  final FeedbackItem item;
  final int index;
  final VoidCallback onDismiss;

  const _AnimatedFeedbackItem({
    super.key,
    required this.item,
    required this.index,
    required this.onDismiss,
  });

  @override
  State<_AnimatedFeedbackItem> createState() => _AnimatedFeedbackItemState();
}

class _AnimatedFeedbackItemState extends State<_AnimatedFeedbackItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;

    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.index * 44.0 * _controller.value),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.item.colors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.item.colors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.item.icon,
                          color: widget.item.colors.textOnPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.item.message,
                            style: TextStyle(
                              color: widget.item.colors.textOnPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Icon(
                            Icons.close,
                            color: widget.item.colors.textOnPrimary.withValues(alpha: 0.7),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
