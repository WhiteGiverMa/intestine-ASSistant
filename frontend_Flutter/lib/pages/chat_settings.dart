import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';

const String kDefaultSystemPrompt =
    '''You are a professional gut health consultant. You can have friendly conversations with users, answer questions about gut health, and provide professional advice.

If the user shares bowel record data, please analyze and provide suggestions based on this data.

Please reply in Chinese, maintaining a professional yet friendly tone.''';

class ChatSettings extends StatefulWidget {
  final Function(bool enabled, ThinkingIntensity intensity)? onThinkingChanged;
  final Function(String? prompt)? onSystemPromptChanged;
  final Function(bool enabled)? onStreamingChanged;
  final VoidCallback? onClose;

  const ChatSettings({
    super.key,
    this.onThinkingChanged,
    this.onSystemPromptChanged,
    this.onStreamingChanged,
    this.onClose,
  });

  @override
  State<ChatSettings> createState() => _ChatSettingsState();
}

class _ChatSettingsState extends State<ChatSettings> {
  bool _thinkingEnabled = false;
  bool _streamingEnabled = false;
  ThinkingIntensity _thinkingIntensity = ThinkingIntensity.medium;
  String? _systemPrompt;
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _thinkingEnabled = prefs.getBool('thinking_enabled') ?? false;
      _streamingEnabled = prefs.getBool('streaming_enabled') ?? false;
      final intensityStr = prefs.getString('thinking_intensity') ?? 'medium';
      _thinkingIntensity = ThinkingIntensity.fromApiValue(intensityStr);
      _systemPrompt = prefs.getString('system_prompt');
      _promptController.text = _systemPrompt ?? kDefaultSystemPrompt;
    });
  }

  Future<void> _saveThinkingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('thinking_enabled', value);
    setState(() => _thinkingEnabled = value);
    widget.onThinkingChanged?.call(value, _thinkingIntensity);
    if (mounted) {
      widget.onClose?.call();
    }
  }

  Future<void> _saveStreamingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streaming_enabled', value);
    setState(() => _streamingEnabled = value);
    widget.onStreamingChanged?.call(value);
  }

  Future<void> _saveThinkingIntensity(ThinkingIntensity value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('thinking_intensity', value.toApiValue());
    setState(() => _thinkingIntensity = value);
    widget.onThinkingChanged?.call(_thinkingEnabled, value);
  }

  Future<void> _saveSystemPrompt(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedValue = value?.trim();
    if (trimmedValue == null ||
        trimmedValue.isEmpty ||
        trimmedValue == kDefaultSystemPrompt) {
      await prefs.remove('system_prompt');
      setState(() => _systemPrompt = null);
      widget.onSystemPromptChanged?.call(null);
    } else {
      await prefs.setString('system_prompt', trimmedValue);
      setState(() => _systemPrompt = trimmedValue);
      widget.onSystemPromptChanged?.call(trimmedValue);
    }
    if (mounted) {
      widget.onClose?.call();
    }
  }

  void _restoreDefaultPrompt() {
    _promptController.text = kDefaultSystemPrompt;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStreamingSection(colors),
          const Divider(height: 24),
          _buildThinkingSection(colors),
          const Divider(height: 24),
          _buildSystemPromptSection(colors),
        ],
      ),
    );
  }

  Widget _buildStreamingSection(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.stream, size: 20, color: colors.textPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '流式输出',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '逐字显示AI回复，类似ChatGPT体验',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: _streamingEnabled,
              onChanged: _saveStreamingEnabled,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.primary;
                }
                return null;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.primary.withValues(alpha: 0.5);
                }
                return null;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThinkingSection(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, size: 20, color: colors.textPrimary),
            const SizedBox(width: 8),
            Text(
              '深度思考',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Switch(
              value: _thinkingEnabled,
              onChanged: _saveThinkingEnabled,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.primary;
                }
                return null;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.primary.withValues(alpha: 0.5);
                }
                return null;
              }),
            ),
          ],
        ),
        if (_thinkingEnabled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '强度',
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SegmentedButton<ThinkingIntensity>(
                  segments: const [
                    ButtonSegment(
                      value: ThinkingIntensity.low,
                      label: Text('低'),
                    ),
                    ButtonSegment(
                      value: ThinkingIntensity.medium,
                      label: Text('中'),
                    ),
                    ButtonSegment(
                      value: ThinkingIntensity.high,
                      label: Text('高'),
                    ),
                  ],
                  selected: {_thinkingIntensity},
                  onSelectionChanged: (Set<ThinkingIntensity> selection) {
                    _saveThinkingIntensity(selection.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return colors.primary;
                      }
                      return null;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return colors.textOnPrimary;
                      }
                      return null;
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSystemPromptSection(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note, size: 20, color: colors.textPrimary),
            const SizedBox(width: 8),
            Text(
              '系统提示词',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _restoreDefaultPrompt,
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
              ),
              child: const Text('恢复默认'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '自定义系统提示词',
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
              controller: _promptController,
              onSubmitted: _saveSystemPrompt,
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
                onPressed: () => _showExpandedEditor(context, colors),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => _saveSystemPrompt(_promptController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.textOnPrimary,
            ),
            child: const Text('保存'),
          ),
        ),
      ],
    );
  }

  void _showExpandedEditor(BuildContext context, ThemeColors colors) {
    final expandedController = TextEditingController(
      text: _promptController.text,
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
                            expandedController.text = kDefaultSystemPrompt;
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
                            _promptController.text = expandedController.text;
                            _saveSystemPrompt(expandedController.text);
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.textOnPrimary,
                          ),
                          child: const Text('保存'),
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
}

Future<void> showChatSettings(
  BuildContext context, {
  Function(bool enabled, ThinkingIntensity intensity)? onThinkingChanged,
  Function(bool enabled)? onStreamingChanged,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: ChatSettings(
            onThinkingChanged: onThinkingChanged,
            onStreamingChanged: onStreamingChanged,
            onClose: () => Navigator.pop(context),
          ),
        ),
  );
}
