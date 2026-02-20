import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import 'data_page.dart';
import 'analysis_page.dart';
import 'record_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

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
              _buildHeader(colors),
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
              _buildBottomNav(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ThemeDecorations.header(context, mode: context.themeMode),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '肠道健康助手',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          if (_token == null)
            Row(
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
            ),
        ],
      ),
    );
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
                const AnalysisPage(),
                colors,
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
    Widget page,
    ThemeColors colors, {
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
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

  Widget _buildBottomNav(ThemeColors colors) {
    return Container(
      decoration: ThemeDecorations.bottomNav(context, mode: context.themeMode),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('🏠', '首页', true, colors),
            _buildNavItem('📊', '数据', false, colors, page: const DataPage()),
            _buildNavItem(
              '🤖',
              '分析',
              false,
              colors,
              page: const AnalysisPage(),
            ),
            _buildNavItem(
              '⚙️',
              '设置',
              false,
              colors,
              page: const SettingsPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String emoji,
    String label,
    bool isActive,
    ThemeColors colors, {
    Widget? page,
  }) {
    return GestureDetector(
      onTap: page != null
          ? () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => page))
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? colors.primary : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
