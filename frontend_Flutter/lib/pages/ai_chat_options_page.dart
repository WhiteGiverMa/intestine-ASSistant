import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/deepseek_service.dart';
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
  bool _testing = false;
  String? _message;
  bool _obscureApiKey = true;

  final _aiApiKeyController = TextEditingController();
  final _aiApiUrlController = TextEditingController();
  final _aiModelController = TextEditingController();
  final _systemPromptController = TextEditingController();
  final _systemPromptFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _systemPromptFocusNode.addListener(_onSystemPromptFocusLost);
    _loadSettings();
  }

  @override
  void dispose() {
    _systemPromptFocusNode.removeListener(_onSystemPromptFocusLost);
    _systemPromptFocusNode.dispose();
    _aiApiKeyController.dispose();
    _aiApiUrlController.dispose();
    _aiModelController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _onSystemPromptFocusLost() {
    if (!_systemPromptFocusNode.hasFocus) {
      _saveSystemPrompt();
    }
  }

  Future<void> _saveSystemPrompt() async {
    final promptText = _systemPromptController.text.trim();
    final promptToSave =
        (promptText.isEmpty ||
                promptText == DeepSeekService.kDefaultSystemPrompt)
            ? ''
            : promptText;

    try {
      await ApiService.updateUserSettings(defaultSystemPrompt: promptToSave);
    } catch (e) {
      debugPrint('保存系统提示词失败: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ApiService.getUserSettings();
      final savedPrompt = settings['default_system_prompt'] ?? '';
      setState(() {
        _aiApiKeyController.text = settings['ai_api_key'] ?? '';
        _aiApiUrlController.text =
            settings['ai_api_url'] ?? 'https://api.deepseek.com';
        _aiModelController.text = settings['ai_model'] ?? 'deepseek-chat';
        _systemPromptController.text =
            savedPrompt.isNotEmpty
                ? savedPrompt
                : DeepSeekService.kDefaultSystemPrompt;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _systemPromptController.text = DeepSeekService.kDefaultSystemPrompt;
        _loading = false;
      });
    }
  }

  Future<void> _handleSaveAiConfig() async {
    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      final promptText = _systemPromptController.text.trim();
      final promptToSave =
          (promptText.isEmpty ||
                  promptText == DeepSeekService.kDefaultSystemPrompt)
              ? ''
              : promptText;

      await ApiService.updateUserSettings(
        aiApiKey: _aiApiKeyController.text.trim(),
        aiApiUrl: _aiApiUrlController.text.trim(),
        aiModel: _aiModelController.text.trim(),
        defaultSystemPrompt: promptToSave,
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

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _message = null;
    });

    try {
      await DeepSeekService.testConnection();
      setState(() {
        _message = '✅ 连接测试成功！API 配置有效';
      });
    } catch (e) {
      setState(() {
        _message = '❌ ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _clearAllChatHistory() async {
    final colors = context.read<ThemeProvider>().colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
              const AppHeader(title: 'AI对话选项', showBackButton: true),
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
                'AI API 配置',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '支持 OpenAI API 格式的服务，如 DeepSeek、硅基流动、OpenAI 等。',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildQuickConfigButtons(colors),
          const SizedBox(height: 16),
          TextField(
            controller: _aiApiKeyController,
            decoration: InputDecoration(
              labelText: 'API 密钥',
              hintText: '输入您的 API Key',
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
                onPressed:
                    () => setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ),
            obscureText: _obscureApiKey,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aiApiUrlController,
            decoration: InputDecoration(
              labelText: 'API URL',
              hintText: '如: https://api.deepseek.com',
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
              hintText: '如: deepseek-chat, gpt-4o-mini',
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
                  '1. 选择服务商并注册账号\n'
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _testing ? null : _testConnection,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
              ),
              child:
                  _testing
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      )
                      : const Text('🔌 测试连接', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 16),
          _buildApiLinks(colors),
        ],
      ),
    );
  }

  Widget _buildQuickConfigButtons(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快捷配置：',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickConfigChip(
              'DeepSeek',
              'https://api.deepseek.com',
              'deepseek-chat',
              colors,
            ),
            _buildQuickConfigChip(
              '硅基流动',
              'https://api.siliconflow.cn/v1',
              'deepseek-ai/DeepSeek-V3.2',
              colors,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickConfigChip(
    String label,
    String apiUrl,
    String model,
    ThemeColors colors,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _aiApiUrlController.text = apiUrl;
          _aiModelController.text = model;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
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
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                '系统提示词',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _systemPromptController.text =
                      DeepSeekService.kDefaultSystemPrompt;
                  setState(() {});
                },
                style: TextButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                ),
                child: const Text('恢复默认'),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '自定义 AI 对话的系统提示词，留空或使用默认值将使用系统默认设置。',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              TextField(
                controller: _systemPromptController,
                focusNode: _systemPromptFocusNode,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '输入自定义系统提示词...',
                  hintStyle: TextStyle(color: colors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.only(
                    left: 12,
                    right: 40,
                    top: 12,
                    bottom: 12,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  icon: Icon(
                    Icons.open_in_full,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  tooltip: '展开编辑',
                  onPressed: () => _showExpandedPromptEditor(context, colors),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExpandedPromptEditor(BuildContext context, ThemeColors colors) {
    final expandedController = TextEditingController(
      text: _systemPromptController.text,
    );
    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colors.divider)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_note, size: 24, color: colors.primary),
                        const SizedBox(width: 12),
                        Text(
                          '系统提示词',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            expandedController.text =
                                DeepSeekService.kDefaultSystemPrompt;
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                          ),
                          child: const Text('恢复默认'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: expandedController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: '输入系统提示词...',
                          hintStyle: TextStyle(color: colors.textHint),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          filled: true,
                          fillColor: colors.surface,
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: colors.divider)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                          ),
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            _systemPromptController.text =
                                expandedController.text;
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.textOnPrimary,
                          ),
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildApiLinks(ThemeColors colors) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLinkButton('DeepSeek 官网', 'https://deepseek.com', colors.primary),
        _buildLinkButton('硅基流动官网', 'https://siliconflow.cn', colors.primary),
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
        color:
            isSuccess
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
