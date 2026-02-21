import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/app_header.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import 'login_page.dart';

class UserAccountPage extends StatefulWidget {
  const UserAccountPage({super.key});

  @override
  State<UserAccountPage> createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  String? _email;
  String? _userId;
  String? _nickname;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token != null && userJson != null) {
      final userData = jsonDecode(userJson);
      setState(() {
        _email = userData['email'];
        _userId = userData['user_id'];
        _nickname = userData['nickname'];
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showChangeEmailDialog() {
    final themeProvider = context.read<ThemeProvider>();
    final colors = themeProvider.colors;
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool saving = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('修改邮箱'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前邮箱: $_email',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: '新邮箱',
                        hintText: '请输入新邮箱地址',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: '密码',
                        hintText: '请输入密码以确认',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMsg!,
                        style: TextStyle(color: colors.error, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final newEmail = newEmailController.text.trim();
                          if (newEmail.isEmpty) {
                            setDialogState(() {
                              errorMsg = '请输入新邮箱';
                            });
                            return;
                          }
                          if (!newEmail.contains('@')) {
                            setDialogState(() {
                              errorMsg = '请输入有效的邮箱地址';
                            });
                            return;
                          }
                          if (passwordController.text.isEmpty) {
                            setDialogState(() {
                              errorMsg = '请输入密码';
                            });
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                            errorMsg = null;
                          });

                          try {
                            final updatedEmail = await ApiService.updateEmail(
                              newEmail: newEmail,
                              password: passwordController.text,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              setState(() {
                                _email = updatedEmail;
                              });
                              _showSuccessDialog('邮箱修改成功');
                            }
                          } catch (e) {
                            final errMsg = e.toString().replaceAll(
                              'Exception: ',
                              '',
                            );
                            setDialogState(() {
                              saving = false;
                              errorMsg = errMsg;
                            });
                          }
                        },
                  child: Text(saving ? '处理中...' : '确认修改'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final themeProvider = context.read<ThemeProvider>();
    final colors = themeProvider.colors;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('修改密码'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: '当前密码',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: '新密码',
                        hintText: '至少6个字符',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: '确认新密码',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMsg!,
                        style: TextStyle(color: colors.error, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (newPasswordController.text.length < 6) {
                            setDialogState(() {
                              errorMsg = '新密码至少需要6个字符';
                            });
                            return;
                          }
                          if (newPasswordController.text !=
                              confirmPasswordController.text) {
                            setDialogState(() {
                              errorMsg = '两次输入的新密码不一致';
                            });
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                            errorMsg = null;
                          });

                          try {
                            await ApiService.updatePassword(
                              currentPassword: currentPasswordController.text,
                              newPassword: newPasswordController.text,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              _showSuccessDialog('密码修改成功');
                            }
                          } catch (e) {
                            final errMsg = e.toString().replaceAll(
                              'Exception: ',
                              '',
                            );
                            setDialogState(() {
                              saving = false;
                              errorMsg = errMsg;
                            });
                          }
                        },
                  child: Text(saving ? '处理中...' : '确认修改'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmDialog() {
    final colors = context.read<ThemeProvider>().colors;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出当前账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService.logout();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
              child: Text(
                '确认退出',
                style: TextStyle(color: colors.textOnPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final colors = context.read<ThemeProvider>().colors;
    final emailController = TextEditingController();
    bool deleting = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: colors.error),
                  const SizedBox(width: 8),
                  Text('注销账号', style: TextStyle(color: colors.error)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '此操作将永久删除您的账号和所有数据，且无法恢复！',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Text('请输入您的邮箱以确认：'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: _email,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMsg!,
                      style: TextStyle(color: colors.error, fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: deleting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: deleting
                      ? null
                      : () async {
                          if (emailController.text.trim() != _email) {
                            setDialogState(() {
                              errorMsg = '邮箱输入不正确';
                            });
                            return;
                          }

                          setDialogState(() {
                            deleting = true;
                            errorMsg = null;
                          });

                          try {
                            await ApiService.deleteAccount();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            final errMsg = e.toString().replaceAll(
                              'Exception: ',
                              '',
                            );
                            setDialogState(() {
                              deleting = false;
                              errorMsg = errMsg;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.error,
                  ),
                  child: Text(
                    deleting ? '处理中...' : '确认注销',
                    style: TextStyle(color: colors.textOnPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    final colors = context.read<ThemeProvider>().colors;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: colors.success, size: 48),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
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
              AppHeader(title: '用户', showBackButton: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildAccountInfo(colors),
                      const SizedBox(height: 24),
                      _buildActionButtons(colors),
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

  Widget _buildAccountInfo(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: Text('👤', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          if (_email != null) ...[
            Text(
              _email!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            if (_nickname != null && _nickname!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _nickname!,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'ID: ${_userId ?? ""}',
              style: TextStyle(fontSize: 12, color: colors.textHint),
            ),
          ] else ...[
            Text(
              '未登录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('去登录', style: TextStyle(color: colors.textOnPrimary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeColors colors) {
    if (_email == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildActionButton(
          icon: '📧',
          title: '修改邮箱',
          subtitle: '更改您的登录邮箱',
          onTap: _showChangeEmailDialog,
          colors: colors,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: '🔐',
          title: '修改密码',
          subtitle: '更改您的登录密码',
          onTap: _showChangePasswordDialog,
          colors: colors,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: '🚪',
          title: '退出登录',
          subtitle: '退出当前账号',
          onTap: _showLogoutConfirmDialog,
          textColor: colors.textSecondary,
          colors: colors,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: '⚠️',
          title: '注销账号',
          subtitle: '永久删除账号和所有数据',
          onTap: _showDeleteAccountDialog,
          isDanger: true,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
    Color? textColor,
    required ThemeColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isDanger
              ? Border.all(color: colors.error.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDanger
                    ? colors.error.withValues(alpha: 0.1)
                    : colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDanger ? colors.error : textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDanger
                  ? colors.error.withValues(alpha: 0.5)
                  : colors.textHint,
            ),
          ],
        ),
      ),
    );
  }

}
