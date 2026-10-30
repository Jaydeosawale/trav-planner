import '../../../places/data/nearby_origin.dart';
import '../../../../app/router/navigation_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/widgets/require_sign_in.dart';
import '../../../../core/widgets/place_source_credit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../places/data/current_location.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/network/api_client.dart';
import '../../../places/data/place_area.dart';
import '../../../destinations/data/place.dart';
import '../../../maps/places_map.dart';

class NearbyPlacesPage extends ConsumerStatefulWidget {
  const NearbyPlacesPage({
    super.key,
    this.client,
    this.initialKind = 'all',
    this.initialOrigin,
    this.useCurrentLocation = false,
  });
  final String initialKind;
  final LatLng? initialOrigin;
  final bool useCurrentLocation;
  final Dio? client;
  @override
  ConsumerState<NearbyPlacesPage> createState() => _NearbyPlacesPageState();
}

class _NearbyPlacesPageState extends ConsumerState<NearbyPlacesPage> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>>? _items;
  LatLng? _origin;
  String _location = '';
  late String _kind = widget.initialKind;
  double _radius = 5;
  bool _busy = false, _map = false;
  String? _notice;
  String _filter = '';
  List<Map<String, dynamic>> get _filtered => (_items ?? [])
      .where(
        (p) => '${p['name']} ${p['place_type']} ${p['description'] ?? ''}'
            .toLowerCase()
            .contains(_filter.toLowerCase().trim()),
      )
      .toList();
  Dio get _client => widget.client ?? ApiClient.dio;
  @override
  void initState() {
    super.initState();
    if (widget.initialOrigin != null) {
      _origin = widget.initialOrigin;
      _location = 'Your selected current location';
    }
    if (widget.useCurrentLocation || widget.initialOrigin != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.useCurrentLocation) {
          _gps();
        } else {
          _search();
        }
      });
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _citiesSearch() async {
    if (_query.text.trim().length < 2) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final result = await PlaceAreaApi(
        client: _client,
      ).search(_query.text.trim());
      final rows = result.items
          .map(
            (area) => <String, dynamic>{
              'id': area.cityId,
              'source_id': area.sourceId,
              'name': area.name,
              'country': area.countryName,
              'region_name': area.regionName,
              'latitude': area.latitude,
              'longitude': area.longitude,
            },
          )
          .toList();
      if (mounted && result.notice != null) {
        setState(() => _notice = result.notice);
      }
      if (mounted) setState(() => _cities = rows);
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Couldn’t find locations. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(Map<String, dynamic> c) async {
    if (c['source_id'] != null) {
      if (!await ensureSignedIn(context, ref)) return;
      if (!mounted) return;
      try {
        c = Map<String, dynamic>.from(
          (await _client.post(
            '/discovery/locations/${c['source_id']}/open',
          )).data,
        );
      } catch (_) {
        if (mounted) setState(() => _notice = 'Couldn’t open this location.');
        return;
      }
    }
    final point = validCoordinates(c['latitude'], c['longitude']);
    if (point == null) {
      setState(() => _notice = 'This location needs verified coordinates.');
      return;
    }
    setState(() {
      _origin = point;
      _location = c['name'].toString();
      _cities = [];
    });
    await _search();
  }

  Future<void> _gps() async {
    if (_busy) return;
    if (!await ensureSignedIn(context, ref) || !mounted) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final p = await ref.read(currentLocationServiceProvider).request();
      if (!mounted) return;
      ref.read(chosenPlaceAreaProvider.notifier).state = null;
      ref.read(nearbyOriginProvider.notifier).state = LatLng(
        p.latitude,
        p.longitude,
      );
      setState(() {
        _origin = LatLng(p.latitude, p.longitude);
        _location = 'Your selected current location';
        _cities = [];
      });
      await _search();
    } catch (error) {
      if (mounted) {
        final failure = error is LocationAccessFailure
            ? error
            : const LocationAccessFailure(
                'Location is unavailable. Try again or enter a town.',
              );
        setState(() => _notice = failure.message);
        if (failure.openSettings || failure.deviceLocationSettings) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => failure.deviceLocationSettings
                    ? ref
                          .read(currentLocationServiceProvider)
                          .openDeviceSettings()
                    : ref.read(currentLocationServiceProvider).openSettings(),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _search() async {
    if (_origin == null) return;
    if (!await ensureSignedIn(context, ref)) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final r = await _client.post(
        '/discovery/nearby',
        data: {
          'latitude': _origin!.latitude,
          'longitude': _origin!.longitude,
          'radius_km': _radius,
          'kind': _kind,
        },
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      );
      if (mounted) {
        setState(() {
          _items = (r.data['items'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _notice = '${r.data['message']}\n${r.data['distance_note']}';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _notice =
              error is DioException && error.response?.statusCode == 401
              ? 'Sign in to search nearby. Your chosen area is kept.'
              : 'Nearby places couldn’t load. Your area and filters are kept; try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _maps() async {
    final target = _location == 'Your selected current location'
        ? '${_origin!.latitude.toStringAsFixed(3)}, ${_origin!.longitude.toStringAsFixed(3)}'
        : _location;
    final query =
        '${_kind == 'all'
            ? 'places'
            : _kind == 'hotel'
            ? 'hotels'
            : _kind} near $target';
    try {
      if (!await launchUrl(
        Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': query,
        }),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception();
      }
    } catch (_) {
      if (mounted) setState(() => _notice = 'Couldn’t open Google Maps.');
    }
  }

  void _open(Map<String, dynamic> item) {
    final p = TravelPlace.fromJson(item);
    openPlace(context, p);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Places nearby')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'A little closer to you.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose a town or use your location. Local discovery checks known public town centres; coverage and business details may be incomplete.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _query,
                  decoration: const InputDecoration(labelText: 'City or area'),
                  onSubmitted: (_) => _citiesSearch(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _citiesSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('Find location'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _gps,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use my location'),
                    ),
                  ],
                ),
                for (final c in _cities)
                  ListTile(
                    title: Text(c['name'].toString()),
                    subtitle: Text(
                      [c['region_name'], c['country']]
                          .where((v) => v != null && v.toString().isNotEmpty)
                          .join(' · '),
                    ),
                    onTap: _busy ? null : () => _choose(c),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'Looking for'),
                  items:
                      const {
                            'all': 'All places',
                            'attraction': 'Attractions',
                            'museum': 'Museums',
                            'park': 'Parks',
                            'restaurant': 'Restaurants',
                            'cafe': 'Cafés',
                            'hotel': 'Stays',
                            'station': 'Stations',
                            'bus_stop': 'Bus stops',
                            'airport': 'Airports',
                            'parking': 'Parking',
                            'shop': 'Shopping',
                            'pharmacy': 'Pharmacies',
                            'hospital': 'Hospitals & clinics',
                            'worship': 'Places of worship',
                            'toilet': 'Public toilets',
                            'viewpoint': 'Viewpoints',
                            'charging': 'EV charging',
                            'beach': 'Beaches',
                            'heritage': 'Heritage',
                          }.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                          _kind = v!;
                          _items = null;
                          _notice = 'Search to update this category.';
                        }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<double>(
                  initialValue: _radius,
                  decoration: const InputDecoration(labelText: 'Search radius'),
                  items: [2.0, 5.0, 10.0, 20.0]
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text('${r.toInt()} km'),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (r) => setState(() {
                          _radius = r!;
                          _items = null;
                          _notice = 'Search to update this radius.';
                        }),
                ),
                if (_origin != null) ...[
                  const SizedBox(height: 12),
                  Text('Around $_location'),
                  FilledButton(
                    onPressed: _busy ? null : _search,
                    child: const Text('Search nearby'),
                  ),
                ],
                if (_busy) const LinearProgressIndicator(),
                if (_notice != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_notice!),
                  ),
                if (_origin != null) ...[
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _maps,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Search this area on Google Maps'),
                  ),
                  const Text(
                    'Opens Google Maps with the chosen area or approximate location. Its listings and availability are managed by Google.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
                PlaceSourceCredit(data: _items),
                if (_items != null) ...[
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('OpenStreetMap contributors · ODbL'),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://overpass.kumi.systems/'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('Open-map service & privacy'),
                  ),
                ],
                if (_items != null && _items!.isNotEmpty) ...[
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Filter these results',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('List')),
                      ButtonSegment(value: true, label: Text('Map')),
                    ],
                    selected: {_map},
                    onSelectionChanged: (v) => setState(() => _map = v.first),
                  ),
                  const SizedBox(height: 12),
                  if (_map)
                    SizedBox(
                      height: 350,
                      child: PlacesMap(
                        places: _filtered.map(TravelPlace.fromJson).toList(),
                        center: _origin,
                        onSelect: (p) =>
                            _open(_items!.firstWhere((i) => i['id'] == p.id)),
                      ),
                    )
                  else
                    for (final p in _filtered)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(p['name'].toString()),
                          subtitle: Text(
                            '${p['place_type']} · ${p['distance_km']} km straight-line',
                          ),
                          onTap: () => _open(p),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
