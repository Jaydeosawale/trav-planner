import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import 'destination_card.dart';
import 'section_title.dart';

class DestinationCarousel extends StatelessWidget {
  const DestinationCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionTitle(title: "Popular Destinations")),

            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Row(
                children: [
                  Text(
                    "See all",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          "Handpicked places loved by travellers around the world",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 26),

        SizedBox(
          height: 405,
          child: ListView(
            padding: const EdgeInsets.only(left: 6, right: 24),
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            children: const [
              DestinationCard(
                image: "assets/images/destinations/bali_1.jpg",
                place: "Bali",
                country: "Indonesia",
                price: "₹48,000",
              ),

              DestinationCard(
                image: "assets/images/destinations/tokyo_1.jpg",
                place: "Tokyo",
                country: "Japan",
                price: "₹95,000",
              ),

              DestinationCard(
                image: "assets/images/destinations/switzerland_1.jpg",
                place: "Zurich",
                country: "Switzerland",
                price: "₹1,75,000",
              ),

              DestinationCard(
                image: "assets/images/destinations/dubai_1.jpg",
                place: "Dubai",
                country: "United Arab Emirates",
                price: "₹65,000",
              ),

              DestinationCard(
                image: "assets/images/destinations/goa_1.jpg",
                place: "Goa",
                country: "India",
                price: "₹18,000",
              ),
            ],
          ),
        ),
      ],
    );
  }
}
