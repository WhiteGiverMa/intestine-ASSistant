import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';

const String appVersion = '0.2.0';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildAppInfo(colors),
                      const SizedBox(height: 16),
                      _buildVersionCard(context, colors),
                      const SizedBox(height: 16),
                      _buildDeveloperCard(context, colors),
                      const SizedBox(height: 16),
                      _buildPoweredByCard(context, colors),
                    ],
                  ),
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
      decoration: ThemeDecorations.header(context),
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
            '关于',
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

  Widget _buildAppInfo(ThemeColors colors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text('🚽', style: TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Intestine ASSistant',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '智能排便健康助手',
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildVersionCard(BuildContext context, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('📱', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '版本号',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '当前版本',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            'v$appVersion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('👨‍💻', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '开发者',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '项目作者',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '马戈',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoweredByCard(BuildContext context, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Powered by',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPoweredByItem('GLM-5', '智谱AI大语言模型', colors),
          const SizedBox(height: 12),
          _buildPoweredByItem('DeepSeek v3.2', '深度求索AI模型', colors),
        ],
      ),
    );
  }

  Widget _buildPoweredByItem(
    String name,
    String description,
    ThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
