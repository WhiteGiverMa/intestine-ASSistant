import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/local_db_service.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/base_page.dart';

class MiscSettingsPage extends StatefulWidget {
  const MiscSettingsPage({super.key});

  @override
  State<MiscSettingsPage> createState() => _MiscSettingsPageState();
}

class _MiscSettingsPageState extends State<MiscSettingsPage> {
  int _maxYear = 2112;
  bool _loading = true;

  final _yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final savedValue = await LocalDbService.getSetting('max_year');
    setState(() {
      _maxYear = int.tryParse(savedValue ?? '') ?? 2112;
      _yearController.text = _maxYear.toString();
      _loading = false;
    });
  }

  Future<void> _saveMaxYear() async {
    final year = int.tryParse(_yearController.text);
    if (year == null || year < 2012 || year > 9999) {
      _showError('请输入有效的年份（2012-9999）');
      return;
    }

    await LocalDbService.setSetting('max_year', year.toString());
    setState(() => _maxYear = year);
    _showSuccess('最大年份已设置为 $year');
  }

  void _showError(String message) {
    final colors = context.read<ThemeProvider>().colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: colors.error),
    );
  }

  void _showSuccess(String message) {
    final colors = context.read<ThemeProvider>().colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: colors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;

    if (_loading) {
      return BasePage(
        title: '其他设置',
        showBackButton: true,
        useScrollView: false,
        child: Center(
          child: Text(
            '加载中...',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return BasePage(
      title: '其他设置',
      showBackButton: true,
      maxWidth: 600,
      child: Column(children: [_buildYearSetting(colors)]),
    );
  }

  Widget _buildYearSetting(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📅', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '日期范围设置',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '设置日期选择器的最大年份',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '最大年份',
                    hintText: '例如: 2112',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _saveMaxYear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '保存',
                  style: TextStyle(color: colors.textOnPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '当前设置: $_maxYear',
            style: TextStyle(fontSize: 12, color: colors.textHint),
          ),
        ],
      ),
    );
  }
}
