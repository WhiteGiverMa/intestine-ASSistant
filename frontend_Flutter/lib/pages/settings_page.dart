import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../services/api_service.dart';
import '../widgets/themed_switch.dart';
import 'data_page.dart';
import 'analysis_page.dart';
import 'about_page.dart';
import 'login_page.dart';
import 'misc_settings_page.dart';
import 'dev_tools_page.dart';
import 'user_account_page.dart';
import 'ai_chat_options_page.dart';
import 'theme_selector_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _devMode = false;
  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final settings = await ApiService.getUserSettings();
      setState(() {
        _devMode = settings['dev_mode'] ?? false;
        _loading = false;
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (_isAuthError(errorMsg)) {
        await _handleAuthError();
      }
      setState(() => _loading = false);
    }
  }

  bool _isAuthError(String errorMsg) {
    final lowerMsg = errorMsg.toLowerCase();
    return lowerMsg.contains('认证') ||
        lowerMsg.contains('token') ||
        lowerMsg.contains('令牌') ||
        lowerMsg.contains('authenticated') ||
        lowerMsg.contains('unauthorized');
  }

  Future<void> _handleAuthError() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    if (mounted) {
      setState(() => _message = '登录已过期，请重新登录');
    }
  }

  Future<void> _handleDevModeToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => _message = '请先登录');
      return;
    }

    setState(() {
      _devMode = value;
      _saving = true;
      _message = null;
    });

    try {
      await ApiService.updateUserSettings(devMode: value);
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (_isAuthError(errorMsg)) {
        await _handleAuthError();
        setState(() => _devMode = !value);
      } else {
        setState(() {
          _devMode = !value;
          _message = errorMsg;
        });
      }
    } finally {
      setState(() => _saving = false);
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
              _buildHeader(colors),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildThemeButton(colors),
                      const SizedBox(height: 16),
                      _buildAiChatOptionsButton(colors),
                      const SizedBox(height: 16),
                      _buildUserButton(colors),
                      const SizedBox(height: 16),
                      _buildMiscButton(colors),
                      const SizedBox(height: 16),
                      _buildDevModeToggle(colors),
                      const SizedBox(height: 16),
                      if (_devMode) _buildDevTools(colors),
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        _buildMessage(colors),
                      ],
                      const SizedBox(height: 16),
                      _buildAboutButton(colors),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ThemeDecorations.header(context, mode: context.themeMode),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              '←',
              style: TextStyle(fontSize: 20, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(ThemeColors colors) {
    final themeProvider = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ThemeSelectorPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ThemeDecorations.card(context, mode: themeProvider.mode),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: ThemeDecorations.iconContainer(
                    context,
                    mode: themeProvider.mode,
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Text('🎨', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '主题',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      themeProvider.mode.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildAiChatOptionsButton(ThemeColors colors) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiChatOptionsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ThemeDecorations.card(context, mode: context.themeMode),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: ThemeDecorations.iconContainer(
                    context,
                    mode: context.themeMode,
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI对话选项',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'API配置、清除对话',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildUserButton(ThemeColors colors) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserAccountPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ThemeDecorations.card(context, mode: context.themeMode),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: ThemeDecorations.iconContainer(
                    context,
                    mode: context.themeMode,
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Text('👤', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '用户',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '账号管理、修改密码、退出登录',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMiscButton(ThemeColors colors) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MiscSettingsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ThemeDecorations.card(context, mode: context.themeMode),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: ThemeDecorations.iconContainer(
                    context,
                    mode: context.themeMode,
                    backgroundColor: colors.warning.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Text('⚙️', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '杂项',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '系统记录最大年份等设置',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDevModeToggle(ThemeColors colors) {
    return ThemedSwitchWithTitle(
      value: _devMode,
      onChanged: _saving ? null : _handleDevModeToggle,
      title: '开发者模式',
      subtitle: '启用测试和调试工具',
    );
  }

  Widget _buildDevTools(ThemeColors colors) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DevToolsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ThemeDecorations.card(context, mode: context.themeMode),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: ThemeDecorations.iconContainer(
                    context,
                    mode: context.themeMode,
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Text('🛠️', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '开发者工具包',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '测试数据生成器',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ThemeColors colors) {
    final isSuccess = _message!.contains('成功');
    final isAuthError = _message!.contains('登录');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess
            ? colors.success.withValues(alpha: 0.1)
            : colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            _message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isSuccess ? colors.success : colors.error,
            ),
          ),
          if (isAuthError) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔑', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text('去登录', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutButton(ThemeColors colors) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ThemeDecorations.card(context, mode: context.themeMode),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: ThemeDecorations.iconContainer(
                    context,
                    mode: context.themeMode,
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Text('ℹ️', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '关于',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '版本信息、开发者',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(ThemeColors colors) {
    return Container(
      decoration: ThemeDecorations.bottomNav(context, mode: context.themeMode),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              '🏠',
              '首页',
              false,
              () => Navigator.pop(context),
              colors,
            ),
            _buildNavItem('📊', '数据', false, const DataPage(), colors),
            _buildNavItem('🤖', '分析', false, const AnalysisPage(), colors),
            _buildNavItem('⚙️', '设置', true, null, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String emoji,
    String label,
    bool isActive,
    dynamic target,
    ThemeColors colors,
  ) {
    return GestureDetector(
      onTap: target != null
          ? () {
              if (target is VoidCallback) {
                target();
              } else if (target is Widget) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => target),
                );
              }
            }
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? colors.primary : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
