import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class AuthDebugPage extends ConsumerWidget {
  const AuthDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Status: ${authState.status.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session cleared.'),
                  ),
                );
              },
              child: const Text('Clear Session'),
            ),
          ],
        ),
      ),
    );
  }
}