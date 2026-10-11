import 'package:trav_planner/shared/widgets/brand_logo.dart';
import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import 'admin_banners_page.dart';
import 'package:trav_planner/features/auth/presentation/pages/login_page.dart';
import 'admin_cities_page.dart';
import 'admin_destinations_page.dart';
import 'admin_places_page.dart';
import '../../data/models/admin_dashboard_model.dart';
import '../providers/admin_dashboard_provider.dart';
import 'admin_countries_page.dart';
import 'admin_ai_billing_page.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            if (isMobile) {
              return _MobileAdminDashboard(
                userName: user?.fullName ?? 'Administrator',
                email: user?.email ?? '',
              );
            }

            return _DesktopAdminDashboard(
              userName: user?.fullName ?? 'Administrator',
              email: user?.email ?? '',
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// Desktop Dashboard
// ============================================================

class _DesktopAdminDashboard extends ConsumerStatefulWidget {
  final String userName;
  final String email;

  const _DesktopAdminDashboard({required this.userName, required this.email});

  @override
  ConsumerState<_DesktopAdminDashboard> createState() =>
      _DesktopAdminDashboardState();
}

class _DesktopAdminDashboardState
    extends ConsumerState<_DesktopAdminDashboard> {
  int selectedIndex = 0;

  final List<_AdminMenuItem> menuItems = const [
    _AdminMenuItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _AdminMenuItem(icon: Icons.campaign_rounded, label: 'Banners'),
    _AdminMenuItem(icon: Icons.place_rounded, label: 'Destinations'),
    _AdminMenuItem(icon: Icons.location_on_outlined, label: 'Places'),
    _AdminMenuItem(icon: Icons.public_rounded, label: 'Countries'),
    _AdminMenuItem(icon: Icons.map_rounded, label: 'States'),
    _AdminMenuItem(icon: Icons.location_city_rounded, label: 'Cities'),
    _AdminMenuItem(icon: Icons.category_rounded, label: 'Categories'),
    _AdminMenuItem(icon: Icons.route_rounded, label: 'Planners'),
    _AdminMenuItem(icon: Icons.people_alt_rounded, label: 'Users'),
    _AdminMenuItem(icon: Icons.auto_awesome_rounded, label: 'AI Platform'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSidebar(),

        Expanded(
          child: Column(
            children: [
              _buildTopBar(),

              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // Sidebar
  // ==========================================================

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Column(
        children: [
          const SizedBox(height: 28),

          // --------------------------------------------------
          // Logo
          // --------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [const BrandLogo(size: 36)]),
          ),

          const SizedBox(height: 32),

          // --------------------------------------------------
          // Admin label
          // --------------------------------------------------
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ADMIN CONSOLE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------
          // Menu
          // --------------------------------------------------
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];

                final selected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: selected
                                ? AppColors.onPrimary
                                : AppColors.textSecondary,
                          ),

                          const SizedBox(width: 12),

                          Text(
                            item.label,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.onPrimary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --------------------------------------------------
          // Bottom
          // --------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(color: AppColors.textSecondary),

                const SizedBox(height: 8),

                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.textSecondary,
                    ),
                    title: const Text(
                      'Settings',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    onTap: () {},
                  ),
                ),

                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: _logout,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Top Bar
  // ==========================================================

  Widget _buildTopBar() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Admin Dashboard',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(width: 8),

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 10),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const Text(
                'Administrator',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Main Content
  // ==========================================================

  Widget _buildContent() {
    // ========================================================
    // Dashboard
    // ========================================================

    if (selectedIndex == 0) {
      final dashboardAsync = ref.watch(adminDashboardProvider);

      return dashboardAsync.when(
        loading: _buildDashboardLoading,

        error: (error, stackTrace) {
          return _buildDashboardError(error.toString());
        },

        data: (dashboard) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(),

                const SizedBox(height: 28),

                _buildStats(dashboard),

                const SizedBox(height: 32),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildRecentActivity(dashboard)),

                    const SizedBox(width: 24),

                    Expanded(flex: 2, child: _buildQuickActions()),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    // ========================================================
    // Banners
    // ========================================================

    if (selectedIndex == 1) {
      return const AdminBannersPage();
    }

    // ========================================================
    // Destinations
    // ========================================================

    if (selectedIndex == 2) {
      return const AdminDestinationsPage();
    }

    // ========================================================
    // Places
    // ========================================================

    if (selectedIndex == 3) {
      return const AdminPlacesPage();
    }

    // ========================================================
    // Countries
    // ========================================================

    if (selectedIndex == 4) {
      return const AdminCountriesPage();
    }
    // ========================================================
    // Cities
    // ========================================================

    if (selectedIndex == 6) {
      return const AdminCitiesPage();
    }
    // ========================================================
    // AI Platform
    // ========================================================

    if (selectedIndex == 10) {
      return const AdminAIBillingPage();
    }
    // ========================================================
    // Other Admin Modules
    // ========================================================

    return _ComingSoonPage(
      title: menuItems[selectedIndex].label,
      icon: menuItems[selectedIndex].icon,
    );
  }

  // ==========================================================
  // Dashboard Loading
  // ==========================================================

  Widget _buildDashboardLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  // ==========================================================
  // Dashboard Error
  // ==========================================================

  Widget _buildDashboardError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.error,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(adminDashboardProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Welcome Header
  // ==========================================================

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning 👋',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Here is what is happening across Trav Planner today.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: AppColors.textPrimary,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // REAL Dashboard Stats
  // ==========================================================

  Widget _buildStats(AdminDashboardModel dashboard) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1100
            ? 4
            : width >= 700
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          children: [
            _DashboardStatCard(
              title: 'Total Users',
              value: dashboard.users.total.toString(),
              change: '${dashboard.users.active} active',
              icon: Icons.people_alt_rounded,
            ),

            _DashboardStatCard(
              title: 'Active Banners',
              value: dashboard.content.banners.active.toString(),
              change: '${dashboard.content.banners.total} total',
              icon: Icons.campaign_rounded,
            ),

            _DashboardStatCard(
              title: 'Destinations',
              value: dashboard.content.destinations.total.toString(),
              change: '${dashboard.content.destinations.featured} featured',
              icon: Icons.place_rounded,
            ),

            _DashboardStatCard(
              title: 'Trip Plans',
              value: dashboard.trips.total.toString(),
              change: '${dashboard.trips.planned} planned',
              icon: Icons.route_rounded,
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // Recent Trip Plans
  // ==========================================================

  Widget _buildRecentActivity(AdminDashboardModel dashboard) {
    final plans = dashboard.recentPlans;

    return _DashboardPanel(
      title: 'Recent Trip Plans',
      action: TextButton(
        onPressed: () {
          setState(() {
            selectedIndex = 8;
          });
        },
        child: const Text('View all'),
      ),
      child: plans.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent trip plans yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: plans
                  .map(
                    (plan) => _ActivityItem(
                      icon: Icons.route_rounded,
                      title: plan.title.isEmpty ? 'Trip Plan' : plan.title,
                      subtitle: '${plan.startDate} → ${plan.endDate}',
                      time: plan.status,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  // ==========================================================
  // Quick Actions
  // ==========================================================

  Widget _buildQuickActions() {
    return _DashboardPanel(
      title: 'Quick Actions',
      child: Column(
        children: [
          _QuickActionButton(
            icon: Icons.add_photo_alternate_outlined,
            title: 'Create Banner',
            subtitle: 'Add a promotional banner',
            onTap: () {
              setState(() {
                selectedIndex = 1;
              });
            },
          ),

          const SizedBox(height: 12),

          _QuickActionButton(
            icon: Icons.add_location_alt_outlined,
            title: 'Add Destination',
            subtitle: 'Create a destination',
            onTap: () {
              setState(() {
                selectedIndex = 2;
              });
            },
          ),

          const SizedBox(height: 12),

          _QuickActionButton(
            icon: Icons.people_outline_rounded,
            title: 'Manage Users',
            subtitle: 'View registered users',
            onTap: () {
              setState(() {
                selectedIndex = 9;
              });
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Logout
  // ==========================================================

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

class _MobileAdminDashboard extends ConsumerWidget {
  final String userName;
  final String email;

  const _MobileAdminDashboard({required this.userName, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),

        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      drawer: _MobileDrawer(userName: userName, email: email),

      body: dashboardAsync.when(
        // ======================================================
        // Loading
        // ======================================================
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },

        // ======================================================
        // Error
        // ======================================================
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Unable to load dashboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(adminDashboardProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },

        // ======================================================
        // Success
        // ======================================================
        data: (dashboard) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminDashboardProvider);
              await ref.read(adminDashboardProvider.future);
            },

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ------------------------------------------------
                  // Greeting
                  // ------------------------------------------------
                  Text(
                    'Good morning 👋',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // Welcome Card
                  // ------------------------------------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),

                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                    ),

                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Icon(
                          Icons.flight_takeoff_rounded,
                          color: AppColors.textPrimary,
                          size: 42,
                        ),

                        SizedBox(height: 20),

                        Text(
                          'Trav Planner Admin',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          'Manage your travel platform from one place.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // Total Users
                  // ------------------------------------------------
                  _MobileStatCard(
                    title: 'Total Users',
                    value: dashboard.users.total.toString(),
                    icon: Icons.people_alt_rounded,
                  ),

                  const SizedBox(height: 12),

                  // ------------------------------------------------
                  // Active Banners
                  // ------------------------------------------------
                  _MobileStatCard(
                    title: 'Active Banners',
                    value: dashboard.content.banners.active.toString(),
                    icon: Icons.campaign_rounded,
                  ),

                  const SizedBox(height: 12),

                  // ------------------------------------------------
                  // Destinations
                  // ------------------------------------------------
                  _MobileStatCard(
                    title: 'Destinations',
                    value: dashboard.content.destinations.total.toString(),
                    icon: Icons.place_rounded,
                  ),

                  const SizedBox(height: 12),

                  // ------------------------------------------------
                  // Trip Plans
                  // ------------------------------------------------
                  _MobileStatCard(
                    title: 'Trip Plans',
                    value: dashboard.trips.total.toString(),
                    icon: Icons.route_rounded,
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // Additional Content Summary
                  // ------------------------------------------------
                  const Text(
                    'Content Overview',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _MobileStatCard(
                    title: 'Cities',
                    value: dashboard.content.cities.total.toString(),
                    icon: Icons.location_city_rounded,
                  ),

                  const SizedBox(height: 12),

                  _MobileStatCard(
                    title: 'Places',
                    value: dashboard.content.places.total.toString(),
                    icon: Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 12),

                  _MobileStatCard(
                    title: 'Featured Destinations',
                    value: dashboard.content.destinations.featured.toString(),
                    icon: Icons.star_rounded,
                  ),

                  const SizedBox(height: 12),

                  _MobileStatCard(
                    title: 'Featured Places',
                    value: dashboard.content.places.featured.toString(),
                    icon: Icons.star_border_rounded,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// Mobile Drawer
// ============================================================

class _MobileDrawer extends ConsumerWidget {
  final String userName;
  final String email;

  const _MobileDrawer({required this.userName, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.surface),
            accountName: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            accountEmail: Text(email),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.campaign_rounded),
            title: const Text('Banners'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.place_rounded),
            title: const Text('Destinations'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Places'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.people_alt_rounded),
            title: const Text('Users'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.auto_awesome_rounded),
            title: const Text('AI Platform'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const Spacer(),

          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ============================================================
// Dashboard Stat Card
// ============================================================

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                Text(
                  '$change this month',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Mobile Stat Card
// ============================================================

class _MobileStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MobileStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),

          const SizedBox(width: 14),

          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Dashboard Panel
// ============================================================

class _DashboardPanel extends StatelessWidget {
  final String title;
  final Widget? action;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              ?action,
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// Activity Item
// ============================================================

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Text(
            time,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Quick Action
// ============================================================

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Coming Soon
// ============================================================

class _ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoonPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 40, color: AppColors.primary),
          ),

          const SizedBox(height: 20),

          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'This module will be connected to the Trav Planner API next.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Menu Model
// ============================================================

class _AdminMenuItem {
  final IconData icon;
  final String label;

  const _AdminMenuItem({required this.icon, required this.label});
}
