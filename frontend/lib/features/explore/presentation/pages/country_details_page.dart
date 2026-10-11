import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../data/models/explore_country.dart';

class CountryDetailsPage extends StatelessWidget {
  final ExploreCountry country;

  const CountryDetailsPage({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, isWide)),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 20,
                  vertical: 20,
                ),
                child: _buildContent(context, isWide),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isWide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 48 : 16, 12, isWide ? 48 : 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: 'Back to countries',
            icon: const Icon(Icons.arrow_back_rounded),
          ),

          const SizedBox(width: 8),

          const Text(
            'Country Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isWide) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCountryHero(isWide),

            const SizedBox(height: 24),

            _buildQuickFacts(isWide),

            const SizedBox(height: 24),

            _buildExploreSection(context, isWide),

            const SizedBox(height: 24),

            _buildVisaSection(context, isWide),

            const SizedBox(height: 24),

            _buildTravelInformationSection(isWide),

            const SizedBox(height: 24),

            _buildAiSection(context, isWide),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryHero(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 32 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFlag(),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  country.name,
                  style: TextStyle(
                    fontSize: isWide ? 34 : 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                if (country.continent != null && country.continent!.isNotEmpty)
                  Text(
                    country.continent!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: country.iso2, icon: Icons.public_rounded),

                    if (country.iso3 != null && country.iso3!.isNotEmpty)
                      _InfoChip(label: country.iso3!, icon: Icons.code_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlag() {
    if (country.flagUrl != null && country.flagUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          country.flagUrl!,
          width: 92,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _flagPlaceholder();
          },
        ),
      );
    }

    return _flagPlaceholder();
  }

  Widget _flagPlaceholder() {
    return Container(
      width: 92,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        country.iso2,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildQuickFacts(bool isWide) {
    final facts = <_CountryFact>[
      _CountryFact(
        icon: Icons.location_city_rounded,
        label: 'Capital',
        value: country.capital,
      ),
      _CountryFact(
        icon: Icons.payments_rounded,
        label: 'Currency',
        value: country.currency,
      ),
      _CountryFact(
        icon: Icons.phone_rounded,
        label: 'Phone Code',
        value: country.phoneCode,
      ),
      _CountryFact(
        icon: Icons.public_rounded,
        label: 'Continent',
        value: country.continent,
      ),
      _CountryFact(
        icon: Icons.schedule_rounded,
        label: 'Timezone',
        value: country.timezone,
      ),
    ];

    final visibleFacts = facts
        .where((fact) => fact.value != null && fact.value!.trim().isNotEmpty)
        .toList();

    return _SectionCard(
      title: 'Quick Facts',
      icon: Icons.info_outline_rounded,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visibleFacts.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 2.5 : 1.8,
        ),
        itemBuilder: (context, index) {
          return _FactCard(fact: visibleFacts[index]);
        },
      ),
    );
  }

  Widget _buildExploreSection(BuildContext context, bool isWide) {
    return _SectionCard(
      title: 'Explore ${country.name}',
      icon: Icons.explore_rounded,
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.map_rounded,
              title: 'States & Provinces',
              subtitle: 'Explore regions and local information.',
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _ActionCard(
              icon: Icons.location_city_rounded,
              title: 'Cities',
              subtitle: 'Discover cities and places to visit.',
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisaSection(BuildContext context, bool isWide) {
    return _SectionCard(
      title: 'Visa & Entry',
      icon: Icons.badge_outlined,
      child: _ActionCard(
        icon: Icons.verified_user_outlined,
        title: 'Check Visa & Entry Requirements',
        subtitle: 'Get current requirements before travelling.',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Visa intelligence will be connected to current official sources.',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTravelInformationSection(bool isWide) {
    return _SectionCard(
      title: 'Travel Information',
      icon: Icons.travel_explore_rounded,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 2.8 : 3.5,
        children: const [
          _SimpleInfoCard(
            icon: Icons.shield_outlined,
            title: 'Safety',
            subtitle: 'Travel safety information',
          ),
          _SimpleInfoCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Health',
            subtitle: 'Health and travel guidance',
          ),
          _SimpleInfoCard(
            icon: Icons.gavel_rounded,
            title: 'Local Rules',
            subtitle: 'Important local regulations',
          ),
        ],
      ),
    );
  }

  Widget _buildAiSection(BuildContext context, bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 28 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.surfaceVariant, AppColors.surfaceVariant],
        ),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Travel Intelligence',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  'Ask anything about travelling to ${country.name}.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AI country search will be connected next.'),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Ask AI'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21, color: AppColors.primary),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  final _CountryFact fact;

  const _FactCard({required this.fact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(fact.icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            fact.label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            fact.value!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SimpleInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryFact {
  final IconData icon;
  final String label;
  final String? value;

  const _CountryFact({
    required this.icon,
    required this.label,
    required this.value,
  });
}
