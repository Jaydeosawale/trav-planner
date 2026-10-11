import 'package:trav_planner/core/theme/app_colors.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/datasources/admin_city_api.dart';
import '../../data/datasources/admin_country_api.dart';
import '../../data/datasources/admin_state_api.dart';
import '../../data/models/admin_city_model.dart';
import '../../data/models/admin_country_model.dart';
import '../../data/models/admin_state_model.dart';

class AdminCitiesPage extends StatefulWidget {
  const AdminCitiesPage({super.key});

  @override
  State<AdminCitiesPage> createState() => _AdminCitiesPageState();
}

class _AdminCitiesPageState extends State<AdminCitiesPage> {
  final AdminCityApi _cityApi = AdminCityApi();

  final AdminCountryApi _countryApi = AdminCountryApi();

  final AdminStateApi _stateApi = AdminStateApi();

  // ==========================================================
  // Data
  // ==========================================================

  List<AdminCityModel> _cities = [];

  List<AdminCountryModel> _countries = [];

  List<AdminStateModel> _states = [];

  // ==========================================================
  // Loading / Error
  // ==========================================================

  bool _loading = true;

  String? _error;

  // ==========================================================
  // Filters
  // ==========================================================

  String _search = '';

  String? _selectedCountryId;

  String? _selectedStateId;

  // ==========================================================
  // Pagination
  // ==========================================================

  int _page = 1;

  final int _pageSize = 50;

  int _total = 0;

  int _totalPages = 0;

  // ==========================================================
  // Search Debounce
  // ==========================================================

  Timer? _searchDebounce;

  // ==========================================================
  // Init
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  // ==========================================================
  // Dispose
  // ==========================================================

  @override
  void dispose() {
    _searchDebounce?.cancel();

    super.dispose();
  }

  // ==========================================================
  // Load Data
  // ==========================================================

  Future<void> _loadData({int page = 1}) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;

      _error = null;

