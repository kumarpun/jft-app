import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/auth_controller.dart';
import 'state/screen_guard.dart';
import 'state/theme_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  themeController.init();
  ScreenGuard().init();
  runApp(const JftSenseiApp());
}

class JftSenseiApp extends StatefulWidget {
  const JftSenseiApp({super.key});
  @override
  State<JftSenseiApp> createState() => _JftSenseiAppState();
}

class _JftSenseiAppState extends State<JftSenseiApp> {
  final AuthController _auth = AuthController()..init();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) => MaterialApp(
      title: 'JFT Sensei',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeController.mode,
      home: ListenableBuilder(
        listenable: _auth,
        builder: (context, _) {
          if (!_auth.ready) {
            return const Scaffold(body: Center(child: BrandLogo(size: 96)));
          }
          return _auth.user == null ? LoginScreen(auth: _auth) : HomeShell(key: ValueKey(_auth.user!.id), auth: _auth);
        },
      ),
    ));
  }
}
