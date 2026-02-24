import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final ErrorType? errorType;
  final VoidCallback? onRetry;
  final bool showCopyButton;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.errorType,
    this.onRetry,
    this.showCopyButton = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
    ErrorType? errorType,
    VoidCallback? onRetry,
    bool showCopyButton = true,
  }) {
    return showDialog(
      context: context,
      builder:
          (context) => ErrorDialog(
            title: title,
            message: message,
            details: details,
            errorType: errorType,
            onRetry: onRetry,
            showCopyButton: showCopyButton,
          ),
    );
  }

  static Future<void> showFromAppError(
    BuildContext context, {
    required AppError error,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder:
          (context) => ErrorDialog(
            title: _getTitleForErrorType(error.type),
            message: error.message,
            details: error.details ?? error.originalError,
            errorType: error.type,
            onRetry:
                error.type == ErrorType.network ||
                        error.type == ErrorType.server
                    ? onRetry
                    : null,
          ),
    );
  }

  static String _getTitleForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.auth:
        return '认证失败';
      case ErrorType.network:
        return '网络错误';
      case ErrorType.server:
        return '服务器错误';
      case ErrorType.unknown:
        return '操作失败';
    }
  }

  IconData _getIconForErrorType() {
    switch (errorType) {
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.unknown:
        return Icons.error_outline;
      case null:
        return Icons.error_outline;
    }
  }

  Color _getColorForErrorType() {
    switch (errorType) {
      case ErrorType.auth:
        return Colors.orange;
      case ErrorType.network:
        return Colors.blue;
      case ErrorType.server:
        return Colors.purple;
      case ErrorType.unknown:
        return Colors.red;
      case null:
        return Colors.red;
    }
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
    final colors = context.watch<ThemeProvider>().colors;
    final color = _getColorForErrorType();

    return AlertDialog(
      backgroundColor: colors.card,
      title: Row(
        children: [
          Icon(_getIconForErrorType(), color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: TextStyle(color: colors.textPrimary)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 15, color: colors.textPrimary),
            ),
            if (details != null) ...[
              const SizedBox(height: 12),
              Text(
                '详细信息：',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    details!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (showCopyButton)
          TextButton.icon(
            onPressed: () => _copyToClipboard(context),
            icon: Icon(Icons.copy, size: 18, color: colors.textSecondary),
            label: Text(
              '复制错误信息',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        if (onRetry != null)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onRetry!();
            },
            icon: Icon(Icons.refresh, size: 18, color: colors.primary),
            label: Text('重试', style: TextStyle(color: colors.primary)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('关闭', style: TextStyle(color: colors.textSecondary)),
        ),
      ],
    );
  }
}

class ErrorWidgetInline extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showCopyButton;

  const ErrorWidgetInline({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showCopyButton = false,
  });

  IconData _getIconForErrorType() {
    switch (error.type) {
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  Color _getColorForErrorType() {
    switch (error.type) {
      case ErrorType.auth:
        return Colors.orange;
      case ErrorType.network:
        return Colors.blue;
      case ErrorType.server:
        return Colors.purple;
      case ErrorType.unknown:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final color = _getColorForErrorType();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIconForErrorType(), size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            error.message,
            style: TextStyle(color: color, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (showCopyButton &&
              (error.details != null || error.originalError.isNotEmpty)) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: error.details ?? error.originalError),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('错误信息已复制'),
                    backgroundColor: colors.primary,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 14, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '点击复制错误详情',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (onRetry != null && error.type != ErrorType.auth) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
