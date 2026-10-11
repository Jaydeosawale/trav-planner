import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../data/datasources/admin_place_api.dart';
import '../../data/models/admin_place_model.dart';
import '../../data/datasources/admin_city_api.dart';
import '../../data/datasources/admin_category_api.dart';
import '../../data/datasources/admin_country_api.dart';
import '../../data/datasources/admin_state_api.dart';
import '../../data/models/admin_city_model.dart';
import '../../data/models/admin_category_model.dart';
import '../../data/models/admin_country_model.dart';
import '../../data/models/admin_state_model.dart';

class AdminPlacesPage extends StatefulWidget {
  const AdminPlacesPage({super.key});

  @override
  State<AdminPlacesPage> createState() => _AdminPlacesPageState();
}

class _AdminPlacesPageState extends State<AdminPlacesPage> {
  final AdminPlaceApi _api = AdminPlaceApi();

  final TextEditingController _searchController = TextEditingController();

  List<AdminPlaceModel> _places = [];

  bool _loading = true;
  String? _error;

  bool? _activeFilter;
  bool? _featuredFilter;

  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // Load
  // ==========================================================

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final places = await _api.getPlaces();

      if (!mounted) return;

      setState(() {
        _places = places;
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
  // Filtered Places
  // ==========================================================

  List<AdminPlaceModel> get _filteredPlaces {
    final query = _search.trim().toLowerCase();

    return _places.where((place) {
      if (_activeFilter != null && place.isActive != _activeFilter) {
        return false;
      }

      if (_featuredFilter != null && place.isFeatured != _featuredFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return place.name.toLowerCase().contains(query) ||
          place.slug.toLowerCase().contains(query) ||
          place.placeType.toLowerCase().contains(query) ||
          (place.locality?.toLowerCase().contains(query) ?? false) ||
          (place.address?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildToolbar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  // ==========================================================
  // Header
  // ==========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Places',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'Manage attractions, restaurants, hotels and other places',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 120,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _loadPlaces,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : () => _openPlaceForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Place'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // Toolbar
  // ==========================================================

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 850) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildActiveFilter()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildFeaturedFilter()),
                    const SizedBox(width: 10),
                    _buildClearButton(),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 10),
              SizedBox(width: 135, child: _buildActiveFilter()),
              const SizedBox(width: 10),
              SizedBox(width: 145, child: _buildFeaturedFilter()),
              const SizedBox(width: 10),
              _buildClearButton(),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // Search
  // ==========================================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        hintText: 'Search places, type, locality...',
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // ==========================================================
  // Active Filter
  // ==========================================================

  Widget _buildActiveFilter() {
    return DropdownButtonFormField<bool?>(
      initialValue: _activeFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Status',
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: const [
        DropdownMenuItem<bool?>(value: null, child: Text('All')),
        DropdownMenuItem<bool?>(value: true, child: Text('Active')),
        DropdownMenuItem<bool?>(value: false, child: Text('Inactive')),
      ],
      onChanged: (value) {
        setState(() {
          _activeFilter = value;
        });
      },
    );
  }

  // ==========================================================
  // Featured Filter
  // ==========================================================

  Widget _buildFeaturedFilter() {
    return DropdownButtonFormField<bool?>(
      initialValue: _featuredFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Featured',
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: const [
        DropdownMenuItem<bool?>(value: null, child: Text('All')),
        DropdownMenuItem<bool?>(value: true, child: Text('Featured')),
        DropdownMenuItem<bool?>(value: false, child: Text('Not featured')),
      ],
      onChanged: (value) {
        setState(() {
          _featuredFilter = value;
        });
      },
    );
  }

  // ==========================================================
  // Clear
  // ==========================================================

  Widget _buildClearButton() {
    final hasFilters =
        _search.trim().isNotEmpty ||
        _activeFilter != null ||
        _featuredFilter != null;

    return SizedBox(
      width: 100,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: hasFilters
            ? () {
                _searchController.clear();

                setState(() {
                  _search = '';
                  _activeFilter = null;
                  _featuredFilter = null;
                });
              }
            : null,
        icon: const Icon(Icons.clear_rounded, size: 17),
        label: const Text('Clear'),
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
      return _buildError();
    }

    if (_filteredPlaces.isEmpty) {
      return _buildEmpty();
    }

    return _buildPlaceGrid();
  }

  // ==========================================================
  // Error
  // ==========================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Unable to load places',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadPlaces,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Empty
  // ==========================================================

  Widget _buildEmpty() {
    final hasFilters =
        _search.trim().isNotEmpty ||
        _activeFilter != null ||
        _featuredFilter != null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place_outlined, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No matching places' : 'No places found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'Try changing your search or filters.'
                : 'Places created by Admin will appear here.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _search = '';
                  _activeFilter = null;
                  _featuredFilter = null;
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // Grid
  // ==========================================================

  Widget _buildPlaceGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1400
            ? 4
            : width >= 1050
            ? 3
            : width >= 700
            ? 2
            : 1;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.92,
          ),
          itemCount: _filteredPlaces.length,
          itemBuilder: (context, index) {
            return _buildPlaceCard(_filteredPlaces[index]);
          },
        );
      },
    );
  }

