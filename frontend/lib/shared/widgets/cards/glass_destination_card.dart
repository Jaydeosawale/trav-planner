import 'package:trav_planner/core/theme/app_colors.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../features/home/data/models/destination_model.dart';

class GlassDestinationCard extends StatelessWidget {
  final DestinationModel destination;

  const GlassDestinationCard({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 270,
          margin: const EdgeInsets.only(right: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(child: _buildImage()),

                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.textPrimary, Colors.transparent],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.white.withValues(alpha: 0.20),
                        child: Icon(
                          destination.isFeatured
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        color: Colors.white.withValues(alpha: 0.18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),

                            const SizedBox(height: 6),

                            if (destination.country.isNotEmpty)
                              Text(
                                destination.country,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),

                            if (destination.country.isNotEmpty)
                              const SizedBox(height: 14),

                            if (destination.shortDescription != null)
                              Text(
                                destination.shortDescription!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Icon(
                                  destination.isActive
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: destination.isActive
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  destination.isActive
                                      ? "Available"
                                      : "Unavailable",
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                if (destination.isFeatured)
                                  const Text(
                                    "Featured",
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(duration: 600.ms)
        .slideX(begin: .25)
        .scale(begin: const Offset(.95, .95));
  }

  Widget _buildImage() {
    // ----------------------------------------------------------
    // 1. Use image coming from backend if available.
    // ----------------------------------------------------------

    final image = destination.image;

    if (image != null && image.isNotEmpty) {
      if (image.startsWith("http://") || image.startsWith("https://")) {
        return Image.network(
          image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _fallbackImage();
          },
        );
      }

      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _fallbackImage();
        },
      );
    }

    // ----------------------------------------------------------
    // 2. Temporary local images.
    // ----------------------------------------------------------

    final localImage = _localImageForDestination();

    return Image.asset(
      localImage,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return _fallbackImage();
      },
    );
  }

  String _localImageForDestination() {
    final slug = destination.slug.toLowerCase();

    if (slug.contains("goa")) {
      return "assets/images/destinations/goa_1.jpg";
    }

    if (slug.contains("jaipur") || slug.contains("city-palace")) {
      return "assets/images/destinations/dubai_1.jpg";
    }

    if (slug.contains("lake-pichola") || slug.contains("udaipur")) {
      return "assets/images/destinations/bali_1.jpg";
    }

    if (slug.contains("taj-mahal") || slug.contains("agra")) {
      return "assets/images/destinations/japan_1.jpg";
    }

    return "assets/images/destinations/switzerland_1.jpg";
  }

  Widget _fallbackImage() {
    return Container(
      color: AppColors.textPrimary,
      child: const Center(
        child: Icon(Icons.landscape, color: AppColors.textSecondary, size: 48),
      ),
    );
  }
}
