import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/app_header.dart';

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  String? _apiUrl;
  bool _loading = true;

  final _apiUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiUrl = prefs.getString('api_url') ?? 'http://localhost:8001/api/v1';
      _apiUrlController.text = _apiUrl!;
      _loading = false;
    });
  }

  Future<void> _saveApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', _apiUrlController.text.trim());
    setState(() => _apiUrl = _apiUrlController.text.trim());
    _showSuccess('API URL 已更新');
  }

  Future<void> _resetApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_url');
    setState(() {
      _apiUrl = 'http://localhost:8001/api/v1';
      _apiUrlController.text = _apiUrl!;
    });
    _showSuccess('API URL 已重置为默认值');
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
              const AppHeader(title: '开发者工具', showBackButton: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildApiUrlSection(colors),
                      const SizedBox(height: 16),
                      _buildWarningCard(colors),
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

  Widget _buildApiUrlSection(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔧', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'API 配置',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '设置后端 API 地址',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiUrlController,
            decoration: InputDecoration(
              labelText: 'API URL',
              hintText: '例如: http://localhost:8001/api/v1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveApiUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '保存',
                    style: TextStyle(color: colors.textOnPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetApiUrl,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: colors.divider),
                  ),
                  child: const Text('重置'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '当前: $_apiUrl',
            style: TextStyle(fontSize: 12, color: colors.textHint),
          ),
        ],
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
              '此页面仅供开发者调试使用，普通用户请勿修改设置。',
              style: TextStyle(fontSize: 12, color: colors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
