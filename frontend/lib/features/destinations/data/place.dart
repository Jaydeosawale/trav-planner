import 'dart:convert';
import 'package:latlong2/latlong.dart';

LatLng? validCoordinates(dynamic latitude, dynamic longitude) {
  final lat = double.tryParse(latitude?.toString() ?? '');
  final lon = double.tryParse(longitude?.toString() ?? '');
  if (lat == null ||
      lon == null ||
      !lat.isFinite ||
      !lon.isFinite ||
      lat < -90 ||
      lat > 90 ||
      lon < -180 ||
      lon > 180) {
    return null;
  }
  return LatLng(lat, lon);
}

class TravelPlace {
  final String id, name, type;
  final String? cityId;
  final String? description, address, imageUrl;
  final LatLng? point;
  final bool featured;
  final bool discovered;
  final String? visitingNotes;
  final Map<String, dynamic>? imageCredit;
  final Uri? source;

  const TravelPlace({
    required this.id,
    required this.name,
    required this.type,
    this.cityId,
    this.description,
    this.address,
    this.imageUrl,
    this.point,
    this.featured = false,
    this.discovered = false,
    this.source,
    this.visitingNotes,
    this.imageCredit,
  });

  TravelPlace withPhoto(TravelPlace photo) => TravelPlace(
    id: id,
    name: name,
    type: type,
    cityId: cityId,
    description: description,
    address: address,
    imageUrl: photo.imageUrl ?? imageUrl,
    point: point,
    featured: featured,
    discovered: discovered,
    source: source,
    visitingNotes: visitingNotes,
    imageCredit: photo.imageCredit ?? imageCredit,
  );

  factory TravelPlace.fromJson(Map<String, dynamic> json) => TravelPlace(
    id: json['id'].toString(),
    cityId: json['city_id']?.toString(),
    name: json['name']?.toString() ?? 'Place',
    type: json['place_type']?.toString() ?? 'attraction',
    description: (json['description'] ?? json['short_description'])?.toString(),
    address: json['address']?.toString(),
    imageUrl: json['image_url']?.toString(),
    point: validCoordinates(json['latitude'], json['longitude']),
    featured: json['is_featured'] == true,
    discovered: json['is_discovery'] == true,
    visitingNotes: json['visiting_notes']?.toString(),
    imageCredit: _credits(json['image_credit']),
    source:
        json['provider'] == 'wikidata' &&
            RegExp(
              r'^Q[1-9][0-9]*$',
            ).hasMatch(json['external_place_id']?.toString() ?? '')
        ? Uri.https('www.wikidata.org', '/wiki/${json['external_place_id']}')
        : json['provider'] == 'osm' &&
              RegExp(
                r'^(node|way|relation)/[0-9]+$',
              ).hasMatch(json['external_place_id']?.toString() ?? '')
        ? Uri.https('www.openstreetmap.org', '/${json['external_place_id']}')
        : null,
  );
}

Map<String, dynamic>? _credits(dynamic value) {
  try {
    final decoded = value is String ? jsonDecode(value) : value;
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } catch (_) {
    return null;
  }
}
