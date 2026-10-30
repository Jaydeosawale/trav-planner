import 'features/places/data/location_memory.dart';
import 'widgets/web_play_store_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/updates/app_update_prompt.dart';

import 'features/auth/presentation/pages/reset_password_page.dart';
import 'app/router/app_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  runApp(const ProviderScope(child: TravPlannerApp()));
}

class TravPlannerApp extends ConsumerWidget {
  const TravPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(locationMemoryProvider);
    if (Uri.base.fragment.startsWith('reset_token=')) {
      return MaterialApp(
        title: 'Trav Planner',
        theme: AppTheme.light,
        home: ResetPasswordPage(
          token: Uri.splitQueryString(Uri.base.fragment)['reset_token'] ?? '',
        ),
      );
    }
    return MaterialApp.router(
      scaffoldMessengerKey: _messengerKey,
      title: 'Trav Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(appRouterProvider),
      builder: (_, child) => AppUpdatePrompt(
        messengerKey: _messengerKey,
        child: WebPlayStoreFrame(
          child: SessionRestorer(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
