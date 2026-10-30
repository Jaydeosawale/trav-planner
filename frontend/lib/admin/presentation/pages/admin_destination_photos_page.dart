import 'package:trav_planner/core/widgets/full_photo_frame.dart';
import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../data/datasources/admin_destination_photo_api.dart';
import '../../data/models/admin_destination_model.dart';
import '../../data/models/admin_destination_photo_model.dart';

class AdminDestinationPhotosPage extends StatefulWidget {
  final AdminDestinationModel destination;

  const AdminDestinationPhotosPage({super.key, required this.destination});

  @override
  State<AdminDestinationPhotosPage> createState() =>
      _AdminDestinationPhotosPageState();
}

class _AdminDestinationPhotosPageState
    extends State<AdminDestinationPhotosPage> {
  final AdminDestinationPhotoApi _api = AdminDestinationPhotoApi();

  List<AdminDestinationPhotoModel> _photos = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  // ==========================================================
  // Load
  // ==========================================================

  Future<void> _loadPhotos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final photos = await _api.getPhotos(widget.destination.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _photos = photos;
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
  // Add / Edit
  // ==========================================================

  Future<void> _openPhotoForm({AdminDestinationPhotoModel? photo}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return _PhotoFormDialog(
          destinationId: widget.destination.id,
          photo: photo,
          api: _api,
        );
      },
    );

    if (result == true) {
      await _loadPhotos();
    }
  }

  // ==========================================================
  // Delete
  // ==========================================================

  Future<void> _deletePhoto(AdminDestinationPhotoModel photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete photo?'),
          content: const Text(
            'This photo will be removed from the destination gallery.',
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
      await _api.deletePhoto(photo.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted successfully.')),
      );

      await _loadPhotos();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString());
    }
  }

  // ==========================================================
  // Toggle active
  // ==========================================================

  Future<void> _toggleActive(AdminDestinationPhotoModel photo) async {
    try {
      await _api.updatePhoto(photoId: photo.id, isActive: !photo.isActive);

      await _loadPhotos();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString());
    }
  }

  // ==========================================================
  // Set cover
  // ==========================================================

  Future<void> _setCover(AdminDestinationPhotoModel photo) async {
    try {
      await _api.updatePhoto(photoId: photo.id, isCover: true);

      await _loadPhotos();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString());
    }
  }

  // ==========================================================
  // Error
  // ==========================================================

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.destination.name} • Photos'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadPhotos,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openPhotoForm();
        },
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add Photo'),
      ),
    );
  }

  // ==========================================================
  // Body
  // ==========================================================

  Widget _buildBody() {
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
                'Unable to load photos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: _loadPhotos, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_photos.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: 350,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        return _buildPhotoCard(_photos[index]);
      },
    );
  }

  // ==========================================================
  // Photo Card
  // ==========================================================

  Widget _buildPhotoCard(AdminDestinationPhotoModel photo) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
                child: FullPhotoFrame(
                  image: Image.network(
                    photo.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) {
                      return _imagePlaceholder();
                    },
                  ),
                ),
              ),

              if (photo.isCover)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _badge(icon: Icons.star_rounded, label: 'Cover'),
                ),

              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  color: AppColors.textPrimary,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _openPhotoForm(photo: photo);
                        break;

                      case 'cover':
                        _setCover(photo);
                        break;

                      case 'active':
                        _toggleActive(photo);
                        break;

                      case 'delete':
                        _deletePhoto(photo);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    if (!photo.isCover)
                      const PopupMenuItem(
                        value: 'cover',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.star_outline_rounded),
                          title: Text('Set as cover'),
                        ),
                      ),
                    PopupMenuItem(
                      value: 'active',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          photo.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        title: Text(photo.isActive ? 'Deactivate' : 'Activate'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.caption?.isNotEmpty == true
                        ? photo.caption!
                        : 'No caption',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Icon(
                        photo.isActive
                            ? Icons.check_circle_rounded
                            : Icons.pause_circle_rounded,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        photo.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Order ${photo.displayOrder}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
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

  Widget _badge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.border,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ==========================================================
  // Empty
  // ==========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 72,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 18),
          const Text(
            'No destination photos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos to showcase this destination.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {
              _openPhotoForm();
            },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add First Photo'),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// Photo Form
// ==========================================================

class _PhotoFormDialog extends StatefulWidget {
  final String destinationId;
  final AdminDestinationPhotoModel? photo;
  final AdminDestinationPhotoApi api;

  const _PhotoFormDialog({
    required this.destinationId,
    required this.photo,
    required this.api,
  });

  @override
  State<_PhotoFormDialog> createState() => _PhotoFormDialogState();
}

class _PhotoFormDialogState extends State<_PhotoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _imageController;
  late final TextEditingController _captionController;
  late final TextEditingController _orderController;

  bool _isCover = false;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.photo != null;

  @override
  void initState() {
    super.initState();

    final photo = widget.photo;

    _imageController = TextEditingController(text: photo?.imageUrl ?? '');

    _captionController = TextEditingController(text: photo?.caption ?? '');

    _orderController = TextEditingController(
      text: photo?.displayOrder.toString() ?? '0',
    );

    _isCover = photo?.isCover ?? false;
    _isActive = photo?.isActive ?? true;
  }

  @override
  void dispose() {
    _imageController.dispose();
    _captionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final displayOrder = int.tryParse(_orderController.text.trim()) ?? 0;

    try {
      if (_isEditing) {
        await widget.api.updatePhoto(
          photoId: widget.photo!.id,
          imageUrl: _imageController.text.trim(),
          caption: _captionController.text.trim(),
          displayOrder: displayOrder,
          isCover: _isCover,
          isActive: _isActive,
        );
      } else {
        await widget.api.addPhoto(
          destinationId: widget.destinationId,
          imageUrl: _imageController.text.trim(),
          caption: _captionController.text.trim().isEmpty
              ? null
              : _captionController.text.trim(),
          displayOrder: displayOrder,
          isCover: _isCover,
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Destination Photo' : 'Add Destination Photo',
      ),
      content: SizedBox(
        width: 550,
        height: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _imageController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Image URL is required';
                    }

                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _captionController,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Caption',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Display order',
                    helperText: 'Lower numbers appear first.',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cover photo'),
                  subtitle: const Text(
                    'Use this as the primary gallery image.',
                  ),
                  value: _isCover,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _isCover = value;
                          });
                        },
                ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Show this photo to users.'),
                  value: _isActive,
                  onChanged: _saving
                      ? null
                      : (value) {
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
}
