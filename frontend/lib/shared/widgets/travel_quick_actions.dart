import 'package:flutter/material.dart';
import '../../features/booking/presentation/pages/booking_links_page.dart';
import '../../features/explore/presentation/pages/nearby_places_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';

class TravelQuickActions extends StatelessWidget {
  const TravelQuickActions({super.key});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      ActionChip(
        avatar: const Icon(Icons.flight_takeoff, size: 18),
        label: const Text('Book travel'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BookingLinksPage())),
      ),
      ActionChip(
        avatar: const Icon(Icons.near_me_outlined, size: 18),
        label: const Text('Places nearby'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NearbyPlacesPage())),
      ),
      ActionChip(
        avatar: const Icon(Icons.public, size: 18),
        label: const Text('Explore destinations'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ExplorePage())),
      ),
    ],
  );
}
