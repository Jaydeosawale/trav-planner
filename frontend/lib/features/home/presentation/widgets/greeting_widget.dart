import 'package:flutter/material.dart';

class GreetingWidget extends StatelessWidget {
  const GreetingWidget({super.key});

  String greeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 8) {
      return 'The World Is Waking. Where Will You Go? 🌅';
    }

    if (hour >= 8 && hour < 12) {
      return 'Your Next Adventure Starts Here. ☀️';
    }

    if (hour >= 12 && hour < 17) {
      return 'Somewhere New Is Waiting. 🧭';
    }

    if (hour >= 17 && hour < 21) {
      return 'Chase the Light. Find Your Way. 🌇';
    }

    return "Tonight's Dream. Tomorrow's Journey. 🌙";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      greeting(),
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}