// 数据管理中心入口页面。
//
// @module: data_page
// @type: page
// @layer: frontend
// @depends: [record_page, data_overview_page, analysis_page, settings_page]
// @exports: [DataPage]
// @brief: 数据管理入口，提供记录排便和数据概览的快捷入口。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/app_header.dart';
import '../widgets/app_bottom_nav.dart';
import 'record_page.dart';
import 'data_overview_page.dart';
import 'analysis_page.dart';
import 'settings_page.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
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
              AppHeader(title: '数据管理'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildWelcome(colors),
                      const SizedBox(height: 24),
                      _buildMenuGrid(colors),
                    ],
                  ),
                ),
              ),
              AppBottomNav(
                activeTab: NavTab.data,
                onNavigate: (tab) => _handleNavTab(context, tab),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavTab(BuildContext context, NavTab tab) {
    switch (tab) {
      case NavTab.home:
        Navigator.pop(context);
        break;
      case NavTab.data:
        break;
      case NavTab.analysis:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalysisPage()),
        );
        break;
      case NavTab.settings:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
        break;
    }
  }

  Widget _buildWelcome(ThemeColors colors) {
    return Column(
      children: [
        const Text('📊', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(
          '数据管理中心',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text('记录、查看和管理您的肠道健康数据', style: TextStyle(color: colors.textSecondary)),
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
                '手动输入或计时记录',
                const RecordPage(),
                colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                '📈',
                '数据概览',
                '统计趋势与记录管理',
                const DataOverviewPage(),
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
}
