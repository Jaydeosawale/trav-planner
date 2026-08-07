import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xff38BDF8),
            Color(0xff0EA5E9),
          ],
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.wb_sunny_rounded,
            size: 70,
            color: Colors.white,
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "26°C",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Perfect Weather for Travel",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          )
        ],
      ),
    ).animate().fade().slideY();
  }
}