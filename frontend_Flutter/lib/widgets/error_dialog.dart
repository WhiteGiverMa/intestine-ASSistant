import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? details;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.details,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        details: details,
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final text = details ?? message;
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullText = details ?? message;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  details!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _copyToClipboard(context),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('复制错误信息'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
