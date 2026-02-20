import 'package:flutter/material.dart';
import 'theme_colors.dart';

class ThemeStyles {
  static TextStyle titleLarge(BuildContext context) {
    final colors = ThemeColors.forMode(
      context.findAncestorWidgetOfExactType<ThemeColorsProvider>()?.mode ??
          AppThemeMode.greenClassic,
    );
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: colors.textPrimary,
    );
  }

  static TextStyle titleMedium(BuildContext context) {
    final colors = ThemeColors.forMode(
      context.findAncestorWidgetOfExactType<ThemeColorsProvider>()?.mode ??
          AppThemeMode.greenClassic,
    );
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: colors.textPrimary,
    );
  }

  static TextStyle titleSmall(BuildContext context) {
    final colors = ThemeColors.forMode(
      context.findAncestorWidgetOfExactType<ThemeColorsProvider>()?.mode ??
          AppThemeMode.greenClassic,
    );
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
    );
  }

  static TextStyle bodyLarge(BuildContext context) {
    final colors = ThemeColors.forMode(
      context.findAncestorWidgetOfExactType<ThemeColorsProvider>()?.mode ??
          AppThemeMode.greenClassic,
    );
    return TextStyle(fontSize: 16, color: colors.textPrimary);
  }

  static TextStyle bodyMedium(BuildContext context) {
    final colors = ThemeColors.forMode(
      context.findAncestorWidgetOfExactType<ThemeColorsProvider>()?.mode ??
          AppThemeMode.greenClassic,
    );
    return TextStyle(fontSize: 14, color: colors.textPrimary);
  }

  static TextStyle bodySmall(BuildContext context) {
    final colors = ThemeColors.forMode(
      context.findAncestorWidgetOfExactType<ThemeColorsProvider>()?.mode ??
          AppThemeMode.greenClassic,
    );
    return TextStyle(fontSize: 12, color: colors.textSecondary);
  }

  static TextStyle labelLarge(BuildContext context) {
    final colors = ThemeColors.forMode(
      context.findAncestorWidgetOfExactType<ThemeColorsProvider>()?.mode ??
          AppThemeMode.greenClassic,
    );
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: colors.textPrimary,
    );
  }

  static TextStyle labelMedium(BuildContext context) {
    final colors = ThemeColors.forMode(
      context.findAncestorWidgetOfExactType<ThemeColorsProvider>()?.mode ??
          AppThemeMode.greenClassic,
    );
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: colors.textSecondary,
    );
  }

  static TextStyle labelSmall(BuildContext context) {
    final colors = ThemeColors.forMode(
      context.findAncestorWidgetOfExactType<ThemeColorsProvider>()?.mode ??
          AppThemeMode.greenClassic,
    );
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: colors.textHint,
    );
  }

  static TextStyle caption(BuildContext context) {
    final colors = ThemeColors.forMode(
      context.findAncestorWidgetOfExactType<ThemeColorsProvider>()?.mode ??
          AppThemeMode.greenClassic,
    );
    return TextStyle(fontSize: 12, color: colors.textHint);
  }
}

class ThemeColorsProvider extends InheritedWidget {
  final AppThemeMode mode;

  const ThemeColorsProvider({
    super.key,
    required this.mode,
    required super.child,
  });

  static ThemeColorsProvider? of(BuildContext context) {
    return context.findAncestorWidgetOfExactType<ThemeColorsProvider>();
  }

  @override
  bool updateShouldNotify(ThemeColorsProvider oldWidget) {
    return mode != oldWidget.mode;
  }
}
