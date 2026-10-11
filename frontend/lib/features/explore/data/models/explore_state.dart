class ExploreState {
  final String id;
  final String countryId;
  final String name;
  final String code;
  final bool isActive;

  const ExploreState({
    required this.id,
    required this.countryId,
    required this.name,
    required this.code,
    required this.isActive,
  });

  factory ExploreState.fromJson(Map<String, dynamic> json) {
    return ExploreState(
      id: json['id']?.toString() ?? '',
      countryId: json['country_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
