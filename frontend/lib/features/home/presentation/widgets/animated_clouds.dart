import 'package:flutter/material.dart';

class AnimatedClouds extends StatefulWidget {
  const AnimatedClouds({super.key});

  @override
  State<AnimatedClouds> createState() => _AnimatedCloudsState();
}

class _AnimatedCloudsState extends State<AnimatedClouds>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget cloud(double top, double offset) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Positioned(
          top: top,
          left: -120 + controller.value * (500 + offset),
          child: Icon(
            Icons.cloud,
            color: Colors.white.withOpacity(.35),
            size: 70,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        cloud(40, 0),
        cloud(120, 120),
        cloud(180, 220),
      ],
    );
  }
}