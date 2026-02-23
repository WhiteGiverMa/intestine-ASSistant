import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/app_header.dart';

class UserAccountPage extends StatefulWidget {
  const UserAccountPage({super.key});

  @override
  State<UserAccountPage> createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  final _nicknameController = TextEditingController();
  bool _saving = false;
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
              AppHeader(title: '用户信息', showBackButton: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoCard(colors, authProvider),
                      const SizedBox(height: 16),
                      _buildNicknameCard(colors),
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
          Row(
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
          Row(
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
    final isSuccess = _message!.contains('已更新') || _message!.contains('成功');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess
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
}
