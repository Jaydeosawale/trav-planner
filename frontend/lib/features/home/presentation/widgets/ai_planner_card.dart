import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AIPlannerCard extends StatelessWidget {
  const AIPlannerCard({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(

      margin: const EdgeInsets.symmetric(vertical:24),

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(32),

        gradient: const LinearGradient(

          colors: [

            Color(0xff0EA5E9),

            Color(0xff2563EB),

          ],
        ),
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(

            "✨ AI Travel Planner",

            style: TextStyle(

              color: Colors.white,

              fontWeight: FontWeight.bold,

              fontSize:28,

            ),
          ),

          const SizedBox(height:12),

          const Text(

            "Describe your dream vacation and let AI create a personalized itinerary.",

            style: TextStyle(

              color: Colors.white70,

            ),
          ),

          const SizedBox(height:20),

          FilledButton(

            onPressed: () {},

            child: const Text("Start Planning"),

          )
        ],
      ),
    ).animate().fade().scale();
  }
}