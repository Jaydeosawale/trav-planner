import 'place_trip_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/place_source_credit.dart';
import '../../ai/presentation/pages/ai_search_page.dart';
import '../../destinations/data/place.dart';
import '../../maps/places_map.dart';
import '../../saved/presentation/save_place_button.dart';
import '../data/place_catalogue.dart';
import 'widgets/place_card.dart';

class PlaceDetailsPage extends StatelessWidget {
  const PlaceDetailsPage({super.key, required this.place});
  final TravelPlace place;
  Future<void> _open(BuildContext context, Uri uri) async {
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn’t open this link. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Place details')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: PlacePhoto(place: place),
                  ),
                ),
                if (place.imageCredit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Photo: ${place.imageCredit!['author']} · ${place.imageCredit!['license']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  [
                    placeTypeLabel(place.type),
                    if (place.cityName?.isNotEmpty == true) place.cityName!,
                  ].join(' · '),
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    SavePlaceButton(place: place),
                    PlaceTripPicker(place: place),
                    if (place.point != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.directions_outlined),
                        label: const Text('Directions'),
                        onPressed: () => _open(
                          context,
                          Uri.https('www.google.com', '/maps/dir/', {
                            'api': '1',
                            'destination':
                                '${place.point!.latitude},${place.point!.longitude}',
                          }),
                        ),
                      ),
                  ],
                ),
                if (place.address?.isNotEmpty == true) ...[
                  const SizedBox(height: 18),
                  Text(place.address!),
                ],
                if (place.description?.isNotEmpty == true &&
                    place.description != place.address) ...[
                  const SizedBox(height: 20),
                  Text(
                    'About this place',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(place.description!, style: const TextStyle(height: 1.6)),
                ],
                const SizedBox(height: 24),
                if (place.point != null) ...[
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 270,
                      child: PlacesMap(places: [place], onSelect: (_) {}),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Make a day of it.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Build a visit around this place and your travel style.',
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AISearchPage(
                              initialPlace: place,
                              initialMessage:
                                  'Help me plan a visit to ${place.name}${place.cityName == null ? '' : ' in ${place.cityName}'}. Ask my dates, interests and budget; check current access and availability.',
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Plan a visit'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (place.visitingNotes?.isNotEmpty == true)
                  ExpansionTile(
                    title: const Text('Source & visiting notes'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          place.visitingNotes!,
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                PlaceSourceCredit(data: place.visitingNotes),
                if (place.source != null)
                  TextButton.icon(
                    onPressed: () => _open(context, place.source!),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View original listing'),
                  ),
                if (Uri.tryParse(
                      place.imageCredit?['source_url']?.toString() ?? '',
                    )?.scheme ==
                    'https')
                  TextButton(
                    onPressed: () => _open(
                      context,
                      Uri.parse(place.imageCredit!['source_url'].toString()),
                    ),
                    child: const Text('Photo source & licence'),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
