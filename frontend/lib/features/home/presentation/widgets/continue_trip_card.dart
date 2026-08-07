import 'package:flutter/material.dart';

class ContinueTripCard extends StatelessWidget {
  const ContinueTripCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          radius: 28,
          child: Icon(Icons.flight_takeoff),
        ),
        title: const Text("Continue Planning"),
        subtitle: const Text("Japan • 6 Days"),
        trailing: FilledButton(
          onPressed: () {},
          child: const Text("Open"),
        ),
      ),
    );
  }
}