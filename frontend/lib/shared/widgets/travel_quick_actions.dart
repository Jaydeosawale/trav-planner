import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/booking/presentation/pages/booking_links_page.dart';
import '../../features/explore/presentation/pages/nearby_places_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';

class TravelQuickActions extends StatelessWidget {
  const TravelQuickActions({super.key});
  void _open(BuildContext c, Widget page) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => page));
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LayoutBuilder(
        builder: (context, box) => Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in [
              (
                Icons.flight_takeoff,
                'Book travel',
                'Flights, trains & stays',
                const Color(0xFFE1EBFB),
                const BookingLinksPage(),
              ),
              (
                Icons.near_me_outlined,
                'Places nearby',
                'Little finds around you',
                const Color(0xFFDDEEE5),
                const NearbyPlacesPage(),
              ),
              (
                Icons.public,
                'Explore destinations',
                'Your next somewhere',
                const Color(0xFFF8E5D3),
                const ExplorePage(),
              ),
            ])
              SizedBox(
                width: (box.maxWidth - 20) / 3,
                child: Material(
                  color: item.$4,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _open(context, item.$5),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$1, color: AppColors.ocean),
                          const SizedBox(height: 12),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          if (box.maxWidth > 500) ...[
                            const SizedBox(height: 5),
                            Text(
                              item.$3,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'What are you in the mood for?',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in [
            (Icons.restaurant_outlined, 'Good food', 'restaurant'),
            (Icons.park_outlined, 'A little nature', 'park'),
            (Icons.museum_outlined, 'Art & stories', 'museum'),
            (Icons.landscape_outlined, 'A new view', 'viewpoint'),
          ])
            ActionChip(
              avatar: Icon(item.$1, size: 17),
              label: Text(item.$2),
              onPressed: () =>
                  _open(context, NearbyPlacesPage(initialKind: item.$3)),
            ),
        ],
      ),
    ],
  );
}
