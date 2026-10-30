import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../data/datasources/admin_banner_api.dart';
import '../../data/models/admin_banner_model.dart';

class AdminBannersPage extends StatefulWidget {
  const AdminBannersPage({super.key});

  @override
  State<AdminBannersPage> createState() => _AdminBannersPageState();
}

class _AdminBannersPageState extends State<AdminBannersPage> {
  final AdminBannerApi _api = AdminBannerApi();

  List<AdminBannerModel> _banners = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  // ==========================================================
  // Load
  // ==========================================================

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final banners = await _api.getAllBanners();

      if (!mounted) return;

      setState(() {
        _banners = banners;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ==========================================================
  // Filtering
  // ==========================================================

  List<AdminBannerModel> get _filteredBanners {
    final query = _searchQuery.trim().toLowerCase();

    return _banners.where((banner) {
      final matchesSearch =
          query.isEmpty ||
          banner.title.toLowerCase().contains(query) ||
          (banner.campaignName?.toLowerCase().contains(query) ?? false);

      final matchesActive =
          _activeFilter == null || banner.isActive == _activeFilter;

      return matchesSearch && matchesActive;
    }).toList()..sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.displayOrder.compareTo(b.displayOrder);
    });
  }

  // ==========================================================
  // Delete
  // ==========================================================

