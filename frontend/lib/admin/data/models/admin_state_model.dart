class AdminStateModel {
  final String id;
  final String countryId;
  final String name;
  final String code;
  final bool isActive;

  const AdminStateModel({
    required this.id,
    required this.countryId,
    required this.name,
    required this.code,
    required this.isActive,
  });

  factory AdminStateModel.fromJson(Map<String, dynamic> json) {
    return AdminStateModel(
      id: json['id'] as String,
      countryId: json['country_id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
