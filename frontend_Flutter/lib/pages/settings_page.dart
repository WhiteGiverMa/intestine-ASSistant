import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/themed_switch.dart';
import '../widgets/app_header.dart';
import 'about_page.dart';
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

class SettingsPageContent extends StatelessWidget {
  const SettingsPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPage();
  }
}

class _SettingsPageState extends State<SettingsPage> {
  bool _devMode = false;

  @override
  void initState() {
    super.initState();
    _loadDevMode();
  }

  Future<void> _loadDevMode() async {
    // Dev mode is stored locally
    setState(() {
      _devMode = false; // Default to false
    });
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
              const AppHeader(title: '设置'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildThemeButton(colors),
                      const SizedBox(height: 16),
                      _buildAiChatOptionsButton(colors),
                      const SizedBox(height: 16),
                      _buildUserButton(colors, authProvider),
                      const SizedBox(height: 16),
                      _buildMiscButton(colors),
                      const SizedBox(height: 16),
                      _buildDevModeToggle(colors),
                      const SizedBox(height: 16),
                      if (_devMode) _buildDevTools(colors),
                      const SizedBox(height: 16),
                      _buildAboutButton(colors),
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

  Widget _buildUserButton(ThemeColors colors, AuthProvider authProvider) {
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
                      authProvider.localUser?.nickname ?? '本地用户',
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
                      '日期范围设置',
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
      onChanged: (value) {
        setState(() {
          _devMode = value;
        });
      },
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
}
