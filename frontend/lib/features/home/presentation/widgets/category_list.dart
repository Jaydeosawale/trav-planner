import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  static const items = [
    (
      Icons.beach_access_rounded,
      "Beaches",
      AppColors.accent,
      AppColors.primary,
    ),
    (
      Icons.landscape_rounded,
      "Mountains",
      AppColors.success,
      AppColors.success,
    ),
    (
      Icons.account_balance_rounded,
      "Heritage",
      AppColors.warning,
      AppColors.primary,
    ),
    (Icons.forest_rounded, "Nature", AppColors.success, AppColors.success),
    (Icons.location_city_rounded, "Cities", AppColors.accent, AppColors.accent),
    (
      Icons.temple_hindu_rounded,
      "Spiritual",
      AppColors.primary,
      AppColors.primary,
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
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Choose the kind of experience you love",
          style: TextStyle(
            color: AppColors.textSecondary,
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.border),
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
                              colors: [item.$3, item.$4],
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
                            color: AppColors.textPrimary,
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
                            color: AppColors.textPrimary,
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
