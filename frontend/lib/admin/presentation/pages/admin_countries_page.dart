import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../data/datasources/admin_country_api.dart';
import '../../data/models/admin_country_model.dart';

class AdminCountriesPage extends StatefulWidget {
  const AdminCountriesPage({super.key});

  @override
  State<AdminCountriesPage> createState() => _AdminCountriesPageState();
}

class _AdminCountriesPageState extends State<AdminCountriesPage> {
  final AdminCountryApi _api = AdminCountryApi();

  final TextEditingController _searchController = TextEditingController();

  List<AdminCountryModel> _countries = [];

  bool _loading = true;
  String? _error;

  String _filter = 'all';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    _loadCountries();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    super.dispose();
  }

  // ==========================================================
  // Load
  // ==========================================================

  Future<void> _loadCountries() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final countries = await _api.getAllCountries();

      if (!mounted) return;

      setState(() {
        _countries = countries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ==========================================================
  // Search
  // ==========================================================

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ==========================================================
  // Filter
  // ==========================================================

  List<AdminCountryModel> get _filteredCountries {
    final query = _searchController.text.trim().toLowerCase();

    return _countries.where((country) {
      final matchesStatus = switch (_filter) {
        'active' => country.isActive,
        'inactive' => !country.isActive,
        _ => true,
      };

      if (!matchesStatus) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return country.name.toLowerCase().contains(query) ||
          country.iso2.toLowerCase().contains(query) ||
          (country.iso3?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // ==========================================================
  // Status update
  // ==========================================================

  Future<void> _toggleCountry(AdminCountryModel country) async {
    final newStatus = !country.isActive;

    final action = newStatus ? 'enable' : 'disable';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${newStatus ? 'Enable' : 'Disable'} Country?'),
          content: Text(
            newStatus
                ? '${country.name} will become available to users again.'
                : '${country.name} will no longer be available in active country selections.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(newStatus ? 'Enable' : 'Disable'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final updated = await _api.updateCountryStatus(
        countryId: country.id,
        isActive: newStatus,
      );

      if (!mounted) return;

      setState(() {
        final index = _countries.indexWhere((item) => item.id == updated.id);

        if (index != -1) {
          _countries[index] = updated;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${country.name} ${newStatus ? 'enabled' : 'disabled'} successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to $action country: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final countries = _filteredCountries;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 24),

          _buildToolbar(),

          const SizedBox(height: 20),

          Expanded(child: _buildBody(countries)),
        ],
      ),
    );
  }

  // ==========================================================
  // Header
  // ==========================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Countries',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage countries available across Trav Planner.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _loadCountries,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  // ==========================================================
  // Toolbar
  // ==========================================================

  Widget _buildToolbar() {
    final total = _countries.length;

    final active = _countries.where((country) => country.isActive).length;

    final inactive = total - active;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search country or ISO code...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        DropdownButtonFormField<String>(
          initialValue: _filter,
          decoration: InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            DropdownMenuItem(value: 'all', child: Text('All ($total)')),
            DropdownMenuItem(value: 'active', child: Text('Active ($active)')),
            DropdownMenuItem(
              value: 'inactive',
              child: Text('Inactive ($inactive)'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _filter = value;
            });
          },
        ),
      ],
    );
  }

  // ==========================================================
  // Body
  // ==========================================================

  Widget _buildBody(List<AdminCountryModel> countries) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (countries.isEmpty) {
      return _buildEmpty();
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeader(),

          const Divider(height: 1),

          Expanded(
            child: ListView.separated(
              itemCount: countries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _CountryRow(
                  country: countries[index],
                  onToggle: () => _toggleCountry(countries[index]),
                  onTap: () => _showDetails(countries[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Table header
  // ==========================================================

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppColors.surface,
      child: const Row(
        children: [
          SizedBox(width: 55, child: Text('')),
          Expanded(
            flex: 3,
            child: Text(
              'Country',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text('ISO', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Continent',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'Action',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Details
  // ==========================================================

  Future<void> _showDetails(AdminCountryModel country) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              _CountryFlag(country: country, size: 42),
              const SizedBox(width: 12),
              Expanded(child: Text(country.name)),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail('ISO2', country.iso2),
                  _detail('ISO3', country.iso3),
                  _detail('Capital', country.capital),
                  _detail('Currency', country.currency),
                  _detail('Phone Code', country.phoneCode),
                  _detail('Continent', country.continent),
                  _detail('Timezone', country.timezone),
                  _detail('Latitude', country.latitude?.toString()),
                  _detail('Longitude', country.longitude?.toString()),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Availability: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      _StatusChip(isActive: country.isActive),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _toggleCountry(country);
              },
              child: Text(country.isActive ? 'Disable' : 'Enable'),
            ),
          ],
        );
      },
    );
  }

  Widget _detail(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Error
  // ==========================================================

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Unable to load countries.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(_error ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadCountries,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Empty
  // ==========================================================

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public_off_rounded,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No countries found.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Country Row
// ============================================================

class _CountryRow extends StatelessWidget {
  final AdminCountryModel country;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _CountryRow({
    required this.country,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 55,
              child: _CountryFlag(country: country, size: 34),
            ),

            Expanded(
              flex: 3,
              child: Text(
                country.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),

            SizedBox(width: 80, child: Text(country.iso2)),

            Expanded(flex: 2, child: Text(country.continent ?? '—')),

            SizedBox(
              width: 110,
              child: _StatusChip(isActive: country.isActive),
            ),

            SizedBox(
              width: 80,
              child: IconButton(
                tooltip: country.isActive
                    ? 'Disable country'
                    : 'Enable country',
                onPressed: onToggle,
                icon: Icon(
                  country.isActive
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_rounded,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Flag
// ============================================================

class _CountryFlag extends StatelessWidget {
  final AdminCountryModel country;
  final double size;

  const _CountryFlag({required this.country, required this.size});

  @override
  Widget build(BuildContext context) {
    if (country.flagUrl != null && country.flagUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          country.flagUrl!,
          width: size,
          height: size * .7,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _fallback();
          },
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size * .7,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.border,
      ),
      child: Text(
        country.iso2,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ============================================================
// Status
// ============================================================

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive ? AppColors.successContainer : AppColors.errorContainer,
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}
