// 数据管理中心入口页面。
//
// @module: data_page
// @type: page
// @layer: frontend
// @depends: [record_page, data_overview_page]
// @exports: [DataPage, DataPageContent]
// @brief: 数据管理入口，提供记录排便和数据概览的快捷入口。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../utils/animations.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_header.dart';
import 'record_page.dart';
import 'data_overview_page.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class DataPageContent extends StatelessWidget {
  const DataPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const DataPage();
  }
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
              const AppHeader(title: '数据管理'),
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
                            _buildWelcome(colors),
                            const SizedBox(height: 24),
                            _buildMenuGrid(colors, constraints),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome(ThemeColors colors) {
    return AnimatedEntrance(
      duration: AppAnimations.durationSlow,
      child: Column(
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
          Text(
            '记录、查看和管理您的肠胃健康数据',
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(ThemeColors colors, BoxConstraints constraints) {
    final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(
      context,
      minItems: 1,
      maxItems: 3,
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        AnimatedCard(
          delay: const Duration(milliseconds: 100),
          onTap: () => navigateWithFade(context, const RecordPage()),
          child: _buildMenuCardContent('📝', '记录排便', '手动输入或计时记录', colors),
        ),
        AnimatedCard(
          delay: const Duration(milliseconds: 200),
          onTap: () => navigateWithFade(context, const DataOverviewPage()),
          child: _buildMenuCardContent('📈', '数据概览', '统计趋势与记录管理', colors),
        ),
      ],
    );
  }

  Widget _buildMenuCardContent(
    String emoji,
    String title,
    String subtitle,
    ThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context, mode: context.themeMode),
      child: Column(
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
    );
  }
}
