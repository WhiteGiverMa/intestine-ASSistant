import 'dart:convert';
import 'dart:io' if (dart.library.html) '../utils/io_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/local_db_service.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/app_header.dart';
import '../widgets/export_options_dialog.dart';
import '../utils/file_download.dart';

class UserAccountPage extends StatefulWidget {
  const UserAccountPage({super.key});

  @override
  State<UserAccountPage> createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  final _nicknameController = TextEditingController();
  bool _saving = false;
  bool _clearing = false;
  bool _exporting = false;
  bool _importing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nicknameController.text = authProvider.localUser?.nickname ?? 'Local User';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateNickname(_nicknameController.text.trim());
      setState(() {
        _message = '昵称已更新';
      });
    } catch (e) {
      setState(() {
        _message = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
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
              const AppHeader(title: '用户信息', showBackButton: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoCard(colors, authProvider),
                      const SizedBox(height: 16),
                      _buildNicknameCard(colors),
                      const SizedBox(height: 16),
                      _buildDataManagementCard(colors),
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

  Widget _buildInfoCard(ThemeColors colors, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('👤', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '本地用户',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '用户ID: ${authProvider.localUser?.userId ?? '-'}',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '创建时间: ${authProvider.localUser?.createdAt ?? '-'}',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '数据存储在本地设备，无需登录即可使用所有功能。配置 DeepSeek API Key 后可使用 AI 分析功能。',
              style: TextStyle(fontSize: 12, color: colors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameCard(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✏️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '修改昵称',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              labelText: '昵称',
              hintText: '请输入昵称',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveNickname,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _saving ? '保存中...' : '保存',
                style: TextStyle(fontSize: 14, color: colors.textOnPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ThemeColors colors) {
    final isSuccess = _message!.contains('已更新') ||
        _message!.contains('成功') ||
        _message!.contains('已清除');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isSuccess
                ? colors.success.withValues(alpha: 0.1)
                : colors.error.withValues(alpha: 0.1),
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

  Widget _buildDataManagementCard(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📁', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '数据管理',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Column(
            children: [
              _buildDataRowButton(
                icon: Icons.upload_file,
                label: '导出数据',
                onTap: _exporting ? null : _exportData,
                colors: colors,
                isLoading: _exporting,
              ),
              const SizedBox(height: 12),
              _buildDataRowButton(
                icon: Icons.download,
                label: '导入数据',
                onTap: _importing ? null : _importData,
                colors: colors,
                isLoading: _importing,
              ),
              const SizedBox(height: 12),
              _buildDataRowButton(
                icon: Icons.delete_outline,
                label: '清除数据',
                onTap: _clearing ? null : _clearData,
                colors: colors,
                isDestructive: true,
                isLoading: _clearing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataRowButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required ThemeColors colors,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    final bgColor = isDestructive
        ? colors.error.withValues(alpha: 0.1)
        : colors.primary.withValues(alpha: 0.1);
    final iconColor = isDestructive ? colors.error : colors.primary;

    String displayLabel = label;
    if (isLoading) {
      if (label == '导出数据') {
        displayLabel = '导出中...';
      } else if (label == '导入数据') {
        displayLabel = '导入中...';
      } else if (label == '清除数据') {
        displayLabel = '清除中...';
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            else
              Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 14,
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    final options = await ExportOptionsDialog.show(context);
    if (options == null) return;

    setState(() => _exporting = true);

    try {
      final data = await LocalDbService.exportAllData(
        includeSettings: options.includeSettings,
        includeApiConfig: options.includeApiConfig,
        includeRecords: options.includeRecords,
        includeChatHistory: options.includeChatHistory,
      );
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'intestine_backup_$timestamp.json';

      await downloadJsonFile(jsonStr: jsonStr, fileName: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据导出成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _importing = true);

      final file = result.files.first;
      String jsonStr;

      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) throw Exception('无法读取文件');
        jsonStr = utf8.decode(bytes);
      } else {
        final path = file.path;
        if (path == null) throw Exception('无法获取文件路径');
        final f = File(path);
        jsonStr = await f.readAsString();
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (data['version'] == null) {
        throw Exception('无效的备份文件格式');
      }

      final preview = LocalDbService.getImportPreview(data);
      final confirmed = await _showImportPreviewDialog(preview);

      if (confirmed != null && mounted) {
        await LocalDbService.importAllData(data, overwrite: confirmed);
        if (!mounted) return;
        final authProvider = context.read<AuthProvider>();
        await authProvider.refreshUser();
        _nicknameController.text =
            authProvider.localUser?.nickname ?? 'Local User';
        _showSuccess('数据导入成功');
      }
    } catch (e) {
      _showError('导入失败: $e');
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  Future<bool?> _showImportPreviewDialog(Map<String, dynamic> preview) {
    final themeProvider = context.read<ThemeProvider>();
    final colors = themeProvider.colors;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        title: Row(
          children: [
            Icon(Icons.preview, color: colors.primary),
            const SizedBox(width: 8),
            Text('导入预览', style: TextStyle(color: colors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preview['exported_at'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '导出时间: ${preview['exported_at']}',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ),
            _buildPreviewItem('用户信息', preview['users'] ?? 0, colors),
            _buildPreviewItem('排便记录', preview['bowel_records'] ?? 0, colors),
            _buildPreviewItem('聊天会话', preview['chat_sessions'] ?? 0, colors),
            _buildPreviewItem('聊天消息', preview['chat_messages'] ?? 0, colors),
            _buildPreviewItem('设置项', preview['settings'] ?? 0, colors),
            const SizedBox(height: 16),
            Text(
              '请选择导入模式:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: colors.primary),
            child: const Text('合并'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.warning,
              foregroundColor: colors.textOnPrimary,
            ),
            child: const Text('覆盖'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, int count, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count 条',
              style: TextStyle(fontSize: 12, color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    setState(() {
      _message = message;
    });
  }

  void _showError(String message) {
    setState(() {
      _message = message;
    });
  }

  Future<void> _clearData() async {
    final themeProvider = context.read<ThemeProvider>();
    final colors = themeProvider.colors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        title: Text('确认清除', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          '此操作将永久删除所有数据，包括排便记录、聊天记录和设置。是否继续？',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _clearing = true);

    try {
      await DatabaseService.resetDatabase();
      final newUser = await LocalDbService.createLocalUser();

      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUser();

      _nicknameController.text = newUser.nickname;

      setState(() {
        _message = '数据已清除';
      });
    } catch (e) {
      setState(() {
        _message = '清除失败: $e';
      });
    } finally {
      setState(() => _clearing = false);
    }
  }
}
