import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../destinations/data/place.dart';
import '../../../destinations/presentation/destination_details_page.dart';
import '../../../explore/data/datasources/explore_api.dart';
import '../providers/home_provider.dart';

/// Resolve the slide identity, never a similarly named town in another country.
class FeaturedDestinationPage extends ConsumerStatefulWidget {
  const FeaturedDestinationPage({
    super.key,
    required this.label,
    required this.slug,
    this.redirectUrl,
  });
  final String label, slug;
  final String? redirectUrl;

  @override
  ConsumerState<FeaturedDestinationPage> createState() =>
      _FeaturedDestinationPageState();
}

class _FeaturedDestinationPageState
    extends ConsumerState<FeaturedDestinationPage> {
  Widget? _details;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final destinations = await ref.read(destinationsProvider.future);
      final target = widget.redirectUrl == null
          ? null
          : Uri.tryParse(widget.redirectUrl!)?.pathSegments.lastOrNull;
      final name = widget.label.split(',').first.trim().toLowerCase();
      final matches = destinations
          .where(
            (d) =>
                d.isActive &&
                (target != null
                    ? d.id == target || d.slug == target
                    : d.slug.toLowerCase() == widget.slug.toLowerCase() ||
                          d.title.toLowerCase() == name),
          )
          .toList();
      Widget details;
      if (matches.length == 1) {
        final d = matches.single;
        details = DestinationDetailsPage(
          cityId: d.cityId,
          name: d.title,
          description: d.description ?? d.shortDescription,
          imageUrl: d.image,
          center: validCoordinates(d.latitude, d.longitude),
        );
      } else {
        // Regional slides start from an explicitly identified local hub.
        final hub = switch (name) {
          'bali' => ('Ubud', 'Indonesia'),
          'goa' => ('Panjim', 'India'),
          'paris' => ('Paris', 'France'),
          _ => null,
        };
        if (hub == null || target != null) throw StateError('No destination');
        final countries = await ExploreApi.instance.getActiveCountries();
        final country = countries.singleWhere(
          (c) => c.name.toLowerCase() == hub.$2.toLowerCase(),
        );
        final cities = await ExploreApi.instance.searchCities(
          search: hub.$1,
          countryId: country.id,
        );
        final city = cities.items.singleWhere(
          (c) => c.name.toLowerCase() == hub.$1.toLowerCase(),
        );
        details = DestinationDetailsPage(
          cityId: city.id,
          name: widget.label,
          description: 'Explore ${widget.label}, starting around ${city.name}.',
          center: validCoordinates(city.latitude, city.longitude),
        );
      }
      if (mounted) setState(() => _details = details);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) =>
      _details ??
      Scaffold(
        appBar: AppBar(title: Text(widget.label)),
        body: Center(
          child: _failed
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Couldn’t load this destination. Please try again.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
}
