import 'package:flutter/material.dart';

import 'section_title.dart';

class TrendingSection extends StatelessWidget {
  const TrendingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final places = [
      "🇯🇵 Japan",
      "🇨🇭 Switzerland",
      "🇮🇹 Italy",
      "🇫🇷 Paris",
      "🇮🇸 Iceland",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "🔥 Trending",
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: places
              .map(
                (e) => Chip(
                  label: Text(e),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}