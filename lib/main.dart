import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/mobile_canvas.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase isn't linked yet (see lib/firebase_options.dart). The app
    // still launches so the UI can be reviewed; run `flutterfire configure`
    // before testing real Phone Authentication.
    debugPrint('Firebase init skipped: $e');
  }
  runApp(const KaamSetuApp());
}

class KaamSetuApp extends StatelessWidget {
  const KaamSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KaamSetu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      builder: (context, child) =>
          MobileCanvas(child: child ?? const SizedBox.shrink()),
    );
  }
}
