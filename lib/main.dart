import 'package:flutter/material.dart';
import 'api.dart';
import 'theme.dart';
import 'services/notifications.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.i.loadToken();
  // Init notifications early (best-effort; won't block startup).
  Notifications.i.init();
  runApp(const NaitriApp());
}

class NaitriApp extends StatelessWidget {
  const NaitriApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naitri',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Api.i.token == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
