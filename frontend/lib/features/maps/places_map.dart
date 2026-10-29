import '../../core/widgets/place_source_credit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../destinations/data/place.dart';

class PlacesMap extends StatefulWidget {
  final List<TravelPlace> places;
  final LatLng? center;
  final String? selectedId;
  final ValueChanged<TravelPlace> onSelect;
  const PlacesMap({
    super.key,
    required this.places,
    required this.onSelect,
    this.center,
    this.selectedId,
  });

  @override
  State<PlacesMap> createState() => _PlacesMapState();
}

class _PlacesMapState extends State<PlacesMap> {
  final _controller = MapController();
  bool _ready = false;
  bool _failed = false;

  bool _userPanned = false;
  List<LatLng> get _points => [
    if (widget.center != null) widget.center!,
    ...widget.places.where((p) => p.point != null).map((p) => p.point!),
  ];
  void _fitResults() {
    if (!_ready || _points.isEmpty) return;
    if (_points.length == 1) {
      _controller.move(_points.first, 13);
    } else {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_points),
          padding: const EdgeInsets.all(48),
          maxZoom: 14,
        ),
      );
    }
    _userPanned = false;
  }

  @override
  void didUpdateWidget(covariant PlacesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final areaChanged = oldWidget.center != widget.center;
    final resultsChanged =
        oldWidget.places.map((p) => '${p.id}:${p.point}').join('|') !=
        widget.places.map((p) => '${p.id}:${p.point}').join('|');
    if (areaChanged || (resultsChanged && !_userPanned)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _ready) _fitResults();
      });
    }
    if (_ready && oldWidget.selectedId != widget.selectedId) {
      final selected = widget.places.where((p) => p.id == widget.selectedId);
      if (selected.isNotEmpty && selected.first.point != null) {
        _controller.move(selected.first.point!, 14);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final located = widget.places.where((p) => p.point != null).toList();
    final points = [
      if (widget.center != null) widget.center!,
      ...located.map((p) => p.point!),
    ];
    if (points.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Map locations haven’t been added yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        PlaceSourceCredit(
          data: widget.places.map((p) => p.visitingNotes).toList(),
        ),
        if (_failed)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'The background map couldn’t load. Place details and directions are still available.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        Expanded(
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: points.first,
              initialZoom: 12,
              minZoom: 2,
              maxZoom: 18,
              initialCameraFit: points.length > 1
                  ? CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(points),
                      padding: const EdgeInsets.all(48),
                      maxZoom: 14,
                    )
                  : null,
              onMapReady: () => _ready = true,
              onPositionChanged: (_, hasGesture) {
                if (hasGesture) _userPanned = true;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jaydeo.travplanner',
                panBuffer: 0,
                // flutter_map 8.3 uses persistent native caching and HTTP cache headers.
                errorTileCallback: (_, _, _) {
                  if (!_failed && mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _failed = true);
                    });
                  }
                },
              ),
              MarkerLayer(
                markers: [
                  if (widget.center != null)
                    Marker(
                      point: widget.center!,
                      width: 36,
                      height: 36,
                      child: const Tooltip(
                        message: 'Destination center',
                        child: Icon(
                          Icons.location_city,
                          color: AppColors.secondary,
                          size: 28,
                        ),
                      ),
                    ),
                  ...located.map(
                    (place) => Marker(
                      point: place.point!,
                      width: 48,
                      height: 48,
                      child: IconButton(
                        tooltip: place.name,
                        onPressed: () => widget.onSelect(place),
                        icon: Icon(
                          Icons.location_on,
                          color: place.id == widget.selectedId
                              ? AppColors.sunset
                              : AppColors.primary,
                          size: place.id == widget.selectedId ? 42 : 34,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _fitResults,
            icon: const Icon(Icons.center_focus_strong, size: 16),
            label: const Text('Recenter results'),
          ),
        ),
        // Outside the map canvas so sheets and cards cannot obscure attribution.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}
