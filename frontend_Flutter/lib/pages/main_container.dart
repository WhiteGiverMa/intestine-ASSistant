import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_decorations.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/page_flip_container.dart';
import '../utils/responsive_utils.dart';
import 'home_page.dart';
import 'data_page.dart';
import 'analysis_page.dart';
import 'settings_page.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onNavigate: _onNavigate),
      const DataPage(),
      AnalysisPage(onNavigate: _onNavigate),
      const SettingsPage(),
    ];
  }

  void _onNavigate(NavTab tab) {
    final index = tab.index;
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= Breakpoints.tablet;

        return Scaffold(
          body: Container(
            decoration: ThemeDecorations.backgroundGradient(
              context,
              mode: themeProvider.mode,
            ),
            child: Row(
              children: [
                if (isWide) _buildNavigationRail(colors),
                Expanded(
                  child: PageFlipContainer(
                    currentIndex: _currentIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : AppBottomNav(
                  activeTab: NavTab.values[_currentIndex],
                  onNavigate: _onNavigate,
                ),
        );
      },
    );
  }

  Widget _buildNavigationRail(ThemeColors colors) {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        if (index != _currentIndex) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: colors.card.withValues(alpha: 0.95),
      selectedIconTheme: IconThemeData(color: colors.primary),
      unselectedIconTheme: IconThemeData(color: colors.textSecondary),
      selectedLabelTextStyle: TextStyle(
        color: colors.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(color: colors.textSecondary),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('首页'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.storage_outlined),
          selectedIcon: Icon(Icons.storage),
          label: Text('数据'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('分析'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('设置'),
        ),
      ],
    );
  }
}
