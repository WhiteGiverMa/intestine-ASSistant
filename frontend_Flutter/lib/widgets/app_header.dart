import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_decorations.dart';

/// Application header widget with title, back button, and trailing widget support.
///
/// @module: app_header
/// @type: widget
/// @layer: frontend
/// @depends: [providers.theme_provider, theme.theme_decorations]
/// @exports: [AppHeader]
/// @used_by: [
///   pages.home_page,
///   pages.data_page,
///   pages.data_overview_page,
///   pages.analysis_page,
///   pages.record_page,
///   pages.settings_page,
///   pages.user_account_page,
///   pages.theme_selector_page,
///   pages.ai_chat_options_page,
///   pages.dev_tools_page,
///   pages.misc_settings_page,
///   pages.about_page
/// ]
/// @brief: Reusable header component for consistent page headers across the app.
class AppHeader extends StatelessWidget {
  final String? title;
  final bool showBackButton;
  final Widget? trailing;
  final Widget? bottom;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final double titleFontSize;

  const AppHeader({
    super.key,
    this.title,
    this.showBackButton = false,
    this.trailing,
    this.bottom,
    this.titleWidget,
    this.onBack,
    this.titleFontSize = 20,
  }) : assert(title != null || titleWidget != null,
            'Either title or titleWidget must be provided');

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ThemeDecorations.header(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap: onBack ?? () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                  ),
                )
              else
                const SizedBox(width: 28),
              if (showBackButton) const SizedBox(width: 8),
              Expanded(
                child: titleWidget ??
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
              ),
              if (trailing != null) trailing! else const SizedBox(width: 28),
            ],
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}
