import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../widgets/error_dialog.dart';
import 'home_page.dart';
import 'main_container.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isBiometricAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      await ApiService.login(_emailController.text, _passwordController.text);
      if (mounted) {
        _showEnableBiometricDialog();
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        final errorStr = e.toString();
        final cleanMessage = errorStr.replaceAll('Exception: ', '');
        ErrorDialog.show(
          context,
          title: '登录失败',
          message: '登录过程中发生错误',
          details: cleanMessage,
        );
      }
    }
  }

  Future<void> _biometricLogin() async {
    setState(() => _loading = true);

    try {
      final success = await BiometricService.loginWithBiometric();
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ErrorDialog.show(
            context,
            title: '生物识别登录失败',
            message: '验证失败或凭证已过期',
            details: '请使用密码登录',
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        final errorStr = e.toString();
        final cleanMessage = errorStr.replaceAll('Exception: ', '');
        ErrorDialog.show(
          context,
          title: '登录失败',
          message: '生物识别登录过程中发生错误',
          details: cleanMessage,
        );
      }
    }
  }

  void _showEnableBiometricDialog() async {
    final alreadyEnabled = await BiometricService.isBiometricEnabled();
    if (alreadyEnabled) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
      return;
    }

    final available = await BiometricService.isBiometricAvailable();
    if (!available || !mounted) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('启用生物识别登录'),
            content: const Text('是否启用指纹/面容识别快速登录？下次登录时无需输入密码。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
                child: const Text('暂不启用'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await BiometricService.enableBiometric(
                    _emailController.text,
                    _passwordController.text,
                  );
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
                child: const Text('启用'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
                    '登录',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('欢迎回来', style: TextStyle(color: colors.textSecondary)),
                  const SizedBox(height: 32),
                  _buildTextField(
                    '邮箱',
                    _emailController,
                    colors: colors,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    '密码',
                    _passwordController,
                    colors: colors,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    isPassword: true,
                    onToggleVisibility:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _loading ? '登录中...' : '登录',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  if (_biometricAvailable && _biometricEnabled) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: colors.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '或',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                        Expanded(child: Divider(color: colors.divider)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _biometricLogin,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('生物识别登录'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '还没有账号？',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            ),
                        child: Text(
                          '立即注册',
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
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainContainer()),
                        );
                      }
                    },
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
    FocusNode? focusNode,
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? onToggleVisibility,
    bool isPassword = false,
    ValueChanged<String>? onSubmitted,
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
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
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
