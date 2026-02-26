import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_decorations.dart';
import '../theme/theme_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../utils/responsive_utils.dart';
import 'home_page.dart';
import 'data_page.dart';
import 'analysis_page.dart';
import 'settings_page.dart';

/// 页面切换容器，使用 PageView 支持滑动手势切换。
///
/// @module: main_container
/// @type: widget
/// @layer: frontend
/// @depends: [providers.theme_provider, theme.theme_decorations, widgets.app_bottom_nav]
/// @exports: [MainContainer]
/// @brief: 应用主容器，管理四个主 Tab 页面的切换和状态保持。
///         使用 PageView 实现滑动手势切换，Tab 点击使用 jumpToPage 无动画切换。

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _pages = [
      HomePage(onNavigate: _onNavigate),
      const DataPage(),
      AnalysisPage(onNavigate: _onNavigate),
      const SettingsPage(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigate(NavTab tab) {
    final index = tab.index;
    if (index != _currentIndex) {
      _pageController.jumpToPage(index);
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onPageChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  ScrollPhysics _getPlatformPhysics() {
    if (kIsWeb) {
      return const ClampingScrollPhysics();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const BouncingScrollPhysics();
    }
    return const ClampingScrollPhysics();
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
                  child: PageView(
                    controller: _pageController,
                    physics: _getPlatformPhysics(),
                    onPageChanged: _onPageChanged,
                    children: _pages,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              isWide
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
    return SafeArea(
      child: NavigationRail(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index != _currentIndex) {
            _pageController.jumpToPage(index);
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
      ),
    );
  }
}
