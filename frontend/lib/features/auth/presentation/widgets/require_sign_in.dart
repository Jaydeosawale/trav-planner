import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/login_page.dart';
import '../providers/auth_provider.dart';

Future<bool> ensureSignedIn(BuildContext context, [WidgetRef? ref]) async {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(authProvider).isAuthenticated) return true;
  final signedIn = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginPage(returnToCaller: true)),
  );
  return signedIn == true && container.read(authProvider).isAuthenticated;
}

void returnToSignIn(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.go('/login');
  } else {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
