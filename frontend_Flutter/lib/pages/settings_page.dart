import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/themed_switch.dart';
import 'data_page.dart';
import 'analysis_page.dart';
import 'about_page.dart';
import 'login_page.dart';
import 'misc_settings_page.dart';
import 'dev_tools_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _devMode = false;
  bool _loading = true;
  bool _saving = false;
  String? _message;
  bool _obscureApiKey = true;

  final _aiApiKeyController = TextEditingController();
  final _aiApiUrlController = TextEditingController();
  final _aiModelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _aiApiKeyController.dispose();
    _aiApiUrlController.dispose();
    _aiModelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final settings = await ApiService.getUserSettings();
      setState(() {
        _devMode = settings['dev_mode'] ?? false;
        _aiApiKeyController.text = settings['ai_api_key'] ?? '';
        _aiApiUrlController.text = settings['ai_api_url'] ?? '';
        _aiModelController.text = settings['ai_model'] ?? '';
        _loading = false;
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (_isAuthError(errorMsg)) {
        await _handleAuthError();
      }
      setState(() => _loading = false);
    }
  }

  bool _isAuthError(String errorMsg) {
    final lowerMsg = errorMsg.toLowerCase();
    return lowerMsg.contains('认证') ||
        lowerMsg.contains('token') ||
        lowerMsg.contains('令牌') ||
        lowerMsg.contains('authenticated') ||
        lowerMsg.contains('unauthorized');
  }

  Future<void> _handleAuthError() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    if (mounted) {
      setState(() => _message = '登录已过期，请重新登录');
    }
  }

  Future<void> _handleDevModeToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => _message = '请先登录');
      return;
    }

    setState(() {
      _devMode = value;
      _saving = true;
      _message = null;
    });

    try {
      await ApiService.updateUserSettings(devMode: value);
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (_isAuthError(errorMsg)) {
        await _handleAuthError();
        setState(() => _devMode = !value);
      } else {
        setState(() {
          _devMode = !value;
          _message = errorMsg;
        });
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _handleSaveAiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => _message = '请先登录');
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      await ApiService.updateUserSettings(
        aiApiKey: _aiApiKeyController.text.trim(),
        aiApiUrl: _aiApiUrlController.text.trim(),
        aiModel: _aiModelController.text.trim(),
      );
      setState(() {
        _message = 'AI配置保存成功';
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (_isAuthError(errorMsg)) {
        await _handleAuthError();
      } else {
        setState(() {
          _message = errorMsg;
        });
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8F5E9), Color(0xFFB2DFDB)],
            ),
          ),
          child: const Center(
            child: Text('加载中...', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFB2DFDB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildAiConfigSection(),
                      const SizedBox(height: 16),
                      _buildMiscButton(),
                      const SizedBox(height: 16),
                      _buildDevModeToggle(),
                      const SizedBox(height: 16),
                      if (_devMode) _buildDevTools(),
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        _buildMessage(),
                      ],
                      const SizedBox(height: 16),
                      _buildAboutButton(),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '←',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiConfigSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'AI 分析配置',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '配置AI API后，系统将使用AI进行智能分析；未配置则使用本地规则分析。',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aiApiKeyController,
            decoration: InputDecoration(
              labelText: 'API 密钥',
              hintText: '输入您的API密钥',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ),
            obscureText: _obscureApiKey,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aiApiUrlController,
            decoration: InputDecoration(
              labelText: 'API URL',
              hintText: '例如: https://api.deepseek.com/v1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aiModelController,
            decoration: InputDecoration(
              labelText: '模型名称',
              hintText: '例如: deepseek-chat',
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '支持的API格式：',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '• DeepSeek: https://api.deepseek.com/v1\n'
                  '• OpenAI兼容API: 填写对应的Base URL\n'
                  '• 本地部署模型: 填写本地服务地址',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _handleSaveAiConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _saving ? '保存中...' : '💾 保存AI配置',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildApiLinks(),
        ],
      ),
    );
  }

  Widget _buildApiLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLinkButton(
          'SiliconFlow',
          'https://siliconflow.cn',
          Colors.purple,
        ),
        const SizedBox(width: 16),
        _buildLinkButton('DeepSeek', 'https://deepseek.com', Colors.blue),
      ],
    );
  }

  Widget _buildMiscButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MiscSettingsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('⚙️', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '杂项',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '系统记录最大年份等设置',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkButton(String label, String url, Color color) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevModeToggle() {
    return ThemedSwitchWithTitle(
      value: _devMode,
      onChanged: _saving ? null : _handleDevModeToggle,
      title: '开发者模式',
      subtitle: '启用测试和调试工具',
    );
  }

  Widget _buildDevTools() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DevToolsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🛠️', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '开发者工具包',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '测试数据生成器',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage() {
    final isSuccess = _message!.contains('成功');
    final isAuthError = _message!.contains('登录');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            _message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isSuccess ? Colors.green : Colors.red,
            ),
          ),
          if (isAuthError) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔑', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    '去登录',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('ℹ️', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '关于',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '版本信息、开发者',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('🏠', '首页', false, () => Navigator.pop(context)),
            _buildNavItem('📊', '数据', false, const DataPage()),
            _buildNavItem('🤖', '分析', false, const AnalysisPage()),
            _buildNavItem('⚙️', '设置', true),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String emoji,
    String label,
    bool isActive, [
    dynamic target,
  ]) {
    return GestureDetector(
      onTap: target != null
          ? () {
              if (target is VoidCallback) {
                target();
              } else if (target is Widget) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => target),
                );
              }
            }
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
