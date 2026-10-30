import 'package:trav_planner/features/auth/presentation/widgets/require_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trav_planner/features/auth/data/models/user_model.dart';
import 'package:trav_planner/features/auth/presentation/pages/login_page.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';

class SuccessfulLogin extends AuthNotifier {
  SuccessfulLogin(this.role);
  final String role;
  @override
  AuthState build() => const AuthState.unauthenticated();
  @override
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    state = AuthState.authenticated(
      user: UserModel(
        id: 'test',
        email: email,
        fullName: 'Test User',
        isActive: true,
        createdAt: DateTime(2026),
        role: role,
      ),
    );
    return true;
  }
}

void main() {
  testWidgets('authentication and registration cover the tab navigation', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => Scaffold(
            body: shell,
            bottomNavigationBar: const Text('Main tabs'),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, _) => Scaffold(
                    body: Center(
                      child: FilledButton(
                        onPressed: () => ensureSignedIn(context),
                        child: const Text('Open account'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => SuccessfulLogin('user'))],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    expect(find.text('Main tabs'), findsOneWidget);
    await tester.tap(find.text('Open account'));
    await tester.pumpAndSettle();
    expect(find.text('Main tabs'), findsNothing);
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Main tabs'), findsNothing);
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Main tabs'), findsNothing);
    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final role in ['user', 'admin']) {
    for (final routed in [false, true]) {
      testWidgets('successful $role login leaves login (routed: $routed)', (
        tester,
      ) async {
        final router = GoRouter(
          initialLocation: routed ? '/login' : '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, _) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginPage(),
                      ),
                    ),
                    child: const Text('Open login'),
                  ),
                ),
              ),
            ),
            GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
            GoRoute(
              path: '/admin',
              builder: (_, _) =>
                  const Scaffold(body: Text('Admin destination')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authProvider.overrideWith(() => SuccessfulLogin(role))],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        if (!routed) await tester.tap(find.text('Open login'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).at(0),
          'test@example.com',
        );
        await tester.enterText(
          find.byType(TextField).at(1),
          'TestPassword123!',
        );
        await tester.ensureVisible(find.text('Login'));
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsNothing);
        expect(
          router.routeInformationProvider.value.uri.path,
          role == 'admin' ? '/admin' : '/home',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
