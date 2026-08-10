import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final authState = ref.watch(authProvider);

    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          40,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ========================================================
            // Profile Header
            // ========================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1684F5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Text(
                      _initials(
                        user?.fullName ??
                            'Trav Planner',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(width: 18),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ??
                              'Trav Planner',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ========================================================
            // Account
            // ========================================================

            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF123B72),
              ),
            ),

            const SizedBox(height: 12),

            _ProfileMenuItem(
              icon:
                  Icons.person_outline_rounded,
              title: 'Edit Profile',
              subtitle:
                  'Update your personal information',
              onTap: () {},
            ),

            _ProfileMenuItem(
              icon:
                  Icons.settings_outlined,
              title: 'Settings',
              subtitle:
                  'Manage app preferences',
              onTap: () {},
            ),

            _ProfileMenuItem(
              icon:
                  Icons.lock_outline_rounded,
              title: 'Security',
              subtitle:
                  'Password and account security',
              onTap: () {},
            ),

            const SizedBox(height: 26),

            // ========================================================
            // Travel
            // ========================================================

            const Text(
              'Travel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF123B72),
              ),
            ),

            const SizedBox(height: 12),

            _ProfileMenuItem(
              icon:
                  Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle:
                  'Manage travel and trip notifications',
              onTap: () {},
            ),

            _ProfileMenuItem(
              icon:
                  Icons.travel_explore_rounded,
              title: 'Travel Preferences',
              subtitle:
                  'Customize your travel experience',
              onTap: () {},
            ),

            const SizedBox(height: 30),

            // ========================================================
            // Logout
            // ========================================================

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(
                  context,
                  ref,
                ),
                icon: const Icon(
                  Icons.logout_rounded,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.red.shade600,
                  side: BorderSide(
                    color: Colors.red.shade200,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Initials
  // ==========================================================

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where(
          (part) => part.isNotEmpty,
        )
        .toList();

    if (parts.isEmpty) {
      return 'TP';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  // ==========================================================
  // Logout
  // ==========================================================

  static Future<void> _logout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true ||
        !context.mounted) {
      return;
    }

    // ----------------------------------------------------------
    // Clear authentication state and tokens.
    // ----------------------------------------------------------

    await ref
        .read(authProvider.notifier)
        .logout();

    if (!context.mounted) {
      return;
    }

    // ----------------------------------------------------------
    // Remove the authenticated navigation stack
    // and return to Login.
    //
    // We currently don't use named routes, so navigate
    // directly to LoginPage.
    // ----------------------------------------------------------

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }
}

// ==========================================================
// Profile Menu Item
// ==========================================================

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 5,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
        onTap: onTap,
      ),
    );
  }
}