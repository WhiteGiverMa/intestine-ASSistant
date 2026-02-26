import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/url_launcher_service.dart';
import '../services/update_check_service.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/base_page.dart';

const String appVersion = '1.3.3-alpha';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final UpdateCheckService _updateService = UpdateCheckService();
  UpdateCheckResult? _updateResult;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final result = await _updateService.checkForUpdate();
    if (mounted) {
      setState(() {
        _updateResult = result;
        _isChecking = false;
      });
    }
  }

  Future<void> _refreshUpdateCheck() async {
    setState(() {
      _isChecking = true;
    });
    final result = await _updateService.checkForUpdate(forceRefresh: true);
    if (mounted) {
      setState(() {
        _updateResult = result;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;
    return BasePage(
      title: '关于',
      showBackButton: true,
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
      child: Column(
        children: [
          Row(
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
          if (_isChecking) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '正在检查更新...',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ] else if (_updateResult?.hasUpdate == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '发现新版本',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '最新版本: v${_updateResult!.latestVersion}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final url = _updateResult?.downloadUrl ??
                            'https://github.com/WhiteGiverMa/intestine-ASSistant/releases/latest';
                        UrlLauncherService.launchWebUrl(
                          context,
                          url,
                          errorMessage: '无法打开下载页面',
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('前往下载'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.warning,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_updateResult?.errorMessage != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: colors.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _updateResult!.errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.error,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _refreshUpdateCheck,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('重试'),
                ),
              ],
            ),
          ] else if (_updateResult?.isPreRelease == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.science,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '当前为测试版本 (v$appVersion)',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: colors.success,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '已是最新版本',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _refreshUpdateCheck,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('检查更新'),
                ),
              ],
            ),
          ],
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
