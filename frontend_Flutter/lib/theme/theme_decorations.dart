import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'theme_colors.dart';

class ThemeDecorations {
  static AppThemeMode _getMode(BuildContext context, AppThemeMode? mode) {
    return mode ?? context.watch<ThemeProvider>().mode;
  }

  static BoxDecoration backgroundGradient(
    BuildContext context, {
    AppThemeMode? mode,
  }) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.backgroundGradientStart, colors.backgroundGradientEnd],
      ),
    );
  }

  static BoxDecoration card(BuildContext context, {AppThemeMode? mode}) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: colors.shadow,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration cardWithBorder(
    BuildContext context, {
    AppThemeMode? mode,
  }) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.divider),
      boxShadow: [
        BoxShadow(
          color: colors.shadow,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration header(BuildContext context, {AppThemeMode? mode}) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: colors.headerBackground,
      boxShadow: [
        BoxShadow(
          color: colors.shadow,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration bottomNav(BuildContext context, {AppThemeMode? mode}) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: colors.card,
      border: Border(top: BorderSide(color: colors.divider)),
    );
  }

  static BoxDecoration primaryButton(
    BuildContext context, {
    AppThemeMode? mode,
  }) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: colors.primary,
      borderRadius: BorderRadius.circular(12),
    );
  }

  static BoxDecoration primaryChip(BuildContext context, {AppThemeMode? mode}) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: colors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
    );
  }

  static BoxDecoration inputField(BuildContext context, {AppThemeMode? mode}) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: colors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.divider),
    );
  }

  static BoxDecoration errorCard(BuildContext context, {AppThemeMode? mode}) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: colors.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.error.withValues(alpha: 0.3)),
    );
  }

  static BoxDecoration warningCard(BuildContext context, {AppThemeMode? mode}) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: colors.warning.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
    );
  }

  static BoxDecoration successCard(BuildContext context, {AppThemeMode? mode}) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: colors.success.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.success.withValues(alpha: 0.3)),
    );
  }

  static BoxDecoration iconContainer(
    BuildContext context, {
    AppThemeMode? mode,
    Color? backgroundColor,
  }) {
    final colors = ThemeColors.forMode(_getMode(context, mode));
    return BoxDecoration(
      color: backgroundColor ?? colors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    );
  }
}
