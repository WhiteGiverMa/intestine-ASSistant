import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/app_header.dart';
import '../widgets/app_bottom_nav.dart';
import '../utils/animations.dart';
import '../utils/responsive_utils.dart';
import 'record_page.dart';

class HomePage extends StatefulWidget {
  final void Function(NavTab tab)? onNavigate;

  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final colors = themeProvider.colors;

    return SafeArea(
      child: Column(
        children: [
          AppHeader(
            title: '肠胃健康助手',
            trailing: _buildTrailingWidget(authProvider, colors),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: ResponsiveUtils.responsivePadding(context),
                  child: ResponsiveUtils.constrainedContent(
                    context: context,
                    maxWidth: 800,
                    child: Column(
                      children: [
                        _buildWelcome(colors, authProvider),
                        const SizedBox(height: 24),
                        _buildMenuGrid(colors, constraints),
                        const SizedBox(height: 24),
                        _buildBristolChart(colors, constraints),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildTrailingWidget(AuthProvider authProvider, ThemeColors colors) {
    if (authProvider.localUser != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.success.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.success),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: colors.success),
            const SizedBox(width: 4),
            Text(
              '本地模式',
              style: TextStyle(
                color: colors.success,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  Widget _buildWelcome(ThemeColors colors, AuthProvider authProvider) {
    return AnimatedEntrance(
      duration: AppAnimations.durationSlow,
      child: Column(
        children: [
          const Text('🚽', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            '你好，${authProvider.displayName}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '记录您的肠胃健康，智能分析守护您',
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(ThemeColors colors, BoxConstraints constraints) {
    final isWide = constraints.maxWidth >= Breakpoints.tablet;
    final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(
      context,
      minItems: 2,
      maxItems: 3,
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isWide ? 1.8 : 1.2,
      children: [
        AnimatedCard(
          delay: const Duration(milliseconds: 100),
          onTap: () => navigateWithFade(context, const RecordPage()),
          child: _buildMenuItemContent('📝', '记录排便', '快速记录您的排便数据', colors),
        ),
        AnimatedCard(
          delay: const Duration(milliseconds: 150),
          onTap:
              widget.onNavigate != null
                  ? () => widget.onNavigate!(NavTab.analysis)
                  : null,
          child: _buildMenuItemContent('🤖', 'AI 分析', '智能健康分析', colors),
        ),
      ],
    );
  }

  Widget _buildMenuItemContent(
    String emoji,
    String title,
    String subtitle,
    ThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ThemeDecorations.card(context, mode: context.themeMode),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBristolChart(ThemeColors colors, BoxConstraints constraints) {
    final types = [
      {'type': 1, 'emoji': '🪨', 'label': '硬块', 'status': '便秘'},
      {'type': 2, 'emoji': '🥜', 'label': '香肠结块', 'status': '轻便秘'},
      {'type': 3, 'emoji': '🌭', 'label': '香肠裂纹', 'status': '正常'},
      {'type': 4, 'emoji': '🍌', 'label': '香肠光滑', 'status': '理想'},
      {'type': 5, 'emoji': '🫘', 'label': '柔软断块', 'status': '缺纤维'},
      {'type': 6, 'emoji': '🥣', 'label': '糊状', 'status': '轻腹泻'},
      {'type': 7, 'emoji': '💧', 'label': '液体', 'status': '腹泻'},
    ];

    final isNarrow = constraints.maxWidth < 400;
    final isWide = constraints.maxWidth >= Breakpoints.tablet;

    return AnimatedEntrance(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ThemeDecorations.card(context, mode: context.themeMode),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '布里斯托大便分类法',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '类型3-5为健康范围，1-2提示便秘，6-7提示腹泻',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            isNarrow
                ? _buildBristolList(types, colors)
                : _buildBristolRow(types, colors, isWide),
          ],
        ),
      ),
    );
  }

  Widget _buildBristolRow(
    List<Map<String, dynamic>> types,
    ThemeColors colors,
    bool isWide,
  ) {
    return Row(
      children:
          types.asMap().entries.map((entry) {
            final index = entry.key;
            final t = entry.value;
            final status = t['status'] as String;
            Color statusColor;
            if (status == '理想') {
              statusColor = colors.success;
            } else if (status == '正常') {
              statusColor = colors.success.withValues(alpha: 0.7);
            } else if (status.contains('便秘') || status.contains('腹泻')) {
              statusColor = colors.error;
            } else {
              statusColor = colors.warning;
            }

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(left: index == 0 ? 0 : 3),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 6 : 4,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t['emoji'] as String,
                      style: TextStyle(fontSize: isWide ? 28 : 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t['type']}',
                      style: TextStyle(
                        fontSize: isWide ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: isWide ? 13 : 11,
                        height: 1.2,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: isWide ? 12 : 10,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBristolList(
    List<Map<String, dynamic>> types,
    ThemeColors colors,
  ) {
    return Column(
      children:
          types.map((t) {
            final status = t['status'] as String;
            Color statusColor;
            if (status == '理想') {
              statusColor = colors.success;
            } else if (status == '正常') {
              statusColor = colors.success.withValues(alpha: 0.7);
            } else if (status.contains('便秘') || status.contains('腹泻')) {
              statusColor = colors.error;
            } else {
              statusColor = colors.warning;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    t['emoji'] as String,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${t['type']}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
