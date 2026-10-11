class AdminBannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? redirectUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? campaignName;
  final int priority;

  const AdminBannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.redirectUrl,
    required this.displayOrder,
    required this.isActive,
    this.startsAt,
    this.endsAt,
    this.campaignName,
    required this.priority,
  });

  factory AdminBannerModel.fromJson(Map<String, dynamic> json) {
    return AdminBannerModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      redirectUrl: json['redirect_url'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startsAt: _parseDateTime(json['starts_at']),
      endsAt: _parseDateTime(json['ends_at']),
      campaignName: json['campaign_name'] as String?,
      priority: json['priority'] as int? ?? 0,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
