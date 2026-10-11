import 'package:flutter/material.dart';
import '../../features/explore/presentation/pages/explore_page.dart';

class PremiumSearchBar extends StatelessWidget {
  const PremiumSearchBar({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => TextField(
    textInputAction: TextInputAction.search,
    onSubmitted: (query) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExplorePage(initialQuery: query.trim()),
      ),
    ),
    decoration: InputDecoration(
      hintText: 'Where do you want to go?',
      isDense: compact,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: IconButton(
        tooltip: 'Explore destinations',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ExplorePage())),
        icon: const Icon(Icons.tune_rounded),
      ),
    ),
  );
}
