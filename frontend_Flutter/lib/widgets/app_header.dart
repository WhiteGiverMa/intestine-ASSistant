import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_decorations.dart';
import '../utils/animations.dart';

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
  }) : assert(
         title != null || titleWidget != null,
         'Either title or titleWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final leftPadding = mediaQuery.padding.left;
    final rightPadding = mediaQuery.padding.right;

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 12,
        left: (leftPadding > 0 ? leftPadding : 16),
        right: (rightPadding > 0 ? rightPadding : 16),
        bottom: 12,
      ),
      decoration: ThemeDecorations.header(context, mode: themeProvider.mode),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (showBackButton)
                ScaleOnTap(
                  onTap:
                      onBack ??
                      () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.pop(context);
                        }
                      },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: colors.textSecondary,
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),
              if (showBackButton) const SizedBox(width: 8),
              Expanded(
                child:
                    titleWidget ??
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: colors.headerText,
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
