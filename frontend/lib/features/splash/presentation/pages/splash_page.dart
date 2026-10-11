import 'package:trav_planner/core/theme/app_colors.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trav_planner/shared/widgets/brand_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/pages/home_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(milliseconds: 2500), _openNextPage);
  }

  Future<void> _openNextPage() async {
    if (!mounted) return;

    final authNotifier = ref.read(authProvider.notifier);

    await authNotifier.checkSession();

    if (!mounted) return;

    final authState = ref.read(authProvider);

    final Widget nextPage;

    switch (authState.status) {
      case AuthStatus.authenticated:
        final user = authState.user;

        if (user != null && user.isAdmin) {
          nextPage = const AdminDashboardPage();
        } else {
          nextPage = const HomePage();
        }
        break;

      case AuthStatus.unauthenticated:
        nextPage = const LoginPage();
        break;

      case AuthStatus.checking:
        nextPage = const LoginPage();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return nextPage;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandLogo(size: 76),
          SizedBox(height: 20),
          Text(
            'LESS PLANNING. MORE LIVING.',
            style: TextStyle(
              color: AppColors.textSecondary,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 40),
          SizedBox(width: 96, child: LinearProgressIndicator(minHeight: 3)),
        ],
      ),
    ),
  );
}
