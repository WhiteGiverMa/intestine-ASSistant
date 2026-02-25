import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_decorations.dart';
import '../utils/responsive_utils.dart';
import 'app_header.dart';

/// Base page widget that encapsulates common page structure.
///
/// @module: base_page
/// @type: widget
/// @layer: frontend
/// @depends: [providers.theme_provider, theme.theme_decorations, utils.responsive_utils, widgets.app_header]
/// @exports: [BasePage]
/// @brief: Reusable base page component with background, header, and unfocus-on-tap support.
class BasePage extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final Widget? trailing;
  final Widget? bottom;
  final bool unfocusOnTap;
  final double? maxWidth;
  final bool useScrollView;
  final EdgeInsetsGeometry? padding;
  final Widget? child;
  final Widget Function(BuildContext context)? builder;
  final bool resizeToAvoidBottomInset;
  final VoidCallback? onBack;
  final double titleFontSize;

  const BasePage({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = false,
    this.trailing,
    this.bottom,
    this.unfocusOnTap = true,
    this.maxWidth,
    this.useScrollView = true,
    this.padding,
    this.child,
    this.builder,
    this.resizeToAvoidBottomInset = true,
    this.onBack,
    this.titleFontSize = 20,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       ),
       assert(
         title != null || titleWidget != null || showBackButton == false,
         'title or titleWidget is required when showBackButton is true',
       );

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final hasHeader = title != null || titleWidget != null;

    final contentWidget = child ?? builder!(context);

    Widget content = hasHeader
        ? Column(
            children: [
              AppHeader(
                title: title,
                titleWidget: titleWidget,
                showBackButton: showBackButton,
                trailing: trailing,
                bottom: bottom,
                onBack: onBack,
                titleFontSize: titleFontSize,
              ),
              Expanded(child: _buildContent(context, contentWidget)),
            ],
          )
        : _buildContent(context, contentWidget);

    if (unfocusOnTap) {
      content = GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: content,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Container(
        decoration: ThemeDecorations.backgroundGradient(
          context,
          mode: themeProvider.mode,
        ),
        child: SafeArea(child: content),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Widget contentWidget) {
    if (!useScrollView) {
      if (maxWidth != null) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: contentWidget,
          ),
        );
      }
      return contentWidget;
    }

    final scrollChild = maxWidth != null
        ? Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth!),
              child: contentWidget,
            ),
          )
        : contentWidget;

    return SingleChildScrollView(
      padding: padding ?? ResponsiveUtils.responsivePadding(context),
      child: scrollChild,
    );
  }
}