  Future<void> _deleteBanner(AdminBannerModel banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Banner'),
          content: Text(
            'Are you sure you want to delete '
            '"${banner.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _api.deleteBanner(banner.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner deleted successfully.')),
      );

      await _loadBanners();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete banner: $e')));
    }
  }

  // ==========================================================
  // Toggle active
  // ==========================================================

  Future<void> _toggleActive(AdminBannerModel banner) async {
    try {
      await _api.updateBanner(id: banner.id, isActive: !banner.isActive);

      if (!mounted) return;

      await _loadBanners();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update banner: $e')));
    }
  }

  // ==========================================================
  // Create / Edit
  // ==========================================================

  Future<void> _openBannerForm([AdminBannerModel? banner]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _BannerFormDialog(api: _api, banner: banner);
      },
    );

    if (result == true) {
      await _loadBanners();
    }
  }

  // ==========================================================
  // Page
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return Column(
              children: [
                _buildHeader(isMobile),
                Expanded(child: _buildContent(isMobile)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBannerForm(),
        icon: const Icon(Icons.add),
        label: const Text('Create Banner'),
      ),
    );
  }

  // ==========================================================
  // Header
  // ==========================================================

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 28,
        20,
        isMobile ? 16 : 28,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Banners',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage promotional banners and campaigns',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadBanners,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Content
  // ==========================================================

  Widget _buildContent(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _loadBanners,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 28,
          8,
          isMobile ? 16 : 28,
          100,
        ),
        children: [
          _buildSummaryCards(isMobile),
          const SizedBox(height: 20),
          _buildFilters(isMobile),
          const SizedBox(height: 20),
          if (_filteredBanners.isEmpty)
            _buildEmptyState()
          else
            ..._filteredBanners.map(
              (banner) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildBannerCard(banner, isMobile),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // Summary
  // ==========================================================

  Widget _buildSummaryCards(bool isMobile) {
    final total = _banners.length;

    final active = _banners.where((banner) => banner.isActive).length;

    final inactive = total - active;

    final scheduled = _banners.where((banner) {
      return banner.startsAt != null || banner.endsAt != null;
    }).length;

    final cards = [
      _SummaryCard(
        label: 'Total',
        value: total.toString(),
        icon: Icons.view_carousel_outlined,
      ),
      _SummaryCard(
        label: 'Active',
        value: active.toString(),
        icon: Icons.visibility_outlined,
      ),
      _SummaryCard(
        label: 'Inactive',
        value: inactive.toString(),
        icon: Icons.visibility_off_outlined,
      ),
      _SummaryCard(
        label: 'Scheduled',
        value: scheduled.toString(),
        icon: Icons.schedule_outlined,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: card,
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: cards
          .map(
            (card) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: card,
              ),
            ),
          )
          .toList(),
    );
  }

  // ==========================================================
  // Filters
  // ==========================================================

  Widget _buildFilters(bool isMobile) {
    final searchField = TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search banners or campaigns...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final filter = DropdownButtonFormField<bool?>(
      initialValue: _activeFilter,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

    if (isMobile) {
      return Column(
        children: [searchField, const SizedBox(height: 12), filter],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 12),
        SizedBox(width: 180, child: filter),
      ],
    );
  }

  // ==========================================================
  // Banner Card
  // ==========================================================

  Widget _buildBannerCard(AdminBannerModel banner, bool isMobile) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isMobile
            ? _buildMobileBannerCard(banner)
            : _buildDesktopBannerCard(banner),
      ),
    );
  }

  Widget _buildDesktopBannerCard(AdminBannerModel banner) {
    return Row(
      children: [
        _buildImage(banner, width: 190, height: 110),
        const SizedBox(width: 18),
        Expanded(child: _buildBannerInfo(banner)),
        const SizedBox(width: 12),
        _buildActions(banner),
      ],
    );
  }

  Widget _buildMobileBannerCard(AdminBannerModel banner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImage(banner, width: double.infinity, height: 180),
        const SizedBox(height: 14),
        _buildBannerInfo(banner),
        const SizedBox(height: 12),
        _buildActions(banner),
      ],
    );
  }

  Widget _buildImage(
    AdminBannerModel banner, {
    required double width,
    required double height,
  }) {
    if (banner.imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        banner.imageUrl,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined),
          );
        },
      ),
    );
  }

  Widget _buildBannerInfo(AdminBannerModel banner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                banner.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            _StatusChip(isActive: banner.isActive),
          ],
        ),
        if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(banner.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.priority_high,
              label: 'Priority ${banner.priority}',
            ),
            _InfoChip(icon: Icons.sort, label: 'Order ${banner.displayOrder}'),
            if (banner.campaignName != null && banner.campaignName!.isNotEmpty)
              _InfoChip(
                icon: Icons.campaign_outlined,
                label: banner.campaignName!,
              ),
            if (banner.startsAt != null)
              _InfoChip(
                icon: Icons.play_arrow_outlined,
                label: _formatDate(banner.startsAt!),
              ),
            if (banner.endsAt != null)
              _InfoChip(
                icon: Icons.stop_outlined,
                label: _formatDate(banner.endsAt!),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(AdminBannerModel banner) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      children: [
        IconButton(
          tooltip: banner.isActive ? 'Deactivate' : 'Activate',
          onPressed: () => _toggleActive(banner),
          icon: Icon(
            banner.isActive
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
        IconButton(
          tooltip: 'Edit',
          onPressed: () => _openBannerForm(banner),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed: () => _deleteBanner(banner),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  // ==========================================================
  // Empty / Error
  // ==========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          children: [
            Icon(
              Icons.view_carousel_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'No banners found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first promotional banner.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52),
            const SizedBox(height: 12),
            const Text(
              'Unable to load banners',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadBanners,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${local.day}/${local.month}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

// ============================================================
// Summary Card
// ============================================================

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Status Chip
// ============================================================

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ============================================================
// Info Chip
// ============================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ============================================================
// Create / Edit Form
// ============================================================

class _BannerFormDialog extends StatefulWidget {
  final AdminBannerApi api;
  final AdminBannerModel? banner;

  const _BannerFormDialog({required this.api, this.banner});

  @override
  State<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<_BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _redirectUrlController;
  late final TextEditingController _displayOrderController;
  late final TextEditingController _campaignController;
  late final TextEditingController _priorityController;

  bool _isActive = true;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _saving = false;

  bool get _isEditing => widget.banner != null;

  @override
  void initState() {
    super.initState();

    final banner = widget.banner;

    _titleController = TextEditingController(text: banner?.title ?? '');

    _subtitleController = TextEditingController(text: banner?.subtitle ?? '');

    _imageUrlController = TextEditingController(text: banner?.imageUrl ?? '');

    _redirectUrlController = TextEditingController(
      text: banner?.redirectUrl ?? '',
    );

    _displayOrderController = TextEditingController(
      text: (banner?.displayOrder ?? 0).toString(),
    );

    _campaignController = TextEditingController(
      text: banner?.campaignName ?? '',
    );

    _priorityController = TextEditingController(
      text: (banner?.priority ?? 0).toString(),
    );

    _isActive = banner?.isActive ?? true;
    _startsAt = banner?.startsAt;
    _endsAt = banner?.endsAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _imageUrlController.dispose();
    _redirectUrlController.dispose();
    _displayOrderController.dispose();
    _campaignController.dispose();
    _priorityController.dispose();

    super.dispose();
  }

  // ==========================================================
  // Save
  // ==========================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startsAt != null && _endsAt != null && _endsAt!.isBefore(_startsAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final title = _titleController.text.trim();

      final subtitle = _nullableValue(_subtitleController.text);

      final imageUrl = _imageUrlController.text.trim();

      final redirectUrl = _nullableValue(_redirectUrlController.text);

      final campaignName = _nullableValue(_campaignController.text);

      final displayOrder = int.tryParse(_displayOrderController.text) ?? 0;

      final priority = int.tryParse(_priorityController.text) ?? 0;

      if (_isEditing) {
        await widget.api.updateBanner(
          id: widget.banner!.id,
          title: title,
          subtitle: subtitle,
          imageUrl: imageUrl,
          redirectUrl: redirectUrl,
          displayOrder: displayOrder,
          isActive: _isActive,
          startsAt: _startsAt,
          endsAt: _endsAt,
          campaignName: campaignName,
          priority: priority,
        );
      } else {
        await widget.api.createBanner(
          title: title,
          subtitle: subtitle,
          imageUrl: imageUrl,
          redirectUrl: redirectUrl,
          displayOrder: displayOrder,
          isActive: _isActive,
          startsAt: _startsAt,
          endsAt: _endsAt,
          campaignName: campaignName,
          priority: priority,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save banner: $e')));
    }
  }

  String? _nullableValue(String value) {
    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  // ==========================================================
  // Date Picker
  // ==========================================================

  Future<void> _pickStartDate() async {
    final date = await _pickDateTime(initialDate: _startsAt ?? DateTime.now());

    if (date != null) {
      setState(() {
        _startsAt = date;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final date = await _pickDateTime(
      initialDate: _endsAt ?? (_startsAt ?? DateTime.now()),
    );

    if (date != null) {
      setState(() {
        _endsAt = date;
      });
    }
  }

  Future<DateTime?> _pickDateTime({required DateTime initialDate}) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initialDate,
    );

    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Banner' : 'Create Banner'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(
                  controller: _titleController,
                  label: 'Title',
                  requiredField: true,
                ),
                _textField(
                  controller: _subtitleController,
                  label: 'Subtitle',
                  maxLines: 2,
                ),
                _textField(
                  controller: _imageUrlController,
                  label: 'Image URL',
                  requiredField: true,
                  keyboardType: TextInputType.url,
                ),
                _textField(
                  controller: _redirectUrlController,
                  label: 'Redirect URL',
                  keyboardType: TextInputType.url,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _displayOrderController,
                        label: 'Display Order',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        controller: _priorityController,
                        label: 'Priority',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                _textField(
                  controller: _campaignController,
                  label: 'Campaign Name',
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                ),
                const SizedBox(height: 8),
                _dateSelector(
                  label: 'Start Date',
                  value: _startsAt,
                  onPressed: _pickStartDate,
                  onClear: _startsAt == null
                      ? null
                      : () {
                          setState(() {
                            _startsAt = null;
                          });
                        },
                ),
                _dateSelector(
                  label: 'End Date',
                  value: _endsAt,
                  onPressed: _pickEndDate,
                  onClear: _endsAt == null
                      ? null
                      : () {
                          setState(() {
                            _endsAt = null;
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: !_saving,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: requiredField
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

  Widget _dateSelector({
    required String label,
    required DateTime? value,
    required VoidCallback onPressed,
    required VoidCallback? onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving ? null : onPressed,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value == null ? label : '$label: ${_formatDate(value)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'Clear',
              onPressed: _saving ? null : onClear,
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${local.day}/${local.month}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}
