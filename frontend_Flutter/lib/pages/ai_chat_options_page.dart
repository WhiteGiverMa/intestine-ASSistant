import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/themed_switch.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';

class AiChatOptionsPage extends StatefulWidget {
  const AiChatOptionsPage({super.key});

  @override
  State<AiChatOptionsPage> createState() => _AiChatOptionsPageState();
}

class _AiChatOptionsPageState extends State<AiChatOptionsPage> {
  bool _aiAutoTitle = false;
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
        _aiAutoTitle = settings['ai_auto_title'] ?? false;
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

  Future<void> _handleAiAutoTitleToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => _message = '请先登录');
      return;
    }

    setState(() {
      _aiAutoTitle = value;
      _saving = true;
      _message = null;
    });

    try {
      await ApiService.updateUserSettings(aiAutoTitle: value);
      setState(() {
        _message = value ? '已开启AI自动命名' : '已关闭AI自动命名，使用本地命名';
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (_isAuthError(errorMsg)) {
        await _handleAuthError();
        setState(() => _aiAutoTitle = !value);
      } else {
        setState(() {
          _aiAutoTitle = !value;
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
        aiAutoTitle: _aiAutoTitle,
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

  Future<void> _clearAllChatHistory() async {
    final colors = context.read<ThemeProvider>().colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有对话'),
        content: const Text('确定要清除所有对话记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确定', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.clearChatHistory();
        setState(() {
          _message = '所有对话已清除';
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
      }
    }
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
                  child: Column(
                    children: [
                      _buildApiConfigSection(colors),
                      const SizedBox(height: 16),
                      _buildClearChatSection(colors),
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        _buildMessage(colors),
                      ],
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
            'AI对话选项',
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

  Widget _buildApiConfigSection(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔑', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'API 配置',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '配置AI API后，系统将使用AI进行智能分析；未配置则使用本地规则分析。',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
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
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '支持的API格式：',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.info,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• DeepSeek: https://api.deepseek.com/v1\n'
                  '• OpenAI兼容API: 填写对应的Base URL\n'
                  '• 本地部署模型: 填写本地服务地址',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAiAutoTitleToggle(colors),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _handleSaveAiConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _saving ? '保存中...' : '💾 保存AI配置',
                style: TextStyle(fontSize: 14, color: colors.textOnPrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildApiLinks(colors),
        ],
      ),
    );
  }

  Widget _buildApiLinks(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLinkButton(
          'SiliconFlow',
          'https://siliconflow.cn',
          colors.secondary,
        ),
        const SizedBox(width: 16),
        _buildLinkButton('DeepSeek', 'https://deepseek.com', colors.info),
      ],
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
          border: Border.all(color: color),
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

  Widget _buildAiAutoTitleToggle(ThemeColors colors) {
    return ThemedSwitchWithTitle(
      value: _aiAutoTitle,
      onChanged: _saving ? null : _handleAiAutoTitleToggle,
      title: 'AI自动命名对话',
      subtitle: '开启后使用AI生成对话标题，关闭则使用消息前20字',
    );
  }

  Widget _buildClearChatSection(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🗑️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '对话管理',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '清除所有AI对话记录，释放存储空间。',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _clearAllChatHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.errorBackground,
                foregroundColor: colors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.error.withValues(alpha: 0.3)),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '清除所有对话',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ThemeColors colors) {
    final isSuccess =
        _message!.contains('成功') ||
        _message!.contains('已清除') ||
        _message!.contains('已开启') ||
        _message!.contains('已关闭');
    final isAuthError = _message!.contains('登录');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess
            ? colors.success.withValues(alpha: 0.1)
            : colors.errorBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            _message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isSuccess ? colors.success : colors.error,
            ),
          ),
          if (isAuthError) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔑', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    '返回设置页',
                    style: TextStyle(fontSize: 12, color: colors.textOnPrimary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
