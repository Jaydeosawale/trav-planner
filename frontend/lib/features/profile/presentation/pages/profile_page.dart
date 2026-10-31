import '../../../places/data/location_memory.dart';
import '../../../places/data/place_area.dart';
import '../../../places/data/nearby_origin.dart';
import '../../../explore/presentation/pages/nearby_places_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/widgets/require_sign_in.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../saved/presentation/pages/saved_page.dart';
import 'travel_preferences_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final user = authState.user;
    final area = ref.watch(chosenPlaceAreaProvider);
    final gps = ref.watch(nearbyOriginProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        AppColors.surfaceVariant,
                        AppColors.surfaceVariant,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.surface,
                        child: Text(
                          _initials(user?.fullName ?? 'Guest traveler'),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Guest traveler',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              user?.email ?? 'Sign in to save your plans',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                _ProfileMenuItem(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Saved places',
                  subtitle: 'Keep inspiration for your next trip',
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const SavedPage())),
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
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                _ProfileMenuItem(
                  icon: Icons.travel_explore_rounded,
                  title: 'Travel Preferences',
                  subtitle: 'Customize your travel experience',
                  onTap: () async {
                    if (!await ensureSignedIn(context, ref) ||
                        !context.mounted) {
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TravelPreferencesPage(),
                      ),
                    );
                  },
                ),

                if (user != null && (area != null || gps != null))
                  _ProfileMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Saved area',
                    subtitle: area?.name ?? 'Saved GPS area',
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (sheetContext) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              area?.name ?? 'Saved GPS area',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NearbyPlacesPage(),
                                  ),
                                );
                              },
                              child: const Text('Explore or change area'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(forgetSavedAreaProvider.notifier)
                                    .state++;
                                Navigator.pop(sheetContext);
                              },
                              child: const Text('Forget saved area'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                _ProfileMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy policy',
                  subtitle: 'How Trav handles your data',
                  onTap: () => _openPolicy(context, 'privacy'),
                ),
                _ProfileMenuItem(
                  icon: Icons.person_remove_outlined,
                  title: 'Delete account and data',
                  subtitle: 'Request permanent removal of your account',
                  onTap: () => _openPolicy(context, 'delete-account'),
                ),

                const SizedBox(height: 30),

                // ========================================================
                // Logout
                // ========================================================
                SizedBox(
                  width: double.infinity,
                  child: user == null
                      ? FilledButton(
                          onPressed: () => ensureSignedIn(context, ref),
                          child: const Text('Sign in'),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => _logout(context, ref),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Logout',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.errorContainer),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // Initials
  // ==========================================================

  static Future<void> _openPolicy(BuildContext context, String page) async {
    final url = Uri.parse(
      'https://jaydeo-sawale-portfolio.vercel.app/trav/$page/',
    );
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* Show a copyable address when no browser is available. */
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open in your browser'),
        content: SelectableText(url.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'TP';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ==========================================================
  // Logout
  // ==========================================================

  static Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    // ----------------------------------------------------------
    // Clear authentication state and tokens.
    // ----------------------------------------------------------

    await ref.read(authProvider.notifier).logout();

    if (!context.mounted) {
      return;
    }

    // ----------------------------------------------------------
    // Remove the authenticated navigation stack
    // and return to Login.
    //
    // ----------------------------------------------------------

    returnToSignIn(context);
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 5,
          ),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
