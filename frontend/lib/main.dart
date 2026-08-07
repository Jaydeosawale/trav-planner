import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: TravPlannerApp(),
    ),
  );
}

class TravPlannerApp extends StatelessWidget {
  const TravPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trav Planner',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      home: const HomePage(),
    );
  }
}