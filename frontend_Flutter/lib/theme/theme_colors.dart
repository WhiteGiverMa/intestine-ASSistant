import 'package:flutter/material.dart';

enum AppThemeMode {
  greenClassic('绿色经典', 'green_classic'),
  whiteMinimal('白色简约', 'white_minimal'),
  darkOled('暗黑模式', 'dark_oled');

  final String label;
  final String storageKey;

  const AppThemeMode(this.label, this.storageKey);

  static AppThemeMode fromStorageKey(String key) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.storageKey == key,
      orElse: () => AppThemeMode.greenClassic,
    );
  }
}

class ThemeColors {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color background;
  final Color backgroundGradientStart;
  final Color backgroundGradientEnd;
  final Color surface;
  final Color surfaceVariant;
  final Color card;
  final Color cardBackground;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textOnPrimary;
  final Color error;
  final Color errorBackground;
  final Color success;
  final Color warning;
  final Color info;
  final Color secondary;
  final Color accent;
  final Color shadow;

  const ThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.background,
    required this.backgroundGradientStart,
    required this.backgroundGradientEnd,
    required this.surface,
    required this.surfaceVariant,
    required this.card,
    required this.cardBackground,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textOnPrimary,
    required this.error,
    required this.errorBackground,
    required this.success,
    required this.warning,
    required this.info,
    required this.secondary,
    required this.accent,
    required this.shadow,
  });

  static ThemeColors get greenClassic => const ThemeColors(
    primary: Color(0xFF2E7D32),
    primaryLight: Color(0xFF4CAF50),
    primaryDark: Color(0xFF1B5E20),
    background: Color(0xFFFFFFFF),
    backgroundGradientStart: Color(0xFFE8F5E9),
    backgroundGradientEnd: Color(0xFFB2DFDB),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF5F5F5),
    card: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    divider: Color(0xFFE0E0E0),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF757575),
    textHint: Color(0xFF9E9E9E),
    textOnPrimary: Color(0xFFFFFFFF),
    error: Color(0xFFD32F2F),
    errorBackground: Color(0xFFFFEBEE),
    success: Color(0xFF388E3C),
    warning: Color(0xFFF57C00),
    info: Color(0xFF1976D2),
    secondary: Color(0xFF7B1FA2),
    accent: Color(0xFFFFA726),
    shadow: Color(0x1A000000),
  );

  static ThemeColors get whiteMinimal => const ThemeColors(
    primary: Color(0xFF2E7D32),
    primaryLight: Color(0xFF4CAF50),
    primaryDark: Color(0xFF1B5E20),
    background: Color(0xFFFAFAFA),
    backgroundGradientStart: Color(0xFFFAFAFA),
    backgroundGradientEnd: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0F0F0),
    card: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    divider: Color(0xFFE0E0E0),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF757575),
    textHint: Color(0xFF9E9E9E),
    textOnPrimary: Color(0xFFFFFFFF),
    error: Color(0xFFD32F2F),
    errorBackground: Color(0xFFFFEBEE),
    success: Color(0xFF388E3C),
    warning: Color(0xFFF57C00),
    info: Color(0xFF1976D2),
    secondary: Color(0xFF7B1FA2),
    accent: Color(0xFFFFA726),
    shadow: Color(0x0D000000),
  );

  static ThemeColors get darkOled => const ThemeColors(
    primary: Color(0xFF81C784),
    primaryLight: Color(0xFFA5D6A7),
    primaryDark: Color(0xFF66BB6A),
    background: Color(0xFF000000),
    backgroundGradientStart: Color(0xFF000000),
    backgroundGradientEnd: Color(0xFF0A0A0A),
    surface: Color(0xFF121212),
    surfaceVariant: Color(0xFF1E1E1E),
    card: Color(0xFF1E1E1E),
    cardBackground: Color(0xFF1E1E1E),
    divider: Color(0xFF333333),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0),
    textHint: Color(0xFF757575),
    textOnPrimary: Color(0xFF000000),
    error: Color(0xFFCF6679),
    errorBackground: Color(0xFF1A1113),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    info: Color(0xFF64B5F6),
    secondary: Color(0xFFBA68C8),
    accent: Color(0xFFFFCC80),
    shadow: Color(0x00000000),
  );

  static ThemeColors forMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.greenClassic:
        return greenClassic;
      case AppThemeMode.whiteMinimal:
        return whiteMinimal;
      case AppThemeMode.darkOled:
        return darkOled;
    }
  }
}
