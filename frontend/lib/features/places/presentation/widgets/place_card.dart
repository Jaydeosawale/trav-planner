import 'package:trav_planner/core/widgets/full_photo_frame.dart';
import '../../../../app/router/navigation_actions.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../destinations/data/place.dart';
import '../../../saved/presentation/save_place_button.dart';
import '../../data/place_catalogue.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place});
  final TravelPlace place;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => openPlace(context, place),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                PlacePhoto(place: place),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(),
                    child: SavePlaceButton(place: place, compact: true),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      placeTypeLabel(place.type),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  place.cityName ?? place.address ?? 'View place details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (place.imageCredit != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Photo: ${place.imageCredit!['author']} · ${place.imageCredit!['license']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class PlacePhoto extends StatelessWidget {
  const PlacePhoto({super.key, required this.place});
  final TravelPlace place;
  @override
  Widget build(BuildContext context) {
    Widget fallback() => ColoredBox(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_placeIcon(place.type), size: 40, color: AppColors.ocean),
            const SizedBox(height: 8),
            const Text(
              'No photo yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
    final url = place.imageUrl;
    return url?.startsWith('http') == true
        ? FullPhotoFrame(
            image: Image.network(
              url!,
              fit: BoxFit.contain,
              semanticLabel: 'Photo of ${place.name}',
              cacheWidth: 1000,
              frameBuilder: (context, child, frame, sync) =>
                  sync || frame != null
                  ? child
                  : const ColoredBox(
                      color: AppColors.surfaceVariant,
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (_, _, _) => fallback(),
            ),
          )
        : fallback();
  }
}

IconData _placeIcon(String type) => switch (type) {
  'restaurant' => Icons.restaurant_outlined,
  'cafe' => Icons.local_cafe_outlined,
  'hotel' => Icons.bed_outlined,
  'museum' => Icons.museum_outlined,
  'park' => Icons.park_outlined,
  'worship' => Icons.temple_hindu_outlined,
  _ => Icons.location_on_outlined,
};