  // ==========================================================
  // Card
  // ==========================================================

  Widget _buildPlaceCard(AdminPlaceModel place) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPlaceImage(place.imageUrl),

                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildBadge(place.placeType, Icons.place_outlined),
                ),

                if (place.isFeatured)
                  Positioned(top: 12, right: 12, child: _buildFeaturedBadge()),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _buildMoreMenu(place),
                    ],
                  ),

                  const SizedBox(height: 6),

                  if (place.locality != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.locality!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  if (place.rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          place.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (place.priceLevel != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            _priceLevelText(place.priceLevel!),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),

                  const Spacer(),

                  Row(
                    children: [
                      _buildStatusChip(
                        label: place.isActive ? 'Active' : 'Inactive',
                        active: place.isActive,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _openPlaceForm(place: place),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Image
  // ==========================================================

  Widget _buildPlaceImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Icon(
            Icons.place_outlined,
            size: 52,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.surfaceVariant,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 42,
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // Badge
  // ==========================================================

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textPrimary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Featured Badge
  // ==========================================================

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: AppColors.textPrimary),
          SizedBox(width: 4),
          Text(
            'Featured',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Status Chip
  // ==========================================================

  Widget _buildStatusChip({required String label, required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.10)
            : Colors.grey.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.success : AppColors.textPrimary,
        ),
      ),
    );
  }

  // ==========================================================
  // More Menu
  // ==========================================================

  Widget _buildMoreMenu(AdminPlaceModel place) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _openPlaceForm(place: place);
            break;

          case 'toggle':
            _toggleActive(place);
            break;

          case 'featured':
            _toggleFeatured(place);
            break;

          case 'delete':
            _confirmDelete(place);
            break;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit'),
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                place.isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              title: Text(place.isActive ? 'Deactivate' : 'Activate'),
            ),
          ),
          PopupMenuItem(
            value: 'featured',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                place.isFeatured
                    ? Icons.star_border_rounded
                    : Icons.star_rounded,
              ),
              title: Text(
                place.isFeatured ? 'Remove featured' : 'Make featured',
              ),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              title: Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ),
        ];
      },
    );
  }

  // ==========================================================
  // Toggle Active
  // ==========================================================

  Future<void> _toggleActive(AdminPlaceModel place) async {
    try {
      await _api.updatePlace(placeId: place.id, isActive: !place.isActive);

      await _loadPlaces();

      if (!mounted) return;

      _showMessage(place.isActive ? 'Place deactivated' : 'Place activated');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to update place', error: true);
    }
  }

  // ==========================================================
  // Toggle Featured
  // ==========================================================

  Future<void> _toggleFeatured(AdminPlaceModel place) async {
    try {
      await _api.updatePlace(placeId: place.id, isFeatured: !place.isFeatured);

      await _loadPlaces();

      if (!mounted) return;

      _showMessage(
        place.isFeatured ? 'Removed from featured' : 'Place marked as featured',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to update place', error: true);
    }
  }

  // ==========================================================
  // Delete Confirmation
  // ==========================================================

  Future<void> _confirmDelete(AdminPlaceModel place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Place?'),
          content: Text('Are you sure you want to delete "${place.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                Navigator.pop(context, true);
              },
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
      await _api.deletePlace(place.id);

      await _loadPlaces();

      if (!mounted) return;

      _showMessage('Place deleted successfully');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to delete place', error: true);
    }
  }

  // ==========================================================
  // Form
  // ==========================================================

  Future<void> _openPlaceForm({AdminPlaceModel? place}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _PlaceFormDialog(api: _api, place: place);
      },
    );

    if (result == true) {
      await _loadPlaces();
    }
  }

  // ==========================================================
  // Message
  // ==========================================================

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : null,
      ),
    );
  }

  // ==========================================================
  // Price Level
  // ==========================================================

  String _priceLevelText(int value) {
    if (value <= 0) {
      return 'Free';
    }

    return '\$' * value;
  }
}

