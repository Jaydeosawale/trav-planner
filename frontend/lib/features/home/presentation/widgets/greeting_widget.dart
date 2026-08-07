import 'package:flutter/material.dart';

class GreetingWidget extends StatelessWidget {
  const GreetingWidget({super.key});

  String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return "Good Morning ☀️";
    if (hour < 17) return "Good Afternoon 🌤";
    return "Good Evening 🌙";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          greeting(),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          "Discover your \nnext destination?",
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 38,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}