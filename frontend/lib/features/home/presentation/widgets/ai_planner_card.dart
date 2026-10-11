import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AIPlannerCard extends StatelessWidget {
  const AIPlannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),

        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.primary],
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "✨ AI Travel Planner",

            style: TextStyle(
              color: AppColors.textPrimary,

              fontWeight: FontWeight.bold,

              fontSize: 28,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Describe your dream vacation and let AI create a personalized itinerary.",

            style: TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 20),

          FilledButton(onPressed: () {}, child: const Text("Start Planning")),
        ],
      ),
    ).animate().fade().scale();
  }
}
