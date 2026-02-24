import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';

class ExportOptions {
  final bool includeSettings;
  final bool includeApiConfig;
  final bool includeRecords;
  final bool includeChatHistory;

  const ExportOptions({
    this.includeSettings = true,
    this.includeApiConfig = false,
    this.includeRecords = true,
    this.includeChatHistory = true,
  });

  bool get hasAnySelected =>
      includeSettings ||
      includeApiConfig ||
      includeRecords ||
      includeChatHistory;
}

class ExportOptionsDialog extends StatefulWidget {
  final ExportOptions? initialOptions;

  const ExportOptionsDialog({super.key, this.initialOptions});

  static Future<ExportOptions?> show(
    BuildContext context, {
    ExportOptions? initialOptions,
  }) {
    return showDialog<ExportOptions>(
      context: context,
      builder: (context) =>
          ExportOptionsDialog(initialOptions: initialOptions),
    );
  }

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  late bool _includeSettings;
  late bool _includeApiConfig;
  late bool _includeRecords;
  late bool _includeChatHistory;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialOptions ?? const ExportOptions();
    _includeSettings = initial.includeSettings;
    _includeApiConfig = initial.includeApiConfig;
    _includeRecords = initial.includeRecords;
    _includeChatHistory = initial.includeChatHistory;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return AlertDialog(
      backgroundColor: colors.card,
      title: Row(
        children: [
          Icon(Icons.file_download, color: colors.primary),
          const SizedBox(width: 8),
          Text('导出选项', style: TextStyle(color: colors.textPrimary)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckboxTile(
              title: '应用设置',
              subtitle: '主题、日期范围等',
              icon: Icons.settings_outlined,
              value: _includeSettings,
              onChanged: (v) => setState(() => _includeSettings = v),
            ),
            const SizedBox(height: 8),
            _buildCheckboxTile(
              title: 'API 配置设置',
              subtitle: 'DeepSeek API Key 等敏感信息',
              icon: Icons.key_outlined,
              value: _includeApiConfig,
              onChanged: (v) => setState(() => _includeApiConfig = v),
              isWarning: true,
            ),
            if (_includeApiConfig) ...[
              const SizedBox(height: 8),
              _buildWarningBanner(colors),
            ],
            const SizedBox(height: 8),
            _buildCheckboxTile(
              title: '排便记录',
              subtitle: '所有历史排便数据',
              icon: Icons.list_alt,
              value: _includeRecords,
              onChanged: (v) => setState(() => _includeRecords = v),
            ),
            const SizedBox(height: 8),
            _buildCheckboxTile(
              title: 'AI 对话记录',
              subtitle: '与 AI 的所有对话历史',
              icon: Icons.chat_outlined,
              value: _includeChatHistory,
              onChanged: (v) => setState(() => _includeChatHistory = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: _canExport()
              ? () {
                  Navigator.of(context).pop(ExportOptions(
                    includeSettings: _includeSettings,
                    includeApiConfig: _includeApiConfig,
                    includeRecords: _includeRecords,
                    includeChatHistory: _includeChatHistory,
                  ));
                }
              : null,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('导出'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.textOnPrimary,
            disabledBackgroundColor: colors.textHint.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isWarning = false,
  }) {
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      decoration: BoxDecoration(
        color: isWarning && value
            ? colors.warning.withValues(alpha: 0.1)
            : colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning && value
              ? colors.warning.withValues(alpha: 0.3)
              : colors.divider,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isWarning ? colors.warning : colors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        activeColor: isWarning ? colors.warning : colors.primary,
        checkColor: colors.textOnPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildWarningBanner(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ThemeDecorations.warningCard(context),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '导出API配置可能存在安全风险，请妥善保管导出文件',
              style: TextStyle(
                fontSize: 12,
                color: colors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canExport() {
    return _includeSettings ||
        _includeApiConfig ||
        _includeRecords ||
        _includeChatHistory;
  }
}
