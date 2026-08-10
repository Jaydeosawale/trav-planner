import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/cards/glass_destination_card.dart';
import '../providers/home_provider.dart';

class PopularDestinations extends ConsumerWidget {
  const PopularDestinations({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final destinationsAsync = ref.watch(
      destinationsProvider,
    );

    return SizedBox(
      height: 360,
      child: destinationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            "Unable to load destinations..\n$error",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        data: (destinations) {
          if (destinations.isEmpty) {
            return const Center(
              child: Text(
                "No destinations available.",
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              return GlassDestinationCard(
                destination: destinations[index],
              );
            },
          );
        },
      ),
    );
  }
}