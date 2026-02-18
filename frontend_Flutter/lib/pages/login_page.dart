import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/error_dialog.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      await ApiService.login(_emailController.text, _passwordController.text);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFB2DFDB)],
          ),
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
                  const Text('登录', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('欢迎回来', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 32),
                  _buildTextField('邮箱', _emailController, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(
                    '密码',
                    _passwordController,
                    obscureText: _obscurePassword,
                    isPassword: true,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_loading ? '登录中...' : '登录', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('还没有账号？', style: TextStyle(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                        child: const Text('立即注册', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('← 返回首页', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false, TextInputType? keyboardType, VoidCallback? onToggleVisibility, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
