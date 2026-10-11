import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AnimatedPlane extends StatefulWidget {
  const AnimatedPlane({super.key});

  @override
  State<AnimatedPlane> createState() => _AnimatedPlaneState();
}

class _AnimatedPlaneState extends State<AnimatedPlane>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Positioned(
          top: 80,
          left: MediaQuery.of(context).size.width * controller.value,
          child: Transform.rotate(
            angle: -.3,
            child: const Icon(
              Icons.flight_takeoff,
              color: AppColors.textPrimary,
              size: 40,
            ),
          ),
        );
      },
    );
  }
}
