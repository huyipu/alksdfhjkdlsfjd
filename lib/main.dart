import 'package:flutter/material.dart';
import 'pages/splash_page.dart';
import 'utils/prefs.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TlbbApp());
}

class TlbbApp extends StatefulWidget {
  const TlbbApp({super.key});

  @override
  State<TlbbApp> createState() => _TlbbAppState();
}

class _TlbbAppState extends State<TlbbApp> {
  @override
  void initState() {
    super.initState();
    Prefs().init().then((_) => ThemeController().load());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController().mode,
      builder: (_, mode, __) => MaterialApp(
        title: '天龙亿旧',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: mode,
        home: const SplashPage(),
      ),
    );
  }
}
