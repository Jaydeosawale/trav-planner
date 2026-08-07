import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/cards/glass_destination_card.dart';
import '../providers/home_provider.dart';

class PopularDestinations extends ConsumerWidget {
  const PopularDestinations({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ref.watch(destinationsProvider);

    return SizedBox(
      height: 360,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: destinations.length,
        itemBuilder: (_, index) {
          return GlassDestinationCard(
            destination: destinations[index],
          );
        },
      ),
    );
  }
}