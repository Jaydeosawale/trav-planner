import 'package:trav_planner/core/widgets/full_photo_frame.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Curated inspiration opens the existing destination search.
class TravelInspirationGrid extends StatelessWidget {
  const TravelInspirationGrid({super.key, required this.onSelect});
  final ValueChanged<String> onSelect;
  static const places = [
    ('Panaji', 'Discover Goa at your pace', 'goa'),
    ('Paris', 'A city full of stories', 'paris'),
    ('Interlaken', 'Take the Swiss scenic route', 'switzerland'),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth >= 700;
      Widget tile(int index, double height) {
        final place = places[index];
        return Semantics(
          label: 'Explore ${place.$1}',
          button: true,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelect(place.$1),
              child: Ink(
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FullPhotoFrame(
                      image: Image.asset(
                        'assets/images/destinations/${place.$3}_1.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xD9112035)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.$1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            place.$2,
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      top: 14,
                      right: 14,
                      child: Icon(
                        Icons.north_east_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      if (wide) {
        return Row(
          children: [
            Expanded(flex: 5, child: tile(0, 230)),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: tile(1, 230)),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: tile(2, 230)),
          ],
        );
      }
      return SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: places.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, index) => SizedBox(
            width: (box.maxWidth * .86).clamp(220.0, 340.0),
            child: tile(index, 210),
          ),
        ),
      );
    },
  );
}
