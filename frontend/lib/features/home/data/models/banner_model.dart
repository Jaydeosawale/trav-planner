class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? redirectUrl;
  final int displayOrder;
  final bool isActive;

  const BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.redirectUrl,
    required this.displayOrder,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      redirectUrl: json['redirect_url'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
