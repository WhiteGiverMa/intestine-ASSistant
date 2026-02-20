import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';

class ThemeSelectorPage extends StatelessWidget {
  const ThemeSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;

    return Scaffold(
      body: Container(
        decoration: ThemeDecorations.backgroundGradient(
          context,
          mode: themeProvider.mode,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, colors),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: AppThemeMode.values.map((mode) {
                    return _buildThemeCard(context, mode, themeProvider);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ThemeDecorations.header(context, mode: context.themeMode),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              '←',
              style: TextStyle(fontSize: 20, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '选择主题',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    AppThemeMode mode,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.mode == mode;
    final themeColors = ThemeColors.forMode(mode);

    return GestureDetector(
      onTap: () => themeProvider.setMode(mode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeColors.card,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: themeProvider.colors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: themeColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildThemePreview(mode),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mode.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeColors.textPrimary,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: themeProvider.colors.primary,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getThemeDescription(mode),
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildColorPalette(themeColors),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(AppThemeMode mode) {
    final colors = ThemeColors.forMode(mode);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.backgroundGradientStart,
            colors.backgroundGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(ThemeColors colors) {
    return Row(
      children: [
        _buildColorDot(colors.primary, '主色'),
        const SizedBox(width: 8),
        _buildColorDot(colors.card, '卡片'),
        const SizedBox(width: 8),
        _buildColorDot(colors.textPrimary, '文字'),
        const SizedBox(width: 8),
        _buildColorDot(colors.background, '背景'),
      ],
    );
  }

  Widget _buildColorDot(Color color, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  String _getThemeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.greenClassic:
        return '经典绿白配色，清新自然';
      case AppThemeMode.whiteMinimal:
        return '纯白简约风格，现代设计';
      case AppThemeMode.darkOled:
        return '纯黑背景，OLED 省电优化';
    }
  }
}
