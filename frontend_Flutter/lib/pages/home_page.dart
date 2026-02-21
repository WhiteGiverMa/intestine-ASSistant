import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/app_header.dart';
import '../widgets/app_bottom_nav.dart';
import 'record_page.dart';
import 'login_page.dart';
import 'register_page.dart';

class HomePage extends StatefulWidget {
  final void Function(NavTab tab)? onNavigate;

  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final colors = themeProvider.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: '肠道健康助手',
              trailing: _buildTrailingWidget(authProvider, colors),
            ),
            if (authProvider.isOfflineMode)
              _buildOfflineBanner(colors, authProvider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildWelcome(colors),
                    const SizedBox(height: 24),
                    _buildMenuGrid(colors),
                    const SizedBox(height: 24),
                    _buildBristolChart(colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildTrailingWidget(AuthProvider authProvider, ThemeColors colors) {
    if (authProvider.isLoggedIn) {
      return null;
    }
    if (authProvider.isOfflineMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.warning, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.offline_bolt, size: 16, color: colors.warning),
            const SizedBox(width: 4),
            Text(
              '离线模式',
              style: TextStyle(
                color: colors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          ),
          child: Text('登录', style: TextStyle(color: colors.primary)),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterPage()),
          ),
          child: Text('注册', style: TextStyle(color: colors.primary)),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner(ThemeColors colors, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '离线模式已启用',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  authProvider.unsyncedCount > 0
                      ? '${authProvider.unsyncedCount} 条记录待同步'
                      : '数据仅保存在本地',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (authProvider.unsyncedCount > 0)
            TextButton(
              onPressed: () => _showSyncDialog(context, authProvider),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
              ),
              child: Text(
                '同步',
                style: TextStyle(color: colors.primary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _showSyncDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('同步数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('将 ${authProvider.unsyncedCount} 条本地记录同步到服务器？'),
            const SizedBox(height: 8),
            if (!authProvider.isLoggedIn)
              Text(
                '请先登录后再同步数据',
                style: TextStyle(color: colors(context).warning),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          if (authProvider.isLoggedIn)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await authProvider.syncLocalData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '同步完成: ${result['success']} 成功, ${result['failed']} 失败',
                      ),
                    ),
                  );
                }
              },
              child: const Text('开始同步'),
            ),
        ],
      ),
    );
  }

  ThemeColors colors(BuildContext context) {
    return context.watch<ThemeProvider>().colors;
  }

  Widget _buildWelcome(ThemeColors colors) {
    return Column(
      children: [
        const Text('🚽', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(
          '记录您的肠道健康',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '简单记录，智能分析，守护您的肠道健康',
          style: TextStyle(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMenuGrid(ThemeColors colors) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMenuItem(
                '📝',
                '记录排便',
                '快速记录您的排便数据',
                const RecordPage(),
                colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                '🤖',
                'AI 分析',
                '智能健康分析',
                null,
                colors,
                onTap: widget.onNavigate != null
                    ? () => widget.onNavigate!(NavTab.analysis)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    String emoji,
    String title,
    String subtitle,
    Widget? page,
    ThemeColors colors, {
    bool fullWidth = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? (page != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)) : null),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ThemeDecorations.card(context, mode: context.themeMode),
        child: fullWidth
            ? Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBristolChart(ThemeColors colors) {
    final types = [
      {'type': 1, 'emoji': '🪨', 'desc': '硬块', 'status': '便秘'},
      {'type': 2, 'emoji': '🥜', 'desc': '结块', 'status': '轻便秘'},
      {'type': 3, 'emoji': '🌭', 'desc': '有裂纹', 'status': '正常'},
      {'type': 4, 'emoji': '🍌', 'desc': '光滑', 'status': '理想'},
      {'type': 5, 'emoji': '🫘', 'desc': '断块', 'status': '缺纤维'},
      {'type': 6, 'emoji': '🥣', 'desc': '糊状', 'status': '轻腹泻'},
      {'type': 7, 'emoji': '💧', 'desc': '液体', 'status': '腹泻'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: types.map((t) {
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

              return Column(
                children: [
                  Text(
                    t['emoji'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '类型${t['type']}',
                    style: TextStyle(fontSize: 10, color: colors.textSecondary),
                  ),
                  Text(
                    t['desc'] as String,
                    style: TextStyle(fontSize: 10, color: colors.textHint),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
