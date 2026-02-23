import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'pages/main_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  final authProvider = AuthProvider();
  await themeProvider.initialize();
  await authProvider.initialize();
  runApp(MyApp(themeProvider: themeProvider, authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final AuthProvider authProvider;

  const MyApp({
    super.key,
    required this.themeProvider,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, theme, auth, child) {
          return MaterialApp(
            title: '肠道健康助手',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
            locale: const Locale('zh', 'CN'),
            theme: AppTheme.getTheme(theme.mode),
            home: const MainContainer(),
          );
        },
      ),
    );
  }
}
