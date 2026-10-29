import 'package:trav_planner/core/theme/app_colors.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:trav_planner/shared/widgets/brand_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../admin/presentation/pages/admin_dashboard_page.dart';
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

    _timer = Timer(const Duration(milliseconds: 300), _openNextPage);
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
        nextPage = const HomePage();
        break;

      case AuthStatus.unavailable:
      case AuthStatus.checking:
        return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(authState.isAdmin ? '/admin' : '/home');
      return;
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
  Widget build(BuildContext context) {
    if (ref.watch(authProvider).status == AuthStatus.unavailable) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 56),
                  const SizedBox(height: 24),
                  const Text(
                    'Trav couldn’t connect just now.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your session has been kept. Try again, or explore public places while the connection recovers.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _openNextPage,
                    child: const Text('Retry connection'),
                  ),
                  TextButton(
                    onPressed: () {
                      final router = GoRouter.maybeOf(context);
                      if (router != null) {
                        router.go('/home');
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      }
                    },
                    child: const Text('Continue exploring'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const Scaffold(
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
}
