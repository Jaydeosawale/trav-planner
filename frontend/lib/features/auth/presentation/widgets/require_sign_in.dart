import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/login_page.dart';
import '../providers/auth_provider.dart';

Future<bool> ensureSignedIn(BuildContext context, [WidgetRef? ref]) async {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(authProvider).isAuthenticated) return true;
  final signedIn = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginPage(returnToCaller: true)),
  );
  return signedIn == true && container.read(authProvider).isAuthenticated;
}
