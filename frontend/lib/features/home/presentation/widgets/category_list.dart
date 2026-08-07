import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  static const items = [
    (
      Icons.beach_access_rounded,
      "Beaches",
      Color(0xFF38BDF8),
      Color(0xFF2563EB),
    ),
    (
      Icons.landscape_rounded,
      "Mountains",
      Color(0xFF22C55E),
      Color(0xFF10B981),
    ),
    (
      Icons.account_balance_rounded,
      "Heritage",
      Color(0xFFF59E0B),
      Color(0xFFF97316),
    ),
    (
      Icons.forest_rounded,
      "Nature",
      Color(0xFF84CC16),
      Color(0xFF16A34A),
    ),
    (
      Icons.location_city_rounded,
      "Cities",
      Color(0xFF8B5CF6),
      Color(0xFF4F46E5),
    ),
    (
      Icons.temple_hindu_rounded,
      "Spiritual",
      Color(0xFFFB923C),
      Color(0xFFEA580C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Explore by Category",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Choose the kind of experience you love",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = items[index];

              return Container(
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: const Color(0xFFE7EDF5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            item.$3,
                            item.$4,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: item.$4.withValues(alpha: .35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        item.$1,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: (index * 70).ms)
                  .fade(duration: 450.ms)
                  .slideY(begin: .20);
            },
          ),
        ),
      ],
    );
  }
}