// ============================================================
// Place Form Dialog
// ============================================================

class _PlaceFormDialog extends StatefulWidget {
  final AdminPlaceApi api;
  final AdminPlaceModel? place;

  const _PlaceFormDialog({required this.api, this.place});

  @override
  State<_PlaceFormDialog> createState() => _PlaceFormDialogState();
}

class _PlaceFormDialogState extends State<_PlaceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final AdminCountryApi _countryApi = AdminCountryApi();
  final AdminStateApi _stateApi = AdminStateApi();
  final AdminCityApi _cityApi = AdminCityApi();
  final AdminCategoryApi _categoryApi = AdminCategoryApi();

  List<AdminCountryModel> _countries = [];
  List<AdminStateModel> _states = [];
  List<AdminCityModel> _cities = [];
  List<AdminCategoryModel> _categories = [];

  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _loadingCategories = false;

  String? _selectedCountryId;
  String? _selectedStateId;
  AdminCityModel? _selectedCity;

  final TextEditingController _citySearchController = TextEditingController();

  late final TextEditingController _cityIdController;

  late final TextEditingController _categoryIdController;

  late final TextEditingController _nameController;

  late final TextEditingController _slugController;

  late final TextEditingController _placeTypeController;

  late final TextEditingController _shortDescriptionController;

  late final TextEditingController _descriptionController;

  late final TextEditingController _addressController;

  late final TextEditingController _localityController;

  late final TextEditingController _postalCodeController;

  late final TextEditingController _latitudeController;

  late final TextEditingController _longitudeController;

  late final TextEditingController _imageController;

  late final TextEditingController _providerController;

  late final TextEditingController _externalPlaceIdController;

  late final TextEditingController _ratingController;

  late final TextEditingController _priceLevelController;

  bool _isFeatured = false;
  bool _isActive = true;
  bool _saving = false;

  bool get _editing => widget.place != null;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _loadCategories();

    final place = widget.place;

    _cityIdController = TextEditingController(text: place?.cityId ?? '');

    _categoryIdController = TextEditingController(
      text: place?.categoryId ?? '',
    );

    _nameController = TextEditingController(text: place?.name ?? '');

    _slugController = TextEditingController(text: place?.slug ?? '');

    _placeTypeController = TextEditingController(text: place?.placeType ?? '');

    _shortDescriptionController = TextEditingController(
      text: place?.shortDescription ?? '',
    );

    _descriptionController = TextEditingController(
      text: place?.description ?? '',
    );

    _addressController = TextEditingController(text: place?.address ?? '');

    _localityController = TextEditingController(text: place?.locality ?? '');

    _postalCodeController = TextEditingController(
      text: place?.postalCode ?? '',
    );

    _latitudeController = TextEditingController(
      text: place?.latitude?.toString() ?? '',
    );

    _longitudeController = TextEditingController(
      text: place?.longitude?.toString() ?? '',
    );

    _imageController = TextEditingController(text: place?.imageUrl ?? '');

    _providerController = TextEditingController(text: place?.provider ?? '');

    _externalPlaceIdController = TextEditingController(
      text: place?.externalPlaceId ?? '',
    );

    _ratingController = TextEditingController(
      text: place?.rating?.toString() ?? '',
    );

    _priceLevelController = TextEditingController(
      text: place?.priceLevel?.toString() ?? '',
    );

    _isFeatured = place?.isFeatured ?? false;

    _isActive = place?.isActive ?? true;
  }

  @override
  void dispose() {
    _cityIdController.dispose();
    _citySearchController.dispose();
    _categoryIdController.dispose();
    _nameController.dispose();
    _slugController.dispose();
    _placeTypeController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _localityController.dispose();
    _postalCodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _imageController.dispose();
    _providerController.dispose();
    _externalPlaceIdController.dispose();
    _ratingController.dispose();
    _priceLevelController.dispose();

    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _loadingCountries = true;
    });

    try {
      final countries = await _countryApi.getActiveCountries();

      if (!mounted) return;

      setState(() {
        _countries = countries;
        _loadingCountries = false;
      });

      final place = widget.place;
      if (place != null) {
        await _initializeLocationForEdit(place);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingCountries = false;
      });
    }
  }

  Future<void> _initializeLocationForEdit(AdminPlaceModel place) async {
    try {
      final cityResult = await _cityApi.searchCities(
        page: 1,
        size: 1,
        search: place.cityId,
      );

      AdminCityModel? city;
      if (cityResult.items.isNotEmpty &&
          cityResult.items.first.id == place.cityId) {
        city = cityResult.items.first;
      }

      if (city == null) {
        final allResult = await _cityApi.searchCities(page: 1, size: 100);

        for (final item in allResult.items) {
          if (item.id == place.cityId) {
            city = item;
            break;
          }
        }
      }

      if (!mounted || city == null) return;

      await _selectCountryAndStateForCity(city);

      if (!mounted) return;

      setState(() {
        _selectedCity = city;
        _cityIdController.text = city!.id;
        _citySearchController.text = city.name;
      });
    } catch (_) {
      // Keep the existing city id so an edit can still be submitted.
      if (!mounted) return;

      setState(() {
        _cityIdController.text = place.cityId;
      });
    }
  }

  Future<void> _selectCountryAndStateForCity(AdminCityModel city) async {
    final country = _countries.where((item) => item.id == city.countryId);

    if (country.isEmpty) return;

    setState(() {
      _selectedCountryId = city.countryId;
      _selectedStateId = null;
      _states = [];
      _selectedCity = null;
      _cityIdController.clear();
      _citySearchController.clear();
    });

    final states = await _stateApi.getStatesByCountry(city.countryId);

    if (!mounted) return;

    setState(() {
      _states = states;
      _selectedStateId = city.stateId;
    });

    await _searchCities(stateId: city.stateId);
  }

  Future<void> _loadStates(String countryId) async {
    setState(() {
      _selectedCountryId = countryId;
      _selectedStateId = null;
      _states = [];
      _cities = [];
      _selectedCity = null;
      _cityIdController.clear();
      _citySearchController.clear();
      _loadingStates = true;
    });

    try {
      final states = await _stateApi.getStatesByCountry(countryId);

      if (!mounted) return;

      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingStates = false;
      });
    }
  }

  Future<void> _loadCitiesForState(String stateId) async {
    setState(() {
      _selectedStateId = stateId;
      _cities = [];
      _selectedCity = null;
      _cityIdController.clear();
      _citySearchController.clear();
    });

    await _searchCities(stateId: stateId);
  }

  Future<void> _searchCities({String? search, String? stateId}) async {
    final effectiveStateId = stateId ?? _selectedStateId;

    if (_selectedCountryId == null || effectiveStateId == null) {
      return;
    }

    setState(() {
      _loadingCities = true;
    });

    try {
      final result = await _cityApi.searchCities(
        page: 1,
        size: 50,
        search: search,
        countryId: _selectedCountryId,
        stateId: effectiveStateId,
      );

      if (!mounted) return;

      setState(() {
        _cities = result.items;
        _loadingCities = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cities = [];
        _loadingCities = false;
      });
    }
  }

  void _onCitySearchChanged(String value) {
    if (_selectedStateId == null) return;

    _searchCities(search: value.trim().isEmpty ? null : value.trim());
  }

  void _selectCity(AdminCityModel city) {
    setState(() {
      _selectedCity = city;
      _cityIdController.text = city.id;
      _citySearchController.text = city.name;
      _cities = [];
    });
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });

    try {
      final result = await _categoryApi.getActiveCategories();

      if (!mounted) return;

      setState(() {
        _categories = result;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCategories = false;
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

    setState(() {
      _saving = true;
    });

    try {
      final latitude = double.tryParse(_latitudeController.text.trim());

      final longitude = double.tryParse(_longitudeController.text.trim());

      final rating = double.tryParse(_ratingController.text.trim());

      final priceLevel = int.tryParse(_priceLevelController.text.trim());

      final cityId = _selectedCity?.id ?? _cityIdController.text.trim();

      if (cityId.isEmpty) {
        throw Exception('Please select a city.');
      }

      if (_editing) {
        await widget.api.updatePlace(
          placeId: widget.place!.id,
          cityId: cityId,
          categoryId: _nullable(_categoryIdController),
          name: _nameController.text.trim(),
          slug: _slugController.text.trim(),
          placeType: _placeTypeController.text.trim(),
          shortDescription: _nullable(_shortDescriptionController),
          description: _nullable(_descriptionController),
          address: _nullable(_addressController),
          locality: _nullable(_localityController),
          postalCode: _nullable(_postalCodeController),
          latitude: latitude,
          longitude: longitude,
          imageUrl: _nullable(_imageController),
          provider: _nullable(_providerController),
          externalPlaceId: _nullable(_externalPlaceIdController),
          rating: rating,
          priceLevel: priceLevel,
          isFeatured: _isFeatured,
          isActive: _isActive,
        );
      } else {
        await widget.api.createPlace(
          cityId: cityId,
          categoryId: _nullable(_categoryIdController),
          name: _nameController.text.trim(),
          slug: _slugController.text.trim(),
          placeType: _placeTypeController.text.trim(),
          shortDescription: _nullable(_shortDescriptionController),
          description: _nullable(_descriptionController),
          address: _nullable(_addressController),
          locality: _nullable(_localityController),
          postalCode: _nullable(_postalCodeController),
          latitude: latitude,
          longitude: longitude,
          imageUrl: _nullable(_imageController),
          provider: _nullable(_providerController),
          externalPlaceId: _nullable(_externalPlaceIdController),
          rating: rating,
          priceLevel: priceLevel,
          isFeatured: _isFeatured,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save place: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String? _nullable(TextEditingController controller) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Edit Place' : 'Add Place'),
      content: SizedBox(
        width: 700,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 700),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Basic Information'),

                  _DropdownField<String>(
                    label: 'Country',
                    value: _selectedCountryId,
                    items: _countries
                        .map(
                          (country) => DropdownMenuItem<String>(
                            value: country.id,
                            child: Text(
                              '${country.name} (${country.iso2})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    loading: _loadingCountries,
                    required: true,
                    onChanged: (value) {
                      if (value != null) {
                        _loadStates(value);
                      }
                    },
                  ),

                  _DropdownField<String>(
                    label: 'State / Province / Region',
                    value: _selectedStateId,
                    items: _states
                        .map(
                          (state) => DropdownMenuItem<String>(
                            value: state.id,
                            child: Text(
                              state.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    loading: _loadingStates,
                    required: true,
                    onChanged: (value) {
                      if (value != null) {
                        _loadCitiesForState(value);
                      }
                    },
                  ),

                  _SearchableCityField(
                    controller: _citySearchController,
                    cities: _cities,
                    loading: _loadingCities,
                    enabled: _selectedStateId != null,
                    selectedCityId: _selectedCity?.id,
                    onChanged: _onCitySearchChanged,
                    onSelected: _selectCity,
                  ),

                  _DropdownField<String>(
                    label: 'Category',
                    value: _categoryIdController.text.trim().isEmpty
                        ? null
                        : _categoryIdController.text.trim(),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(
                              category.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    loading: _loadingCategories,
                    required: false,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _categoryIdController.text = value;
                      });
                    },
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller: _nameController,
                          label: 'Place name',
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _textField(
                          controller: _placeTypeController,
                          label: 'Place type',
                          hint: 'attraction, hotel, cafe...',
                          required: true,
                        ),
                      ),
                    ],
                  ),

                  _textField(
                    controller: _slugController,
                    label: 'Slug',
                    hint: 'taj-mahal',
                    required: true,
                  ),

                  _textField(
                    controller: _shortDescriptionController,
                    label: 'Short description',
                    maxLines: 2,
                  ),

                  _textField(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 4,
                  ),

                  const SizedBox(height: 12),

                  _sectionTitle('Location'),

                  _textField(
                    controller: _addressController,
                    label: 'Address',
                    maxLines: 2,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller: _localityController,
                          label: 'Locality',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _textField(
                          controller: _postalCodeController,
                          label: 'Postal code',
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller: _latitudeController,
                          label: 'Latitude',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _textField(
                          controller: _longitudeController,
                          label: 'Longitude',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _sectionTitle('Media & Provider'),

                  _textField(
                    controller: _imageController,
                    label: 'Image URL',
                    keyboardType: TextInputType.url,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller: _providerController,
                          label: 'Provider',
                          hint: 'google',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _textField(
                          controller: _externalPlaceIdController,
                          label: 'External Place ID',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _sectionTitle('Rating & Pricing'),

                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller: _ratingController,
                          label: 'Rating',
                          hint: '0 - 5',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _textField(
                          controller: _priceLevelController,
                          label: 'Price level',
                          hint: '0 - 4',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Featured'),
                    subtitle: const Text(
                      'Show this place in featured sections.',
                    ),
                    value: _isFeatured,
                    onChanged: (value) {
                      setState(() {
                        _isFeatured = value;
                      });
                    },
                  ),

                  if (_editing)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      subtitle: const Text(
                        'Allow this place to appear to users.',
                      ),
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
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(context, false);
                },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  // ==========================================================
  // Section Title
  // ==========================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }

  // ==========================================================
  // Text Field
  // ==========================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }

                return null;
              }
            : null,
      ),
    );
  }
}

class _SearchableCityField extends StatelessWidget {
  final TextEditingController controller;
  final List<AdminCityModel> cities;
  final bool loading;
  final bool enabled;
  final String? selectedCityId;
  final ValueChanged<String> onChanged;
  final ValueChanged<AdminCityModel> onSelected;

  const _SearchableCityField({
    required this.controller,
    required this.cities,
    required this.loading,
    required this.enabled,
    required this.selectedCityId,
    required this.onChanged,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final showResults =
        enabled &&
        controller.text.trim().isNotEmpty &&
        cities.isNotEmpty &&
        selectedCityId == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            enabled: enabled,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: 'City *',
              hintText: enabled
                  ? 'Search city...'
                  : 'Select a country and state first',
              border: const OutlineInputBorder(),
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : controller.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear city',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : const Icon(Icons.search),
            ),
            validator: (_) {
              if (selectedCityId == null || selectedCityId!.isEmpty) {
                return 'City is required';
              }
              return null;
            },
          ),
          if (showResults)
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cities.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final city = cities[index];

                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_city_outlined),
                    title: Text(city.name),
                    subtitle: (city.latitude != null && city.longitude != null)
                        ? Text(
                            '${city.latitude}, ${city.longitude}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    onTap: () => onSelected(city),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool loading;
  final bool required;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.loading = false,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items,
        onChanged: loading ? null : onChanged,
      ),
    );
  }
}
