import 'package:trav_planner/core/theme/app_colors.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/datasources/admin_city_api.dart';
import '../../data/datasources/admin_destination_api.dart';
import '../../data/models/admin_city_model.dart';
import '../../data/models/admin_destination_model.dart';
import 'admin_destination_photos_page.dart';

class AdminDestinationsPage extends StatefulWidget {
  const AdminDestinationsPage({super.key});

  @override
  State<AdminDestinationsPage> createState() => _AdminDestinationsPageState();
}

class _AdminDestinationsPageState extends State<AdminDestinationsPage> {
  final AdminDestinationApi _destinationApi = AdminDestinationApi();

  final TextEditingController _searchController = TextEditingController();

  List<AdminDestinationModel> _destinations = [];

  bool _loading = true;
  String? _error;

  String _search = '';
  bool? _activeFilter;
  bool? _featuredFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // Data
  // ==========================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final destinations = await _destinationApi.getAllDestinations();

      if (!mounted) {
        return;
      }

      setState(() {
        _destinations = destinations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ==========================================================
  // Filtering
  // ==========================================================

  List<AdminDestinationModel> get _filteredDestinations {
    final query = _search.trim().toLowerCase();

    return _destinations.where((destination) {
      final matchesSearch =
          query.isEmpty ||
          destination.name.toLowerCase().contains(query) ||
          destination.slug.toLowerCase().contains(query) ||
          (destination.shortDescription ?? '').toLowerCase().contains(query);

      final matchesActive =
          _activeFilter == null || destination.isActive == _activeFilter;

      final matchesFeatured =
          _featuredFilter == null || destination.isFeatured == _featuredFilter;

      return matchesSearch && matchesActive && matchesFeatured;
    }).toList();
  }

  // ==========================================================
  // Create / Edit
  // ==========================================================

  Future<void> _openDestinationForm({
    AdminDestinationModel? destination,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return _DestinationFormDialog(
          destination: destination,
          api: _destinationApi,
        );
      },
    );

    if (result == true) {
      await _loadData();
    }
  }

  // ==========================================================
  // Delete
  // ==========================================================

  Future<void> _deleteDestination(AdminDestinationModel destination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete destination?'),
          content: Text(
            'This will remove "${destination.name}" '
            'from the active destination list.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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
      await _destinationApi.deleteDestination(destination.id);

      if (!mounted) {
        return;
      }

      _showMessage('Destination deleted successfully.');

      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString());
    }
  }

  // ==========================================================
  // Toggle Active
  // ==========================================================

