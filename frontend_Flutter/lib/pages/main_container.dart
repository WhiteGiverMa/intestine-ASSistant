import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_decorations.dart';
import '../widgets/app_bottom_nav.dart';
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

  void _onNavigate(NavTab tab) {
    setState(() {
      _currentIndex = tab.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final pages = [
      HomePage(onNavigate: _onNavigate),
      const DataPage(),
      AnalysisPage(onNavigate: _onNavigate),
      const SettingsPage(),
    ];

    return Scaffold(
      body: Container(
        decoration: ThemeDecorations.backgroundGradient(
          context,
          mode: themeProvider.mode,
        ),
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: NavTab.values[_currentIndex],
        onNavigate: _onNavigate,
      ),
    );
  }
}
