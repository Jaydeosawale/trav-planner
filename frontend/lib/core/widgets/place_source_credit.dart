import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
    final style = TextButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
      textStyle: const TextStyle(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      alignment: Alignment.centerLeft,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            style: style,
            onPressed: () => launchUrl(
              Uri.https('www.geoapify.com'),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Powered by Geoapify'),
          ),
          TextButton(
            style: style,
            onPressed: () => launchUrl(
              Uri.https('www.openstreetmap.org', '/copyright'),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('© OpenStreetMap contributors'),
          ),
        ],
      ),
    );
  }
}