  Future<void> _toggleActive(AdminDestinationModel destination) async {
    try {
      await _destinationApi.updateDestination(
        id: destination.id,
        isActive: !destination.isActive,
      );

      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString());
    }
  }

  // ==========================================================
  // Toggle Featured
  // ==========================================================

  Future<void> _toggleFeatured(AdminDestinationModel destination) async {
    try {
      await _destinationApi.updateDestination(
        id: destination.id,
        isFeatured: !destination.isFeatured,
      );

      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString());
    }
  }

  // ==========================================================
  // Photos
  // ==========================================================

  Future<void> _openPhotos(AdminDestinationModel destination) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return AdminDestinationPhotosPage(destination: destination);
        },
      ),
    );
  }

  // ==========================================================
  // Helpers
  // ==========================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _search = '';
      _activeFilter = null;
      _featuredFilter = null;
    });
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),

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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final title = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Destinations',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'Manage travel destinations and their photos',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          );

          final refreshButton = SizedBox(
            width: 110,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          );

          final addButton = SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: _loading ? null : () => _openDestinationForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Destination'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    refreshButton,
                    const SizedBox(width: 8),
                    addButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),

              const SizedBox(width: 20),

              refreshButton,

              const SizedBox(width: 8),

              addButton,
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
          final width = constraints.maxWidth;

          // Compact layout
          if (width < 850) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(width: 135, child: _buildActiveFilter()),
                    SizedBox(width: 145, child: _buildFeaturedFilter()),
                    _buildClearButton(),
                  ],
                ),
              ],
            );
          }

          // Normal desktop layout
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
        hintText: 'Search destinations...',
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
        DropdownMenuItem<bool?>(
          value: false,
          child: Text('Not featured', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _featuredFilter = value;
        });
      },
    );
  }

  Widget _buildClearButton() {
    final hasFilters =
        _search.trim().isNotEmpty ||
        _activeFilter != null ||
        _featuredFilter != null;

    return SizedBox(
      width: 88,
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
        label: const Text('Clear', overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Unable to load destinations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final destinations = _filteredDestinations;

    if (destinations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisExtent: constraints.maxWidth < 700 ? 430 : 400,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              return _buildDestinationCard(destinations[index]);
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // Empty State
  // ==========================================================

  Widget _buildEmptyState() {
    final hasFilters =
        _search.isNotEmpty || _activeFilter != null || _featuredFilter != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.search_off_rounded : Icons.place_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No destinations match your filters'
                  : 'No destinations yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try changing your search or filters.'
                  : 'Create your first travel destination.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Destination Card
  // ==========================================================

  Widget _buildDestinationCard(AdminDestinationModel destination) {
    final imageUrl = destination.imageUrl;

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
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildDestinationImage(imageUrl),

                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildBadge('Destination', Icons.place_outlined),
                ),

                if (destination.isFeatured)
                  Positioned(top: 12, right: 12, child: _buildFeaturedBadge()),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          destination.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _buildActionsMenu(destination),
                    ],
                  ),

                  const SizedBox(height: 3),

                  Text(
                    destination.slug,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: Text(
                      destination.shortDescription ??
                          'No description available.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        destination.isActive
                            ? Icons.check_circle_rounded
                            : Icons.pause_circle_rounded,
                        size: 16,
                        color: destination.isActive
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        destination.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (destination.latitude != null &&
                          destination.longitude != null)
                        const Icon(Icons.location_on_outlined, size: 15),
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

  Widget _buildDestinationImage(String? imageUrl) {
    final normalizedUrl = _normalizeImageUrl(imageUrl);

    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      normalizedUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            _imagePlaceholder(),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _imagePlaceholder();
      },
    );
  }

  String? _normalizeImageUrl(String? value) {
    if (value == null) {
      return null;
    }

    var url = value.trim();

    if (url.isEmpty) {
      return null;
    }

    // Protect the UI from URLs accidentally stored as Markdown:
    // [https://example.com/image](https://example.com/image)
    final markdownMatch = RegExp(
      r'^\\s*\\[.*?\\]\\((https?://[^)]+)\\)\\s*$',
    ).firstMatch(url);

    if (markdownMatch != null) {
      url = markdownMatch.group(1)!.trim();
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return null;
    }

    return url;
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15),
          const SizedBox(width: 4),
          const Text(
            'Featured',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Actions Menu
  // ==========================================================

  Widget _buildActionsMenu(AdminDestinationModel destination) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        switch (value) {
          case 'photos':
            _openPhotos(destination);
            break;

          case 'edit':
            _openDestinationForm(destination: destination);
            break;

          case 'active':
            _toggleActive(destination);
            break;

          case 'featured':
            _toggleFeatured(destination);
            break;

          case 'delete':
            _deleteDestination(destination);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'photos',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined),
              SizedBox(width: 12),
              Text('Manage Photos'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'active',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                destination.isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              const SizedBox(width: 12),
              Text(destination.isActive ? 'Deactivate' : 'Activate'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'featured',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                destination.isFeatured
                    ? Icons.star_outline_rounded
                    : Icons.star_rounded,
              ),
              const SizedBox(width: 12),
              Text(
                destination.isFeatured ? 'Remove Featured' : 'Make Featured',
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, color: AppColors.error),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Destination Form
// ============================================================

class _DestinationFormDialog extends StatefulWidget {
  final AdminDestinationModel? destination;
  final AdminDestinationApi api;

  const _DestinationFormDialog({required this.destination, required this.api});

  @override
  State<_DestinationFormDialog> createState() => _DestinationFormDialogState();
}

class _DestinationFormDialogState extends State<_DestinationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final AdminCityApi _cityApi = AdminCityApi();

  late final TextEditingController _nameController;

  late final TextEditingController _slugController;

  late final TextEditingController _shortController;

  late final TextEditingController _descriptionController;

  late final TextEditingController _imageController;

  late final TextEditingController _latitudeController;

  late final TextEditingController _longitudeController;

  late final TextEditingController _citySearchController;

  String? _cityId;

  List<AdminCityModel> _cityResults = [];

  bool _cityLoading = false;
  bool _showCityResults = false;

  Timer? _citySearchDebounce;

  bool _isFeatured = false;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final destination = widget.destination;

    _nameController = TextEditingController(text: destination?.name ?? '');

    _slugController = TextEditingController(text: destination?.slug ?? '');

    _shortController = TextEditingController(
      text: destination?.shortDescription ?? '',
    );

    _descriptionController = TextEditingController(
      text: destination?.description ?? '',
    );

    _imageController = TextEditingController(text: destination?.imageUrl ?? '');

    _latitudeController = TextEditingController(
      text: destination?.latitude?.toString() ?? '',
    );

    _longitudeController = TextEditingController(
      text: destination?.longitude?.toString() ?? '',
    );

    _citySearchController = TextEditingController();

    _cityId = destination?.cityId;

    _isFeatured = destination?.isFeatured ?? false;

    _isActive = destination?.isActive ?? true;

    _citySearchController.addListener(_onCitySearchChanged);
  }

  @override
  void dispose() {
    _citySearchDebounce?.cancel();

    _nameController.dispose();
    _slugController.dispose();
    _shortController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _citySearchController.dispose();

    super.dispose();
  }

  // ==========================================================
  // City Search
  // ==========================================================

  void _onCitySearchChanged() {
    final query = _citySearchController.text.trim();

    _citySearchDebounce?.cancel();

    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _cityResults = [];
          _showCityResults = false;
          _cityLoading = false;
        });
      }
      return;
    }

    _citySearchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchCities(query);
    });
  }

  Future<void> _searchCities(String query) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _cityLoading = true;
      _showCityResults = true;
    });

    try {
      final result = await _cityApi.searchCities(
        page: 1,
        size: 20,
        search: query,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _cityResults = result.items;
        _cityLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cityResults = [];
        _cityLoading = false;
      });
    }
  }

  void _selectCity(AdminCityModel city) {
    setState(() {
      _cityId = city.id;
      _cityResults = [];
      _showCityResults = false;
    });

    _citySearchController.text = city.name;

    FocusScope.of(context).unfocus();
  }

  // ==========================================================
  // Save
  // ==========================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_cityId == null || _cityId!.isEmpty) {
      _showFormError('Please select a city.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final latitude = double.tryParse(_latitudeController.text.trim());

      final longitude = double.tryParse(_longitudeController.text.trim());

      final imageUrl = _imageController.text.trim();

      if (widget.destination == null) {
        await widget.api.createDestination(
          cityId: _cityId!,
          name: _nameController.text.trim(),
          slug: _slugController.text.trim(),
          shortDescription: _nullableText(_shortController.text),
          description: _nullableText(_descriptionController.text),
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          latitude: latitude,
          longitude: longitude,
          isFeatured: _isFeatured,
        );
      } else {
        await widget.api.updateDestination(
          id: widget.destination!.id,
          cityId: _cityId,
          name: _nameController.text.trim(),
          slug: _slugController.text.trim(),
          shortDescription: _nullableText(_shortController.text),
          description: _nullableText(_descriptionController.text),
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          latitude: latitude,
          longitude: longitude,
          isFeatured: _isFeatured,
          isActive: _isActive,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showFormError(e.toString());
    }
  }

  String? _nullableText(String value) {
    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  void _showFormError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ==========================================================
  // Build Dialog
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final editing = widget.destination != null;

    return AlertDialog(
      title: Text(editing ? 'Edit Destination' : 'Add Destination'),

      // Prevent AlertDialog from trying to calculate the
      // intrinsic height of the scrollable content.
      content: SizedBox(
        width: 620,
        height: 620,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =====================================================
                      // City
                      // =====================================================
                      const Text(
                        'City',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: _citySearchController,
                        onTap: () {
                          if (_citySearchController.text.trim().isNotEmpty) {
                            setState(() {
                              _showCityResults = true;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search city...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _cityId != null
                              ? IconButton(
                                  tooltip: 'Change city',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    setState(() {
                                      _cityId = null;
                                      _citySearchController.clear();
                                      _cityResults = [];
                                      _showCityResults = false;
                                    });
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      if (_showCityResults) ...[
                        const SizedBox(height: 6),
                        _buildCityResults(),
                      ],

                      if (_cityId != null && !_showCityResults)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'City selected',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // Name
                      // =====================================================
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Destination name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a destination name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // Slug
                      // =====================================================
                      TextFormField(
                        controller: _slugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug',
                          hintText: 'taj-mahal',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a slug';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // Short Description
                      // =====================================================
                      TextFormField(
                        controller: _shortController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Short description',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // Description
                      // =====================================================
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // Image URL
                      // =====================================================
                      TextFormField(
                        controller: _imageController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Cover image URL',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.image_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // Coordinates
                      // =====================================================
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // =====================================================
                      // Featured
                      // =====================================================
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Featured destination'),
                        subtitle: const Text(
                          'Show this destination in featured sections.',
                        ),
                        value: _isFeatured,
                        onChanged: (value) {
                          setState(() {
                            _isFeatured = value;
                          });
                        },
                      ),

                      // =====================================================
                      // Active
                      // =====================================================
                      if (editing)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active'),
                          subtitle: const Text(
                            'Allow this destination to appear to users.',
                          ),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                        ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
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
  // City Results
  // ==========================================================

  Widget _buildCityResults() {
    if (_cityLoading) {
      return Container(
        height: 90,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cityResults.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No matching cities found.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        primary: false,
        itemCount: _cityResults.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final city = _cityResults[index];

          return InkWell(
            onTap: () => _selectCity(city),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_city,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      city.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),

                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
