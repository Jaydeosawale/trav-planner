import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../places/presentation/widgets/place_card.dart';
import '../../../places/data/place_catalogue.dart';
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
  bool _editingLocation = false, _filtering = false;
  String? _coverageNote;
  String get _areaLabel {
    if (_location != 'Your selected current location') return _location;
    final city = (_items ?? [])
        .map((item) => item['city_name']?.toString())
        .whereType<String>()
        .where((name) => name.isNotEmpty && name != 'Nearby')
        .firstOrNull;
    return city == null ? 'Saved GPS area' : 'Near $city';
  }

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
    final area = ref.read(chosenPlaceAreaProvider);
    final savedGps = ref.read(nearbyOriginProvider);
    if (_origin == null &&
        !widget.useCurrentLocation &&
        area == null &&
        savedGps != null) {
      _origin = savedGps;
      _location = 'Your selected current location';
    }
    if (_origin == null && !widget.useCurrentLocation && area != null) {
      final point = validCoordinates(area.latitude, area.longitude);
      if (point != null) {
        _origin = point;
        _location = area.name;
      }
    }
    if (widget.useCurrentLocation || _origin != null) {
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
    if (_query.text.trim().length < 2) {
      setState(() => _notice = 'Enter at least two letters to find a town.');
      return;
    }
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
              'country_id': area.countryId,
              'region_name': area.regionName,
              'latitude': area.latitude,
              'longitude': area.longitude,
            },
          )
          .toList();
      if (mounted && result.notice != null) {
        setState(() => _notice = result.notice);
      }
      if (mounted) {
        setState(() {
          _cities = rows;
          if (rows.isEmpty) _notice = 'No towns matched. Try another name.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Couldn’t find locations. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(Map<String, dynamic> c) async {
    if (!await ensureSignedIn(context, ref) || !mounted) return;
    final countryName = c['country']?.toString() ?? '';
    final regionName = c['region_name']?.toString() ?? '';
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
    if (!mounted) return;
    final point = validCoordinates(c['latitude'], c['longitude']);
    if (point == null) {
      setState(() => _notice = 'This location needs verified coordinates.');
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() {
      _origin = point;
      _location = c['name'].toString();
      _cities = [];
      _editingLocation = false;
      _items = null;
      _filter = '';
      _filtering = false;
    });
    ref.read(chosenPlaceAreaProvider.notifier).state = PlaceArea(
      cityId: c['id']?.toString(),
      name: _location,
      countryId: c['country_id']?.toString(),
      countryName: countryName,
      regionName: regionName,
      latitude: point.latitude,
      longitude: point.longitude,
    );
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
      ScaffoldMessenger.of(context).clearSnackBars();
      ref.read(chosenPlaceAreaProvider.notifier).state = null;
      ref.read(nearbyOriginProvider.notifier).state = LatLng(
        p.latitude,
        p.longitude,
      );
      setState(() {
        _origin = LatLng(p.latitude, p.longitude);
        _location = 'Your selected current location';
        _cities = [];
        _editingLocation = false;
        _items = null;
        _filter = '';
        _filtering = false;
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
          _notice = null;
          _coverageNote =
              '${r.data['message'] ?? ''}\n${r.data['distance_note'] ?? ''}';
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

  static const _categories = {
    'all': 'All places',
    'attraction': 'Sights',
    'restaurant': 'Food',
    'cafe': 'Cafés',
    'park': 'Parks',
    'museum': 'Museums',
    'hotel': 'Stays',
    'beach': 'Beaches',
    'viewpoint': 'Views',
    'station': 'Stations',
    'bus_stop': 'Bus stops',
    'airport': 'Airports',
    'parking': 'Parking',
    'shop': 'Shopping',
    'pharmacy': 'Pharmacies',
    'hospital': 'Hospitals',
    'worship': 'Places of worship',
    'toilet': 'Public toilets',
    'charging': 'EV charging',
    'heritage': 'Heritage',
  };

  Future<void> _changeKind(String kind) async {
    if (_busy || kind == _kind) return;
    setState(() {
      _kind = kind;
      _items = null;
      _filter = '';
      _filtering = false;
    });
    if (_origin != null) await _search();
  }

  Future<void> _filters() async {
    var kind = _kind;
    var radius = _radius;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, update) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nearby filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: kind,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Type of place'),
                items: _categories.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (value) => update(() => kind = value!),
              ),
              const SizedBox(height: 20),
              const Text(
                'Distance',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in [2.0, 5.0, 10.0, 20.0])
                    ChoiceChip(
                      label: Text('${value.toInt()} km'),
                      selected: radius == value,
                      onSelected: (_) => update(() => radius = value),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Show places'),
              ),
            ],
          ),
        ),
      ),
    );
    if (apply != true || !mounted || (kind == _kind && radius == _radius)) {
      return;
    }
    setState(() {
      _kind = kind;
      _radius = radius;
      _items = null;
      _filter = '';
      _filtering = false;
    });
    if (_origin != null) await _search();
  }

  void _details() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'About nearby places',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            _coverageNote?.trim().isNotEmpty == true
                ? _coverageNote!
                : 'Results use stored listings and public town centres. Coverage may be incomplete.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Distances are straight-line estimates. Check opening hours and availability before visiting. Opening Google Maps shares the selected area or approximate location with Google.',
          ),
          const SizedBox(height: 12),
          PlaceSourceCredit(data: _items),
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
      ),
    ),
  );

  Widget _placeRow(Map<String, dynamic> item) {
    final place = TravelPlace.fromJson(item);
    final distance = double.tryParse('${item['distance_km']}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: place.imageUrl?.isNotEmpty == true
                        ? PlacePhoto(place: place)
                        : const ColoredBox(
                            color: AppColors.surfaceVariant,
                            child: Icon(
                              Icons.place_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          placeTypeLabel(place.type),
                          if (distance != null)
                            '${distance.toStringAsFixed(distance < 1 ? 1 : 0)} km away',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider.select((state) => state.user?.id), (
      previous,
      next,
    ) {
      if (previous == next) return;
      setState(() {
        _origin = null;
        _items = null;
        _cities = [];
        _location = '';
        _notice = null;
        _editingLocation = false;
      });
    });
    ref.listen(nearbyOriginProvider, (_, point) {
      if (_origin != null || point == null || _busy || _editingLocation) return;
      setState(() {
        _origin = point;
        _location = 'Your selected current location';
      });
      _search();
    });
    ref.listen(chosenPlaceAreaProvider, (_, area) {
      if (_origin != null || area == null || _busy || _editingLocation) return;
      final point = validCoordinates(area.latitude, area.longitude);
      if (point == null) return;
      setState(() {
        _origin = point;
        _location = area.name;
      });
      _search();
    });
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Places nearby'),
        actions: [
          IconButton(
            tooltip: 'About nearby places',
            onPressed: _details,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_origin != null && !_editingLocation)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _areaLabel,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _editingLocation = true),
                          child: const Text('Change'),
                        ),
                      ],
                    )
                  else ...[
                    if (_origin == null) ...[
                      const Text(
                        'Where are you exploring?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: _query,
                      enabled: !_busy,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search a town or area',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: IconButton(
                          tooltip: 'Find location',
                          onPressed: _busy ? null : _citiesSearch,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                      onSubmitted: (_) => _citiesSearch(),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _gps,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Use my location'),
                      ),
                    ),
                    for (final city in _cities)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_city_outlined),
                        title: Text(city['name'].toString()),
                        subtitle: Text(
                          [city['region_name'], city['country']]
                              .where(
                                (v) => v != null && v.toString().isNotEmpty,
                              )
                              .join(' · '),
                        ),
                        onTap: _busy ? null : () => _choose(city),
                      ),
                    if (_origin != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => setState(() {
                            _editingLocation = false;
                            _cities = [];
                          }),
                          child: const Text('Keep current area'),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final kind in [
                          'all',
                          'restaurant',
                          'cafe',
                          'park',
                          'attraction',
                          'hotel',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_categories[kind]!),
                              selected: _kind == kind,
                              onSelected: _busy
                                  ? null
                                  : (_) => _changeKind(kind),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _categories[_kind] ?? 'Places',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _busy ? null : _filters,
                        icon: const Icon(Icons.tune, size: 17),
                        label: Text('${_radius.toInt()} km · Filters'),
                      ),
                    ],
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (_notice != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _notice!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (_origin != null)
                            TextButton(
                              onPressed: _busy ? null : _search,
                              child: const Text('Retry'),
                            ),
                        ],
                      ),
                    ),
                  if (_items != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_filtered.length} ${_filtered.length == 1 ? 'place' : 'places'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (_items!.isNotEmpty)
                          IconButton(
                            tooltip: 'Filter results',
                            onPressed: () => setState(() {
                              _filtering = !_filtering;
                              if (!_filtering) _filter = '';
                            }),
                            icon: const Icon(Icons.search, size: 20),
                          ),
                        IconButton(
                          tooltip: _map ? 'Show list' : 'Show map',
                          onPressed: () => setState(() => _map = !_map),
                          icon: Icon(
                            _map
                                ? Icons.view_list_outlined
                                : Icons.map_outlined,
                            size: 21,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open area in Google Maps',
                          onPressed: _busy ? null : _maps,
                          icon: const Icon(Icons.open_in_new, size: 20),
                        ),
                      ],
                    ),
                    if (_filtering)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Filter these results',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) => setState(() => _filter = v),
                        ),
                      ),
                    if (_filtered.isEmpty && !_busy)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.explore_outlined,
                              size: 40,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _items!.isEmpty
                                  ? 'No places found here yet'
                                  : 'No matching places',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _items!.isEmpty &&
                                      _coverageNote?.trim().isNotEmpty == true
                                  ? _coverageNote!.split('\n').first
                                  : 'Try another name or a wider area.',
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_items!.isEmpty)
                              TextButton(
                                onPressed: _details,
                                child: const Text('Coverage details'),
                              ),
                          ],
                        ),
                      )
                    else if (_map)
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
                      for (final item in _filtered) _placeRow(item),
                    const SizedBox(height: 8),
                    const Text(
                      'Approximate distances · Coverage may be incomplete',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    PlaceSourceCredit(data: _items),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Text(
                          '© OpenStreetMap',
                          style: TextStyle(fontSize: 11),
                        ),
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
}
