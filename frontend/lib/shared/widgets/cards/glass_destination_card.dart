import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../features/home/data/models/destination_model.dart';

class GlassDestinationCard extends StatelessWidget {
  final DestinationModel destination;

  const GlassDestinationCard({
    super.key,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                destination.image,
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                    ],
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
                  filter: ImageFilter.blur(
                    sigmaX: 12,
                    sigmaY: 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.white.withValues(alpha: 0.20),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
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
                  filter: ImageFilter.blur(
                    sigmaX: 15,
                    sigmaY: 15,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    color: Colors.white.withValues(alpha: 0.18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          destination.country,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              destination.rating.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "₹${destination.price}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    )
        .animate()
        .fade(duration: 600.ms)
        .slideX(begin: .25)
        .scale(begin: const Offset(.95, .95));
  }
}