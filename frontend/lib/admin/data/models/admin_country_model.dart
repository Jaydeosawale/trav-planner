class AdminCountryModel {
  final String id;
  final String name;
  final String iso2;
  final String? iso3;
  final String? flagUrl;
  final String? capital;
  final String? currency;
  final String? phoneCode;
  final String? continent;
  final String? timezone;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  const AdminCountryModel({
    required this.id,
    required this.name,
    required this.iso2,
    this.iso3,
    this.flagUrl,
    this.capital,
    this.currency,
    this.phoneCode,
    this.continent,
    this.timezone,
    this.latitude,
    this.longitude,
    required this.isActive,
  });

  factory AdminCountryModel.fromJson(Map<String, dynamic> json) {
    return AdminCountryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iso2: json['iso2']?.toString() ?? '',
      iso3: json['iso3']?.toString(),
      flagUrl: json['flag_url']?.toString(),
      capital: json['capital']?.toString(),
      currency: json['currency']?.toString(),
      phoneCode: json['phone_code']?.toString(),
      continent: json['continent']?.toString(),
      timezone: json['timezone']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
