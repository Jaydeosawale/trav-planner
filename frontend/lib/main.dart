import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: TravPlannerApp()));
}

class TravPlannerApp extends StatelessWidget {
  const TravPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trav Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: Uri.base.fragment.startsWith('reset_token=')
          ? ResetPasswordPage(
              token:
                  Uri.splitQueryString(Uri.base.fragment)['reset_token'] ?? '',
            )
          : const SplashPage(),
    );
  }
}
