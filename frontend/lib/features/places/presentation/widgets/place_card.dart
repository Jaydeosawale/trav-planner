import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../destinations/data/place.dart';
import '../../../saved/presentation/save_place_button.dart';
import '../../data/place_catalogue.dart';
import '../place_details_page.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place});
  final TravelPlace place;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PlaceDetailsPage(place: place))),
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
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
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
                      fontSize: 9,
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
      color: const Color(0xFFE1EBE6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.landscape_outlined,
              size: 40,
              color: AppColors.ocean,
            ),
            const SizedBox(height: 8),
            const Text(
              'Photo not available',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
    final url = place.imageUrl;
    return url?.startsWith('http') == true
        ? Image.network(
            url!,
            fit: BoxFit.cover,
            cacheWidth: 1000,
            frameBuilder: (context, child, frame, sync) => sync || frame != null
                ? child
                : const ColoredBox(
                    color: Color(0xFFE1EBE6),
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
          )
        : fallback();
  }
}
