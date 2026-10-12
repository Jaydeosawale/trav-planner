import 'package:flutter/material.dart';
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
  const DestinationDetailsPage({
    super.key,
    required this.cityId,
    required this.name,
    this.description,
    this.imageUrl,
    this.center,
    this.initialPlace,
  });

  @override
  ConsumerState<DestinationDetailsPage> createState() =>
      _DestinationDetailsPageState();
}

class _DestinationDetailsPageState
    extends ConsumerState<DestinationDetailsPage> {
  String _filter = 'All';
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
                      data: _buildPlaces,
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

  void _showPlace(TravelPlace place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _PlaceImage(url: place.imageUrl, height: 190),
              ),
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
              if (place.description?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    place.description!,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              if (place.address?.isNotEmpty == true) Text(place.address!),
              const SizedBox(height: 20),
              SavePlaceButton(place: place),
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
              if (place.source != null)
                TextButton.icon(
                  onPressed: () => launchUrl(
                    place.source!,
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Location source · Wikidata'),
                ),
            ],
          ),
        ),
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
