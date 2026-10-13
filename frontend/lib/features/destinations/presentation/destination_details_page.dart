import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../maps/places_map.dart';
import '../data/place.dart';
import '../data/places_provider.dart';
import '../../saved/presentation/save_place_button.dart';

class DestinationDetailsPage extends ConsumerStatefulWidget {
  final String cityId, name;
  final String? description, imageUrl;
  final LatLng? center;
  final TravelPlace? initialPlace;
  final Dio? discoveryClient;
  const DestinationDetailsPage({
    super.key,
    required this.cityId,
    required this.name,
    this.description,
    this.imageUrl,
    this.center,
    this.initialPlace,
    this.discoveryClient,
  });

  @override
  ConsumerState<DestinationDetailsPage> createState() =>
      _DestinationDetailsPageState();
}

class _DestinationDetailsPageState
    extends ConsumerState<DestinationDetailsPage> {
  String _filter = 'All';
  String _discoveryKind = 'attraction';
  bool _discovering = false;
  String? _discoveryNotice;
  List<TravelPlace> _discovered = [];
  TravelPlace? _selected;
  bool _mapMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlace != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPlace(widget.initialPlace!);
      });
    }
  }

  Future<void> _discover() async {
    if (_discovering) return;
    setState(() => _discovering = true);
    try {
      final response = await (widget.discoveryClient ?? ApiClient.dio).get(
        '/discovery/cities/${widget.cityId}',
        queryParameters: {'kind': _discoveryKind},
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      );
      final data = response.data as Map;
      final items = (data['items'] as List? ?? [])
          .map((item) => TravelPlace.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (mounted) {
        setState(() {
          _discovered = {
            ...{for (final p in _discovered) p.id: p},
            ...{for (final p in items) p.id: p},
          }.values.toList();
          _discoveryNotice =
              data['message']?.toString() ?? 'Source-backed places loaded.';
          _filter = 'All';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _discoveryNotice =
              'Couldn’t load additional places. Sign in and try again later; known places are still available.',
        );
      }
    } finally {
      if (mounted) setState(() => _discovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(cityPlacesProvider(widget.cityId));
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cityPlacesProvider(widget.cityId));
          await ref.read(cityPlacesProvider(widget.cityId).future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.imageUrl?.isNotEmpty == true) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: _PlaceImage(url: widget.imageUrl, height: 240),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      'Find your kind of ${widget.name}.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.description?.isNotEmpty == true
                          ? widget.description!
                          : 'Explore places to visit in and around ${widget.name}.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        DropdownButton<String>(
                          value: _discoveryKind,
                          items: const [
                            DropdownMenuItem(
                              value: 'attraction',
                              child: Text('Attractions'),
                            ),
                            DropdownMenuItem(
                              value: 'museum',
                              child: Text('Museums'),
                            ),
                            DropdownMenuItem(
                              value: 'heritage',
                              child: Text('Monuments'),
                            ),
                            DropdownMenuItem(
                              value: 'park',
                              child: Text('Parks'),
                            ),
                            DropdownMenuItem(
                              value: 'beach',
                              child: Text('Beaches'),
                            ),
                            DropdownMenuItem(
                              value: 'restaurant',
                              child: Text('Restaurants'),
                            ),
                            DropdownMenuItem(
                              value: 'cafe',
                              child: Text('Cafés'),
                            ),
                            DropdownMenuItem(
                              value: 'hotel',
                              child: Text('Stays'),
                            ),
                            DropdownMenuItem(
                              value: 'station',
                              child: Text('Stations'),
                            ),
                            DropdownMenuItem(
                              value: 'bus_stop',
                              child: Text('Bus stops'),
                            ),
                            DropdownMenuItem(
                              value: 'airport',
                              child: Text('Airports'),
                            ),
                            DropdownMenuItem(
                              value: 'parking',
                              child: Text('Parking'),
                            ),
                            DropdownMenuItem(
                              value: 'shop',
                              child: Text('Shops'),
                            ),
                          ],
                          onChanged: _discovering
                              ? null
                              : (value) =>
                                    setState(() => _discoveryKind = value!),
                        ),
                        OutlinedButton.icon(
                          onPressed: _discovering ? null : _discover,
                          icon: const Icon(Icons.travel_explore),
                          label: Text(
                            _discovering
                                ? 'Discovering…'
                                : 'Discover more places',
                          ),
                        ),
                      ],
                    ),
                    if (_discoveryNotice != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _discoveryNotice!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    places.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'We couldn’t load the places. Please try again.',
                          ),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              cityPlacesProvider(widget.cityId),
                            ),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                      data: (items) => _buildPlaces(
                        {
                          ...{for (final p in _discovered) p.id: p},
                          ...{for (final p in items) p.id: p},
                        }.values.toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaces(List<TravelPlace> places) {
    final types = places.map((p) => p.type).toSet().toList()..sort();
    final visible = places
        .where((p) => _filter == 'All' || p.type == _filter)
        .toList();
    final selected = visible.where((p) => p.id == _selected?.id).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Places to discover',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.view_list_outlined),
                  label: Text('List'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.map_outlined),
                  label: Text('Map'),
                ),
              ],
              selected: {_mapMode},
              onSelectionChanged: (value) =>
                  setState(() => _mapMode = value.first),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (types.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', ...types]
                  .map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(type.replaceAll('_', ' ')),
                        selected: type == _filter,
                        onSelected: (_) => setState(() {
                          _filter = type;
                          _selected = null;
                        }),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 16),
        if (_mapMode) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: AppColors.surfaceVariant,
              height: 390,
              child: PlacesMap(
                places: visible,
                center: widget.center,
                selectedId: selected?.id,
                onSelect: (place) => setState(() => _selected = place),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (selected != null) _placeCard(selected),
        ] else
          ...visible.map(_placeCard),
        if (places.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Places for this destination are being added. Check back soon.',
            ),
          ),
        if (_mapMode && visible.any((p) => p.point == null))
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Some places are available in the list while their map locations are being added.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _placeCard(TravelPlace place) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _showPlace(place),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 82,
                child: _PlaceImage(url: place.imageUrl, height: 82),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.type.replaceAll('_', ' '),
                    style: const TextStyle(color: AppColors.secondary),
                  ),
                  if (place.address?.isNotEmpty == true)
                    Text(
                      place.address!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            SavePlaceButton(place: place, compact: true),
          ],
        ),
      ),
    ),
  );

  Future<void> _nearbyFood(TravelPlace place, BuildContext sheetContext) async {
    try {
      final response = await (widget.discoveryClient ?? ApiClient.dio).get(
        '/discovery/near/${place.id}',
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      );
      if (!mounted || !sheetContext.mounted) return;
      final data = response.data as Map;
      final items = data['items'] as List? ?? [];
      final selected = await showDialog<TravelPlace>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Nearby restaurants & cafés'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(data['message']?.toString() ?? 'Source data'),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Nearby food places haven’t been added for this area yet.',
                ),
              ),
            for (final item in items)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(
                  context,
                  TravelPlace.fromJson(Map<String, dynamic>.from(item)),
                ),
                child: Text(
                  '${item['name']} · ${item['distance_km']} km straight-line',
                ),
              ),
          ],
        ),
      );
      if (selected != null && mounted && sheetContext.mounted) {
        Navigator.pop(sheetContext);
        _showPlace(selected);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nearby food places are unavailable. Please try again later.',
            ),
          ),
        );
      }
    }
  }

  Future<TravelPlace> _loadPhoto(TravelPlace place) async {
    if (!place.discovered || place.imageUrl != null) return place;
    try {
      final response = await (widget.discoveryClient ?? ApiClient.dio).get(
        '/discovery/places/${place.id}/photo',
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      );
      return TravelPlace.fromJson(Map<String, dynamic>.from(response.data));
    } catch (_) {
      return place;
    }
  }

  void _showPlace(TravelPlace initialPlace) {
    final enrichment = _loadPhoto(initialPlace);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FutureBuilder<TravelPlace>(
        future: enrichment,
        initialData: initialPlace,
        builder: (context, snapshot) {
          final place = snapshot.data ?? initialPlace;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      initialPlace.discovered)
                    const LinearProgressIndicator(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _PlaceImage(url: place.imageUrl, height: 190),
                  ),
                  if (place.imageCredit != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Photo: ${place.imageCredit!['author']} · ${place.imageCredit!['license']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (place.imageCredit!['attribution']
                            ?.toString()
                            .isNotEmpty ==
                        true)
                      Text(
                        place.imageCredit!['attribution'].toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    Text(
                      place.imageCredit!['changes']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Wrap(
                      children: [
                        for (final item in {
                          'Photo source': 'source_url',
                          'Photo licence': 'license_url',
                        }.entries)
                          TextButton(
                            onPressed: () {
                              final uri = Uri.tryParse(
                                place.imageCredit![item.value]?.toString() ??
                                    '',
                              );
                              if (uri?.scheme == 'https') {
                                launchUrl(
                                  uri!,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: Text(item.key),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.type.replaceAll('_', ' '),
                    style: const TextStyle(color: AppColors.secondary),
                  ),
                  if (place.discovered)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Source result · not yet reviewed by Trav',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  if (place.description?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        place.description!,
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  if (place.visitingNotes?.isNotEmpty == true) ...[
                    const Text(
                      'Plan your visit',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.visitingNotes!,
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (place.address?.isNotEmpty == true) Text(place.address!),
                  const SizedBox(height: 20),
                  SavePlaceButton(place: place),
                  TextButton.icon(
                    onPressed: () => _nearbyFood(place, sheetContext),
                    icon: const Icon(Icons.restaurant_outlined),
                    label: const Text('Nearby restaurants & cafés'),
                  ),
                  const SizedBox(height: 12),
                  if (place.point != null)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            final point = place.point!;
                            final opened = await launchUrl(
                              Uri.https('www.google.com', '/maps/dir/', {
                                'api': '1',
                                'destination':
                                    '${point.latitude},${point.longitude}',
                              }),
                              mode: LaunchMode.externalApplication,
                            );
                            if (!opened && sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Couldn’t open directions. Please try again.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.directions_outlined),
                          label: const Text('Get directions'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            setState(() {
                              _filter = 'All';
                              _selected = place;
                              _mapMode = true;
                            });
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Show on map'),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Map location is being added.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  if (place.source?.host == 'www.openstreetmap.org')
                    const Text('© OpenStreetMap contributors · ODbL 1.0'),
                  if (place.source != null)
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        place.source!,
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(
                        place.source!.host == 'www.openstreetmap.org'
                            ? 'Location source · OpenStreetMap'
                            : 'Location source · Wikidata',
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlaceImage extends StatelessWidget {
  final String? url;
  final double height;
  const _PlaceImage({required this.url, required this.height});
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.landscape_outlined,
        color: AppColors.secondary,
        size: 36,
      ),
    );
    return url?.isNotEmpty == true
        ? Image.network(
            url!,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : fallback;
  }
}
