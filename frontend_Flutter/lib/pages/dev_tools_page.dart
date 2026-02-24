import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/app_header.dart';
import '../services/local_db_service.dart';
import 'test_data_generator_page.dart';

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  bool _showRequestDetails = false;

  @override
  void initState() {
    super.initState();
    _loadShowRequestDetails();
  }

  Future<void> _loadShowRequestDetails() async {
    final savedValue = await LocalDbService.getSetting('show_request_details');
    setState(() {
      _showRequestDetails = savedValue == 'true';
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
              const AppHeader(title: '开发者工具', showBackButton: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildWarningCard(colors),
                      const SizedBox(height: 16),
                      _buildTestDataGeneratorEntry(colors),
                      const SizedBox(height: 16),
                      _buildShowRequestDetailsToggle(colors),
                      const SizedBox(height: 16),
                      _buildClearDataButton(colors),
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

  Widget _buildWarningCard(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: colors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '此页面仅供开发者调试使用，生成的数据将直接写入本地数据库。',
              style: TextStyle(fontSize: 12, color: colors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestDataGeneratorEntry(ThemeColors colors) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TestDataGeneratorPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ThemeDecorations.card(context),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🎲', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '测试数据生成器',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '生成随机排便记录用于测试',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildShowRequestDetailsToggle(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔍', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'AI对话请求详情',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '显示请求详情按钮',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI回复完成后可查看请求详情',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _showRequestDetails,
                onChanged: (value) async {
                  await LocalDbService.setSetting(
                    'show_request_details',
                    value.toString(),
                  );
                  setState(() {
                    _showRequestDetails = value;
                  });
                },
                activeColor: colors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClearDataButton(ThemeColors colors) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _showClearConfirm,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.error,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
        ),
        child: const Text(
          '🗑️ 清空所有数据',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showClearConfirm() {
    final colors = context.read<ThemeProvider>().colors;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认清空'),
            content: const Text('确定要清空所有排便记录吗？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '取消',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _clearAllData();
                },
                style: ElevatedButton.styleFrom(backgroundColor: colors.error),
                child: const Text(
                  '确认清空',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      final records = await LocalDbService.getRecords();
      for (final record in records) {
        await LocalDbService.deleteRecord(record.recordId);
      }
      _showSuccess('已清空 ${records.length} 条记录');
    } catch (e) {
      _showError('清空失败：$e');
    }
  }

  void _showSuccess(String message) {
    final colors = context.read<ThemeProvider>().colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: colors.success),
    );
  }

  void _showError(String message) {
    final colors = context.read<ThemeProvider>().colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: colors.error),
    );
  }
}
