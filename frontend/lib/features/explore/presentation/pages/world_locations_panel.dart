import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../destinations/data/place.dart';
import '../../../destinations/presentation/destination_details_page.dart';
import '../../data/models/explore_city.dart';

class WorldLocationsPanel extends StatefulWidget {
  const WorldLocationsPanel({
    super.key,
    required this.query,
    this.country,
    this.client,
  });
  final String query;
  final String? country;
  final Dio? client;
  @override
  State<WorldLocationsPanel> createState() => _WorldLocationsPanelState();
}

class _WorldLocationsPanelState extends State<WorldLocationsPanel> {
  bool _busy = false;
  List<Map<String, dynamic>>? _items;
  String? _notice;

  Future<void> _search() async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final response = await (widget.client ?? ApiClient.dio).get(
        '/discovery/locations',
        queryParameters: {
          'q': widget.query,
          if (widget.country != null) 'country': widget.country,
        },
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      if (mounted) {
        setState(
          () => _items = (response.data['items'] as List)
              .map((i) => Map<String, dynamic>.from(i))
              .toList(),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice =
              'Additional locations are unavailable. Try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final r = await (widget.client ?? ApiClient.dio).post(
        '/discovery/locations/${item['id']}/open',
      );
      final city = ExploreCity.fromJson(Map<String, dynamic>.from(r.data));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DestinationDetailsPage(
            discoveryClient: widget.client,
            cityId: city.id,
            name: city.name,
            center: validCoordinates(city.latitude, city.longitude),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice =
              'Couldn’t open this location. Sign in and try again; available destinations remain here.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'More towns & settlements',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Find smaller locations by name. Local attractions and photos may still be unavailable.',
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _search,
            icon: const Icon(Icons.travel_explore),
            label: const Text('Search more locations'),
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_notice != null) Text(_notice!),
        if (_items != null && _items!.isEmpty)
          const Text(
            'No additional matches. Try a longer name or another spelling.',
          ),
        for (final item in _items ?? <Map<String, dynamic>>[])
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(item['name'].toString()),
              subtitle: Text(
                '${item['region_name']}, ${item['country_name']} · ${item['latitude']}, ${item['longitude']}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy ? null : () => _open(item),
            ),
          ),
        if (_items != null)
          const Text(
            'GeoNames · CC BY 4.0 · adapted snapshot; coverage may be incomplete.',
            style: TextStyle(fontSize: 12),
          ),
      ],
    ),
  );
}
