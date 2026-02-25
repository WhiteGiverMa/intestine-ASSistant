import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  static Future<void> launchWebUrl(
    BuildContext context,
    String url, {
    String? errorMessage,
  }) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && context.mounted) {
          _showError(context, errorMessage ?? '无法打开链接');
        }
      } else if (context.mounted) {
        _showError(context, errorMessage ?? '无法打开链接');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, errorMessage ?? '打开链接时出错');
      }
    }
  }

  static Future<void> launchBilibiliUrl(
    BuildContext context,
    String webUrl,
  ) async {
    final spaceId = _extractBilibiliSpaceId(webUrl);
    if (spaceId != null) {
      final appUrl = 'bilibili://space/$spaceId';
      final appUri = Uri.parse(appUrl);

      try {
        if (await canLaunchUrl(appUri)) {
          final launched = await launchUrl(
            appUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return;
        }
      } catch (_) {
      }
    }

    if (context.mounted) {
      await launchWebUrl(context, webUrl, errorMessage: '无法打开哔哩哔哩');
    }
  }

  static String? _extractBilibiliSpaceId(String url) {
    final regex = RegExp(r'space\.bilibili\.com/(\d+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
