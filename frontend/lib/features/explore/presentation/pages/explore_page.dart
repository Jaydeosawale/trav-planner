import '../../../destinations/presentation/destination_details_page.dart';
import '../../../destinations/data/place.dart';
import '../../../../shared/widgets/travel_inspiration_grid.dart';
import 'package:trav_planner/core/theme/app_colors.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/explore_country.dart';
import '../../data/models/explore_state.dart';
import '../../data/models/explore_city.dart';
import '../providers/explore_provider.dart';
import 'country_details_page.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key, this.initialQuery = ''});
  final String initialQuery;

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  String _searchQuery = '';

  ExploreCountry? _selectedCountry;
  ExploreState? _selectedState;

  int _section = 0;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery.trim();
    _searchController.text = _searchQuery;
    if (_searchQuery.isNotEmpty) _section = 2;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;

      setState(() {
        _searchQuery = query;
        _section = 2;
      });
    });
  }

  void _selectCountry(ExploreCountry country) {
    setState(() {
      _selectedCountry = country;
      _selectedState = null;
      _section = 1;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _clearCountry() {
    setState(() {
      _selectedCountry = null;
      _selectedState = null;
      _section = 0;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(exploreCountriesProvider);

    final isWideScreen = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: !isWideScreen,
        bottom: false,
        child: countries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError(error.toString()),
          data: (items) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: isWide ? 48 : 16,
                    right: isWide ? 48 : 16,
                    top: isWide ? 24 : 14,
                    bottom: isWide ? 24 : 104,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, items.length),

                          SizedBox(height: isWide ? 24 : 16),

                          _buildSearch(),

                          SizedBox(height: isWide ? 24 : 14),

                          if (_section == 0 && _searchQuery.isEmpty) ...[
                            TravelInspirationGrid(
                              onSelect: (query) {
                                setState(() {
                                  _searchController.text = query;
                                  _searchQuery = query;
                                  _section = 2;
                                });
                              },
                            ),
                            const SizedBox(height: 28),
                          ],
                          _buildSectionSelector(),

                          SizedBox(height: isWide ? 24 : 18),

                          if (_section == 0)
                            _buildCountriesSection(items, isWide),

                          if (_section == 1) _buildStatesSection(isWide),

                          if (_section == 2) _buildCitiesSection(isWide),
                          const SizedBox(height: 24),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Geography by ',
                                style: TextStyle(fontSize: 12),
                              ),
                              TextButton(
                                onPressed: () => launchUrl(
                                  Uri.parse('https://www.geonames.org/'),
                                ),
                                child: const Text(
                                  'GeoNames',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              TextButton(
                                onPressed: () => launchUrl(
                                  Uri.parse(
                                    'https://creativecommons.org/licenses/by/4.0/',
                                  ),
                                ),
                                child: const Text(
                                  'CC BY 4.0 · adapted for Trav',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // Header
  // ==========================================================

  Widget _buildHeader(BuildContext context, int countryCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover the world',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Explore countries, regions and cities before you plan your trip.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$countryCount ${countryCount == 1 ? 'country' : 'countries'} available',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // Search
  // ==========================================================

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search countries or cities...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                      _section = 0;
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // Section Selector
  // ==========================================================

  Widget _buildSectionSelector() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          children: [
            _sectionChip(
              label: 'Countries',
              icon: Icons.public_rounded,
              index: 0,
            ),
            const SizedBox(width: 8),
            _sectionChip(
              label: 'States & Provinces',
              icon: Icons.map_rounded,
              index: 1,
            ),
            const SizedBox(width: 8),
            _sectionChip(
              label: 'Cities',
              icon: Icons.location_city_rounded,
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionChip({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final selected = _section == index;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        setState(() {
          _section = index;
        });
      },
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? AppColors.onPrimary : AppColors.primary,
      ),
      label: Text(label),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: selected ? AppColors.onPrimary : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    );
  }

  // ==========================================================
  // Countries
  // ==========================================================

  Widget _buildCountriesSection(List<ExploreCountry> countries, bool isWide) {
    final query = _searchQuery.toLowerCase();

    final filtered = query.isEmpty
        ? countries
        : countries
              .where(
                (country) =>
                    country.name.toLowerCase().contains(query) ||
                    country.iso2.toLowerCase().contains(query) ||
                    (country.continent?.toLowerCase().contains(query) ?? false),
              )
              .toList();

    if (filtered.isEmpty) {
      return _buildEmpty(
        icon: Icons.public_off_rounded,
        title: 'No countries found',
        subtitle: 'Try another country name or ISO code.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Countries',
          'Browse countries and continue into their regions.',
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isWide ? 2.8 : 4.15,
          ),
          itemBuilder: (context, index) {
            final country = filtered[index];

            return _CountryCard(
              country: country,
              onTap: () => _openCountryDetails(country),
            );
          },
        ),
      ],
    );
  }

  // ==========================================================
  // States
  // ==========================================================

  Widget _buildStatesSection(bool isWide) {
    if (_selectedCountry == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'States & Provinces',
            'Select a country first to explore its regions.',
          ),
          const SizedBox(height: 18),
          _buildCountryPicker(),
        ],
      );
    }

    final states = ref.watch(exploreStatesProvider(_selectedCountry!.id));

    return states.when(
      loading: () => _buildLoading('Loading regions...'),
      error: (error, _) => _buildError(error.toString()),
      data: (items) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectedCountryHeader(),

            const SizedBox(height: 20),

            _sectionTitle(
              'States & Provinces',
              '${items.length} regions in ${_selectedCountry!.name}',
            ),

            const SizedBox(height: 16),

            if (items.isEmpty)
              _buildEmpty(
                icon: Icons.map_outlined,
                title: 'No regions found',
                subtitle: 'This country does not have region data yet.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 3.2 : 4,
                ),
                itemBuilder: (context, index) {
                  return _StateCard(
                    state: items[index],
                    onTap: () {
                      setState(() {
                        _selectedState = items[index];
                        _section = 2;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildCountryPicker() {
    final countries = ref.watch(exploreCountriesProvider);

    return countries.when(
      loading: () => _buildLoading('Loading countries...'),
      error: (error, _) => _buildError(error.toString()),
      data: (items) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((country) {
            return ActionChip(
              onPressed: () => _selectCountry(country),
              avatar: Text(
                country.iso2,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              label: Text(country.name),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSelectedCountryHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _clearCountry,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _selectedCountry!.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _clearCountry,
          icon: const Icon(Icons.public_rounded, size: 17),
          label: const Text('Countries'),
        ),
      ],
    );
  }

  Widget _buildSelectedStateHeader() {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    void backToStates() {
      setState(() {
        _selectedState = null;
        _section = 1;
        _searchController.clear();
        _searchQuery = '';
      });
    }

    return Row(
      children: [
        IconButton(
          onPressed: backToStates,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to states',
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _selectedState!.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isWide)
          OutlinedButton.icon(
            onPressed: backToStates,
            icon: const Icon(Icons.map_rounded, size: 17),
            label: const Text('States'),
          )
        else
          IconButton(
            onPressed: backToStates,
            icon: const Icon(Icons.map_rounded),
            tooltip: 'Back to states',
          ),
      ],
    );
  }

  Widget _buildCitiesSection(bool isWide) {
    final query = _searchQuery.trim();

    final request = ExploreCitySearchRequest(
      search: query.isEmpty ? null : query,
      countryId: _selectedCountry?.id,
      stateId: _selectedState?.id,
      size: 20,
    );

    final cities = ref.watch(exploreCitiesProvider(request));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedCountry != null) _buildSelectedCountryHeader(),

        if (_selectedState != null) ...[
          const SizedBox(height: 8),
          _buildSelectedStateHeader(),
        ],

        const SizedBox(height: 8),

        _sectionTitle(
          'Cities',
          query.isEmpty
              ? 'Discover cities from around the world.'
              : 'Search results for "$query"',
        ),

        const SizedBox(height: 16),

        cities.when(
          loading: () => _buildLoading('Finding cities...'),
          error: (error, _) => _buildError(error.toString()),
          data: (result) {
            if (result.items.isEmpty) {
              return _buildEmpty(
                icon: Icons.location_city_outlined,
                title: 'No cities found',
                subtitle: 'Try a different city name.',
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: result.items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isWide ? 3.1 : 4,
              ),
              itemBuilder: (context, index) {
                final city = result.items[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DestinationDetailsPage(
                        cityId: city.id,
                        name: city.name,
                        center: validCoordinates(city.latitude, city.longitude),
                      ),
                    ),
                  ),
                  child: _CityCard(city: city),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ==========================================================
  // Shared UI
  // ==========================================================

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildLoading(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load Explore',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(exploreCountriesProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 46, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .04),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  void _openCountryDetails(ExploreCountry country) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CountryDetailsPage(country: country)),
    );
  }
}

// ============================================================
// Country Card
// ============================================================

class _CountryCard extends StatelessWidget {
  final ExploreCountry country;
  final VoidCallback onTap;

  const _CountryCard({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width >= 900 ? 16 : 12,
          ),
          child: Row(
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width >= 900 ? 52 : 46,
                height: MediaQuery.sizeOf(context).width >= 900 ? 52 : 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: country.flagUrl != null && country.flagUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          country.flagUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.public_rounded,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.public_rounded,
                        color: AppColors.primary,
                      ),
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width >= 900 ? 14 : 11,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      country.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        country.iso2,
                        if (country.continent != null &&
                            country.continent!.isNotEmpty)
                          country.continent!,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// State Card
// ============================================================

class _StateCard extends StatelessWidget {
  final ExploreState state;
  final VoidCallback onTap;

  const _StateCard({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.map_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (state.code.isNotEmpty)
                      Text(
                        state.code,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// City Card
// ============================================================

class _CityCard extends StatelessWidget {
  final ExploreCity city;

  const _CityCard({required this.city});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
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
            child: const Icon(
              Icons.location_city_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  city.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                if (city.latitude != null && city.longitude != null)
                  Text(
                    '${city.latitude!.toStringAsFixed(2)}, ${city.longitude!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  )
                else
                  Text(
                    'Explore city',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
