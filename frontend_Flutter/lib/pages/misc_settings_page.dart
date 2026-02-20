import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';

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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxYear = prefs.getInt('max_year') ?? 2112;
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_year', year);
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
      return Scaffold(
        body: Container(
          decoration: ThemeDecorations.backgroundGradient(
            context,
            mode: themeProvider.mode,
          ),
          child: Center(
            child: Text(
              '加载中...',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ),
      );
    }

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
                  child: Column(children: [_buildYearSetting(colors)]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
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
            '其他设置',
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