      _page = page;
    });

    try {
      final results = await Future.wait([
        _cityApi.searchCities(
          page: page,
          size: _pageSize,
          search: _search,
          countryId: _selectedCountryId,
          stateId: _selectedStateId,
        ),

        if (_countries.isEmpty) _countryApi.getActiveCountries(),
      ]);

      if (!mounted) {
        return;
      }

      final cityResult = results[0] as AdminCitySearchResult;

      final countries = _countries.isEmpty
          ? results[1] as List<AdminCountryModel>
          : _countries;

      setState(() {
        _cities = cityResult.items;

        _total = cityResult.total;

        _page = cityResult.page;

        _totalPages = cityResult.pages;

        _countries = countries;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();

        _loading = false;
      });
    }
  }

  // ==========================================================
  // Load States
  // ==========================================================

  Future<void> _loadStates(String countryId) async {
    try {
      final states = await _stateApi.getStatesByCountry(countryId);

      if (!mounted) {
        return;
      }

      setState(() {
        _states = states;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _states = [];
      });

      _showMessage('Unable to load states: $e', isError: true);
    }
  }

  // ==========================================================
  // Search
  // ==========================================================

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    setState(() {
      _search = value;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _loadData(page: 1);
    });
  }

  // ==========================================================
  // Country Name
  // ==========================================================

  String _countryName(String id) {
    for (final country in _countries) {
      if (country.id == id) {
        return country.name;
      }
    }

    return 'Unknown';
  }

  // ==========================================================
  // State Name
  // ==========================================================

  String _stateName(String id) {
    for (final state in _states) {
      if (state.id == id) {
        return state.name;
      }
    }

    return 'Unknown';
  }

  // ==========================================================
  // Add City
  // ==========================================================

  Future<void> _addCity() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _CityDialog(
        countries: _countries,
        stateApi: _stateApi,
        cityApi: _cityApi,
      ),
    );

    if (result == true) {
      await _loadData(page: 1);
    }
  }

  // ==========================================================
  // Edit City
  // ==========================================================

  Future<void> _editCity(AdminCityModel city) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _CityDialog(
        countries: _countries,
        stateApi: _stateApi,
        cityApi: _cityApi,
        city: city,
      ),
    );

    if (result == true) {
      await _loadData(page: _page);
    }
  }

  // ==========================================================
  // Delete City
  // ==========================================================

  Future<void> _deleteCity(AdminCityModel city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete City'),

          content: Text(
            'Are you sure you want to delete '
            '"${city.name}"?',
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),

              child: const Text('Cancel'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),

              onPressed: () => Navigator.of(context).pop(true),

              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _cityApi.deleteCity(city.id);

      if (!mounted) {
        return;
      }

      _showMessage('City deleted successfully.');

      await _loadData(page: _page);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Failed to delete city: $e', isError: true);
    }
  }

  // ==========================================================
  // Message
  // ==========================================================

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),

        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _buildHeader(),

            const SizedBox(height: 20),

            _buildFilters(),

            const SizedBox(height: 20),

            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Header
  // ==========================================================

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Cities',

                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),

              SizedBox(height: 4),

              Text(
                'Manage cities used '
                'throughout Trav Planner.',

                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),

        FilledButton.icon(
          onPressed: _addCity,

          icon: const Icon(Icons.add),

          label: const Text('Add City'),
        ),
      ],
    );
  }

  // ==========================================================
  // Filters
  // ==========================================================

  Widget _buildFilters() {
    return Card(
      elevation: 0,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // --------------------------------------------------
            // Search
            // --------------------------------------------------
            SizedBox(
              width: 280,
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search cities...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // Country
            // --------------------------------------------------
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedCountryId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'All countries',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ..._countries.map(
                    (country) => DropdownMenuItem<String?>(
                      value: country.id,
                      child: Text(
                        country.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCountryId = value;
                    _selectedStateId = null;
                    _states = [];
                  });

                  if (value != null) {
                    _loadStates(value);
                  }

                  _loadData(page: 1);
                },
              ),
            ),

            // --------------------------------------------------
            // State
            // --------------------------------------------------
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedStateId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All states', overflow: TextOverflow.ellipsis),
                  ),
                  ..._states.map(
                    (state) => DropdownMenuItem<String?>(
                      value: state.id,
                      child: Text(state.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: _selectedCountryId == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedStateId = value;
                        });

                        _loadData(page: 1);
                      },
              ),
            ),

            // --------------------------------------------------
            // Clear
            // --------------------------------------------------
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  _searchDebounce?.cancel();

                  setState(() {
                    _search = '';
                    _selectedCountryId = null;
                    _selectedStateId = null;
                    _states = [];
                  });

                  _loadData(page: 1);
                },
                icon: const Icon(Icons.clear, size: 17),
                label: const Text(
                  'Clear',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
  // Content
  // ==========================================================

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),

            const SizedBox(height: 12),

            Text(_error!, textAlign: TextAlign.center),

            const SizedBox(height: 12),

            FilledButton(
              onPressed: () => _loadData(page: _page),

              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_cities.isEmpty) {
      return const Center(
        child: Text(
          'No cities found.',

          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Card(
            elevation: 0,

            clipBehavior: Clip.antiAlias,

            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,

                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('City')),

                    DataColumn(label: Text('Country')),

                    DataColumn(label: Text('State')),

                    DataColumn(label: Text('Coordinates')),

                    DataColumn(label: Text('Status')),

                    DataColumn(label: Text('Actions')),
                  ],

                  rows: _cities.map((city) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            city.name,

                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),

                        DataCell(Text(_countryName(city.countryId))),

                        DataCell(Text(_stateName(city.stateId))),

                        DataCell(
                          Text(
                            city.latitude != null && city.longitude != null
                                ? '${city.latitude!.toStringAsFixed(4)}, '
                                      '${city.longitude!.toStringAsFixed(4)}'
                                : '—',
                          ),
                        ),

                        DataCell(_StatusChip(active: city.isActive)),

                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Edit',

                                onPressed: () => _editCity(city),

                                icon: const Icon(Icons.edit_outlined),
                              ),

                              IconButton(
                                tooltip: 'Delete',

                                onPressed: () => _deleteCity(city),

                                icon: const Icon(
                                  Icons.delete_outline,

                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        _buildPagination(),
      ],
    );
  }

  // ==========================================================
  // Pagination
  // ==========================================================

  Widget _buildPagination() {
    final start = _total == 0 ? 0 : ((_page - 1) * _pageSize) + 1;

    final end = ((_page - 1) * _pageSize) + _cities.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Text(
          'Showing $start–$end '
          'of $_total cities',

          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),

        Row(
          children: [
            IconButton(
              tooltip: 'Previous page',

              onPressed: _page > 1
                  ? () {
                      _loadData(page: _page - 1);
                    }
                  : null,

              icon: const Icon(Icons.chevron_left),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

              decoration: BoxDecoration(
                color: AppColors.primary,

                borderRadius: BorderRadius.circular(8),
              ),

              child: Text(
                '$_page / $_totalPages',

                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            IconButton(
              tooltip: 'Next page',

              onPressed: _page < _totalPages
                  ? () {
                      _loadData(page: _page + 1);
                    }
                  : null,

              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// Status Chip
// ============================================================

class _StatusChip extends StatelessWidget {
  final bool active;

  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: active ? AppColors.successContainer : AppColors.errorContainer,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        active ? 'Active' : 'Inactive',

        style: TextStyle(
          fontSize: 12,

          fontWeight: FontWeight.w600,

          color: active ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

// ============================================================
// Add / Edit Dialog
// ============================================================

class _CityDialog extends StatefulWidget {
  final List<AdminCountryModel> countries;

  final AdminStateApi stateApi;

  final AdminCityApi cityApi;

  final AdminCityModel? city;

  const _CityDialog({
    required this.countries,
    required this.stateApi,
    required this.cityApi,
    this.city,
  });

  @override
  State<_CityDialog> createState() => _CityDialogState();
}

class _CityDialogState extends State<_CityDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  late final TextEditingController _latitudeController;

  late final TextEditingController _longitudeController;

  List<AdminStateModel> _states = [];

  String? _countryId;

  String? _stateId;

  bool _isActive = true;

  bool _loadingStates = false;

  bool _saving = false;

  bool get _editing => widget.city != null;

  @override
  void initState() {
    super.initState();

    final city = widget.city;

    _nameController = TextEditingController(text: city?.name ?? '');

    _latitudeController = TextEditingController(
      text: city?.latitude?.toString() ?? '',
    );

    _longitudeController = TextEditingController(
      text: city?.longitude?.toString() ?? '',
    );

    _countryId = city?.countryId;

    _stateId = city?.stateId;

    _isActive = city?.isActive ?? true;

    if (_countryId != null) {
      _loadStates(_countryId!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    _latitudeController.dispose();

    _longitudeController.dispose();

    super.dispose();
  }

  // ==========================================================
  // Load States
  // ==========================================================

  Future<void> _loadStates(String countryId) async {
    setState(() {
      _loadingStates = true;
    });

    try {
      final states = await widget.stateApi.getStatesByCountry(countryId);

      if (!mounted) {
        return;
      }

      setState(() {
        _states = states;

        if (_stateId != null && !_states.any((state) => state.id == _stateId)) {
          _stateId = null;
        }

        _loadingStates = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _states = [];

        _stateId = null;

        _loadingStates = false;
      });
    }
  }

  // ==========================================================
  // Save
  // ==========================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_countryId == null || _stateId == null) {
      _showError(
        'Please select a country '
        'and state.',
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final latitude = double.tryParse(_latitudeController.text.trim());

      final longitude = double.tryParse(_longitudeController.text.trim());

      if (_editing) {
        await widget.cityApi.updateCity(
          id: widget.city!.id,

          countryId: _countryId!,

          stateId: _stateId!,

          name: _nameController.text.trim(),

          latitude: latitude,

          longitude: longitude,

          isActive: _isActive,
        );
      } else {
        await widget.cityApi.createCity(
          countryId: _countryId!,

          stateId: _stateId!,

          name: _nameController.text.trim(),

          latitude: latitude,

          longitude: longitude,

          isActive: _isActive,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showError('Failed to save city: $e');
    }
  }

  // ==========================================================
  // Error
  // ==========================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // ==========================================================
  // Dialog Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Edit City' : 'Add City'),

      content: SizedBox(
        width: 500,

        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            child: Column(
              children: [
                // ------------------------------------------------
                // City Name
                // ------------------------------------------------
                TextFormField(
                  controller: _nameController,

                  decoration: const InputDecoration(
                    labelText: 'City name',

                    hintText: 'e.g. Mumbai',
                  ),

                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Enter a valid city name.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // Country
                // ------------------------------------------------
                DropdownButtonFormField<String>(
                  initialValue: _countryId,

                  decoration: const InputDecoration(labelText: 'Country'),

                  items: widget.countries
                      .map(
                        (country) => DropdownMenuItem<String>(
                          value: country.id,

                          child: Text(country.name),
                        ),
                      )
                      .toList(),

                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _countryId = value;

                      _stateId = null;

                      _states = [];
                    });

                    _loadStates(value);
                  },

                  validator: (value) {
                    if (value == null) {
                      return 'Select a country.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // State
                // ------------------------------------------------
                DropdownButtonFormField<String>(
                  initialValue: _stateId,

                  decoration: const InputDecoration(labelText: 'State'),

                  items: _states
                      .map(
                        (state) => DropdownMenuItem<String>(
                          value: state.id,

                          child: Text(state.name),
                        ),
                      )
                      .toList(),

                  onChanged: _loadingStates
                      ? null
                      : (value) {
                          setState(() {
                            _stateId = value;
                          });
                        },

                  validator: (value) {
                    if (value == null) {
                      return 'Select a state.';
                    }

                    return null;
                  },
                ),

                if (_loadingStates)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),

                    child: LinearProgressIndicator(),
                  ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // Coordinates
                // ------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,

                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),

                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,

                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),

                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ------------------------------------------------
                // Active
                // ------------------------------------------------
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,

                  title: const Text('Active'),

                  value: _isActive,

                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      // ========================================================
      // Actions
      // ========================================================
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),

          child: const Text('Cancel'),
        ),

        FilledButton(
          onPressed: _saving ? null : _save,

          child: _saving
              ? const SizedBox(
                  width: 20,

                  height: 20,

                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                )
              : Text(_editing ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}
