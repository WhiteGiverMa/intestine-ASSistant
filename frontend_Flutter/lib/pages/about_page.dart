import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/url_launcher_service.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/app_header.dart';
import '../utils/responsive_utils.dart';

const String appVersion = '1.2.0';

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
              const AppHeader(title: '关于', showBackButton: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: ResponsiveUtils.responsivePadding(context),
                  child: ResponsiveUtils.constrainedContent(
                    context: context,
                    maxWidth: 600,
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
              ),
            ],
          ),
        ),
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
          '肠胃健康智能追踪助手',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      '马戈 (WhiteGiverMa)',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLinkItem(
            context,
            'GitHub',
            'https://github.com/WhiteGiverMa/intestine-ASSistant',
            '🔗',
            colors,
          ),
          const SizedBox(height: 8),
          _buildLinkItem(
            context,
            '哔哩哔哩',
            'https://space.bilibili.com/357545524',
            '📺',
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(
    BuildContext context,
    String title,
    String url,
    String emoji,
    ThemeColors colors,
  ) {
    return GestureDetector(
      onTap: () {
        if (url.contains('bilibili.com')) {
          UrlLauncherService.launchBilibiliUrl(context, url);
        } else {
          UrlLauncherService.launchWebUrl(context, url);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: colors.textSecondary),
          ],
        ),
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
          _buildPoweredByItem('Kimi-K2.5', '月之暗面大语言模型', colors),
          const SizedBox(height: 12),
          _buildPoweredByItem('DeepSeek V3.2', '深度求索AI模型', colors),
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
