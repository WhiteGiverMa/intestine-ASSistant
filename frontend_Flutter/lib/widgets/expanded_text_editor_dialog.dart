import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';

class ExpandedTextEditorDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String initialText;
  final bool showClearButton;
  final String? defaultText;

  const ExpandedTextEditorDialog({
    super.key,
    required this.title,
    this.hintText = '输入内容...',
    this.initialText = '',
    this.showClearButton = false,
    this.defaultText,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String hintText = '输入内容...',
    String initialText = '',
    bool showClearButton = false,
    String? defaultText,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => ExpandedTextEditorDialog(
        title: title,
        hintText: hintText,
        initialText: initialText,
        showClearButton: showClearButton,
        defaultText: defaultText,
      ),
    );
  }

  @override
  State<ExpandedTextEditorDialog> createState() =>
      _ExpandedTextEditorDialogState();
}

class _ExpandedTextEditorDialogState extends State<ExpandedTextEditorDialog> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: colors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    filled: true,
                    fillColor: colors.surface,
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            _buildFooter(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note, size: 24, color: colors.primary),
          const SizedBox(width: 12),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          if (widget.showClearButton)
            TextButton(
              onPressed: () => _controller.clear(),
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
              ),
              child: const Text('清空'),
            ),
          if (widget.defaultText != null) ...[
            if (widget.showClearButton)
              const SizedBox(width: 8),
            TextButton(
              onPressed: () => _controller.text = widget.defaultText!,
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
              ),
              child: const Text('恢复默认'),
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colors.textSecondary),
            tooltip: '关闭',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: colors.textSecondary,
            ),
            child: const Text('取消'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.textOnPrimary,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
