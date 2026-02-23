import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/app_header.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';

class AiChatOptionsPage extends StatefulWidget {
  const AiChatOptionsPage({super.key});

  @override
  State<AiChatOptionsPage> createState() => _AiChatOptionsPageState();
}

class _AiChatOptionsPageState extends State<AiChatOptionsPage> {
  bool _loading = true;
  bool _saving = false;
  String? _message;
  bool _obscureApiKey = true;

  final _aiApiKeyController = TextEditingController();
  final _aiApiUrlController = TextEditingController();
  final _aiModelController = TextEditingController();
  final _systemPromptController = TextEditingController();

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
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ApiService.getUserSettings();
      setState(() {
        _aiApiKeyController.text = settings['ai_api_key'] ?? '';
        _aiApiUrlController.text = settings['ai_api_url'] ?? 'https://api.deepseek.com';
        _aiModelController.text = settings['ai_model'] ?? 'deepseek-chat';
        _systemPromptController.text = settings['default_system_prompt'] ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleSaveAiConfig() async {
    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      await ApiService.updateUserSettings(
        aiApiKey: _aiApiKeyController.text.trim(),
        aiApiUrl: _aiApiUrlController.text.trim(),
        aiModel: _aiModelController.text.trim(),
        defaultSystemPrompt: _systemPromptController.text.trim(),
      );
      setState(() {
        _message = 'AI配置保存成功';
      });
    } catch (e) {
      setState(() {
        _message = e.toString().replaceAll('Exception: ', '');
      });
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
        setState(() {
          _message = e.toString().replaceAll('Exception: ', '');
        });
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
              AppHeader(title: 'AI对话选项', showBackButton: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildApiConfigSection(colors),
                      const SizedBox(height: 16),
                      _buildSystemPromptSection(colors),
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
                'DeepSeek API 配置',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '配置您的 DeepSeek API Key 后，即可使用 AI 智能分析功能。',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aiApiKeyController,
            decoration: InputDecoration(
              labelText: 'API 密钥',
              hintText: '输入您的 DeepSeek API Key',
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
              hintText: '默认: https://api.deepseek.com',
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
              hintText: '默认: deepseek-chat',
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
                  '如何获取 API Key：',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.info,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. 访问 DeepSeek 官网注册账号\n'
                  '2. 进入 API 管理页面创建 Key\n'
                  '3. 复制 Key 粘贴到上方输入框',
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
                _saving ? '保存中...' : '💾 保存配置',
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

  Widget _buildSystemPromptSection(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📝', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '系统提示词',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '自定义 AI 对话的系统提示词，留空使用默认设置。',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _systemPromptController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '输入自定义系统提示词...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiLinks(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLinkButton(
          'DeepSeek 官网',
          'https://deepseek.com',
          colors.primary,
        ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess
            ? colors.success.withValues(alpha: 0.1)
            : colors.errorBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _message!,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: isSuccess ? colors.success : colors.error,
        ),
      ),
    );
  }
}
