import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/local_db_service.dart';
import '../services/update_check_service.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../widgets/themed_switch.dart';
import '../widgets/app_header.dart';
import '../utils/animations.dart';
import '../utils/responsive_utils.dart';
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

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _devMode = false;
  bool _initialized = false;
  bool _hasUpdate = false;
  bool _isPreRelease = false;
  String? _latestVersion;

  @override
  void initState() {
    super.initState();
    _loadDevMode();
    _checkForUpdate();
  }

  Future<void> _loadDevMode() async {
    final savedValue = await LocalDbService.getSetting('dev_mode');
    if (mounted) {
      setState(() {
        _devMode = savedValue == 'true';
        _initialized = true;
      });
    }
  }

  Future<void> _checkForUpdate() async {
    final updateService = UpdateCheckService();
    final result = await updateService.checkForUpdate();
    if (mounted) {
      setState(() {
        _hasUpdate = result.hasUpdate;
        _latestVersion = result.latestVersion;
        _isPreRelease = result.isPreRelease;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                child: _initialized
                    ? SingleChildScrollView(
                        padding: ResponsiveUtils.responsivePadding(context),
                        child: ResponsiveUtils.constrainedContent(
                          context: context,
                          maxWidth: 700,
                          child: Column(
                            children: [
                              AnimatedEntrance(
                                child: _buildThemeButton(colors),
                              ),
                              const SizedBox(height: 16),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 50),
                                child: _buildAiChatOptionsButton(colors),
                              ),
                              const SizedBox(height: 16),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 100),
                                child: _buildUserButton(colors, authProvider),
                              ),
                              const SizedBox(height: 16),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 150),
                                child: _buildMiscButton(colors),
                              ),
                              const SizedBox(height: 16),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 200),
                                child: _buildDevModeToggle(colors),
                              ),
                              const SizedBox(height: 16),
                              if (_devMode)
                                AnimatedEntrance(
                                  delay: const Duration(milliseconds: 250),
                                  child: _buildDevTools(colors),
                                ),
                              if (_devMode) const SizedBox(height: 16),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 300),
                                child: _buildAboutButton(colors),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
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
        navigateWithFade(context, const ThemeSelectorPage());
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
        navigateWithFade(context, const AiChatOptionsPage());
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
      onChanged: (value) async {
        await LocalDbService.setSetting('dev_mode', value.toString());
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
        navigateWithFade(context, const AboutPage());
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
                    Row(
                      children: [
                        Text(
                          '关于',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (_hasUpdate) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hasUpdate
                          ? '发现新版本 v$_latestVersion'
                          : _isPreRelease
                              ? '当前为测试版本'
                              : '版本信息、开发者',
                      style: TextStyle(
                        fontSize: 12,
                        color: _hasUpdate
                            ? colors.warning
                            : _isPreRelease
                                ? colors.primary
                                : colors.textSecondary,
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
