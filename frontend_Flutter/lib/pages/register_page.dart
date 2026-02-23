import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../services/api_service.dart';
import '../widgets/error_dialog.dart';
import 'home_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _register() async {
    if (_passwordController.text.length < 6) {
      ErrorDialog.show(context, title: '错误', message: '密码长度至少6位');
      return;
    }

    setState(() => _loading = true);

    try {
      await ApiService.register(
        _emailController.text,
        _passwordController.text,
        nickname:
            _nicknameController.text.isNotEmpty
                ? _nicknameController.text
                : null,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        final errorStr = e.toString();
        final cleanMessage = errorStr.replaceAll('Exception: ', '');
        ErrorDialog.show(
          context,
          title: '注册失败',
          message: '注册过程中发生错误',
          details: cleanMessage,
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;

    return Scaffold(
      body: Container(
        decoration: ThemeDecorations.backgroundGradient(
          context,
          mode: themeProvider.mode,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🚽', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 24),
                  Text(
                    '注册',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('创建您的账号', style: TextStyle(color: colors.textSecondary)),
                  const SizedBox(height: 32),
                  _buildTextField(
                    '邮箱',
                    _emailController,
                    colors: colors,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    '昵称',
                    _nicknameController,
                    colors: colors,
                    hintText: '可选，默认使用邮箱前缀',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    '密码',
                    _passwordController,
                    colors: colors,
                    obscureText: _obscurePassword,
                    isPassword: true,
                    onToggleVisibility:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _loading ? '注册中...' : '注册',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '已有账号？',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            ),
                        child: Text(
                          '立即登录',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      '← 返回首页',
                      style: TextStyle(color: colors.textHint, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    required ThemeColors colors,
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? onToggleVisibility,
    bool isPassword = false,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintText: hintText,
            hintStyle: TextStyle(color: colors.textHint, fontSize: 14),
            suffixIcon:
                isPassword
                    ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: colors.textSecondary,
                      ),
                      onPressed: onToggleVisibility,
                    )
                    : null,
          ),
        ),
      ],
    );
  }
}
