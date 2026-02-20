// @module: theme_provider
// @type: provider
// @layer: frontend
// @depends: [theme.theme_colors, provider, shared_preferences]
// @exports: [ThemeProvider, ThemeColorsExtension]
// @state:
//   - mode: AppThemeMode (当前主题模式)
//   - colors: ThemeColors (当前主题颜色)
// @persistence: SharedPreferences (key: app_theme_mode)
// @brief: 主题状态管理，支持多主题切换和持久化
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'app_theme_mode';

  AppThemeMode _mode = AppThemeMode.greenClassic;
  bool _initialized = false;

  AppThemeMode get mode => _mode;
  ThemeColors get colors => ThemeColors.forMode(_mode);
  bool get isDark => _mode == AppThemeMode.darkOled;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_storageKey);
      _mode = AppThemeMode.fromStorageKey(key ?? '');
    } catch (e) {
      debugPrint('初始化主题失败: $e');
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, mode.storageKey);
    } catch (e) {
      debugPrint('保存主题设置失败: $e');
    }
    notifyListeners();
  }
}

extension ThemeColorsExtension on BuildContext {
  ThemeColors get themeColors {
    try {
      final provider = watch<ThemeProvider>();
      return provider.colors;
    } catch (e) {
      return ThemeColors.greenClassic;
    }
  }

  AppThemeMode get themeMode {
    try {
      final provider = watch<ThemeProvider>();
      return provider.mode;
    } catch (e) {
      return AppThemeMode.greenClassic;
    }
  }
}
