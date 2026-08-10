import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    _timer = Timer(
      const Duration(milliseconds: 2500),
      _openNextPage,
    );
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
        nextPage = const HomePage();
        break;

      case AuthStatus.unauthenticated:
        nextPage = const LoginPage();
        break;

      case AuthStatus.checking:
        // This should normally not happen because
        // checkSession() completes before navigation.
        nextPage = const LoginPage();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return nextPage;
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(
          milliseconds: 500,
        ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          Positioned(
            top: -180,
            left: -120,
            child: _GlowCircle(
              size: 420,
              color: const Color(0xFF2196F3),
            ),
          ),

          Positioned(
            bottom: -220,
            right: -140,
            child: _GlowCircle(
              size: 480,
              color: const Color(0xFF0D8BFF),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/branding/'
                  'travplanner_symbol_1024.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(
                      duration: 700.ms,
                    )
                    .scale(
                      begin: const Offset(
                        0.72,
                        0.72,
                      ),
                      end: const Offset(
                        1,
                        1,
                      ),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 26),

                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Trav',
                        style: TextStyle(
                          color: Color(0xFF123B72),
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Planner',
                        style: TextStyle(
                          color: Color(0xFF146EF5),
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: 350.ms,
                      duration: 600.ms,
                    )
                    .slideY(
                      begin: 0.25,
                      end: 0,
                      delay: 350.ms,
                      duration: 600.ms,
                    ),

                const SizedBox(height: 18),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF1677F2),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF1677F2),
                      size: 27,
                    ),

                    const SizedBox(width: 12),

                    Container(
                      width: 70,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1677F2),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(
                      delay: 700.ms,
                      duration: 500.ms,
                    ),

                const SizedBox(height: 16),

                const Text(
                  'PLAN LESS. TRAVEL MORE.',
                  style: TextStyle(
                    color: Color(0xFF234B7D),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: 850.ms,
                      duration: 500.ms,
                    ),

                const SizedBox(height: 42),

                SizedBox(
                  width: 100,
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child:
                        const LinearProgressIndicator(
                      minHeight: 5,
                      backgroundColor:
                          Color(0xFFE0E9F7),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        Color(0xFF1684F5),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: 1100.ms,
                      duration: 400.ms,
                    ),

                const SizedBox(height: 18),

                const Text(
                  'EXPLORING POSSIBILITIES...',
                  style: TextStyle(
                    color: Color(0xFF6683A8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: 1200.ms,
                      duration: 500.ms,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}