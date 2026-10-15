import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fixed attribution destination; never launches URLs supplied by source data.
class PlaceSourceCredit extends StatelessWidget {
  const PlaceSourceCredit({super.key, required this.data});
  final Object? data;

  @override
  Widget build(BuildContext context) {
    if (!data.toString().contains('Powered by Geoapify')) {
      return const SizedBox.shrink();
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: () => launchUrl(
            Uri.https('www.geoapify.com'),
            mode: LaunchMode.externalApplication,
          ),
          child: const Text('Powered by Geoapify'),
        ),
        TextButton(
          onPressed: () => launchUrl(
            Uri.https('www.openstreetmap.org', '/copyright'),
            mode: LaunchMode.externalApplication,
          ),
          child: const Text('© OpenStreetMap contributors'),
        ),
      ],
    );
  }
}
