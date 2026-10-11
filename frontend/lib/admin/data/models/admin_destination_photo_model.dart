class AdminDestinationPhotoModel {
  final String id;
  final String destinationId;
  final String imageUrl;
  final String? caption;
  final int displayOrder;
  final bool isCover;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminDestinationPhotoModel({
    required this.id,
    required this.destinationId,
    required this.imageUrl,
    this.caption,
    required this.displayOrder,
    required this.isCover,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminDestinationPhotoModel.fromJson(Map<String, dynamic> json) {
    return AdminDestinationPhotoModel(
      id: json['id'] as String,
      destinationId: json['destination_id'] as String,
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isCover: json['is_cover'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
