import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../explore/presentation/providers/explore_provider.dart';
import '../../data/place_catalogue.dart';

class PlaceCategoryBar extends StatelessWidget {
  const PlaceCategoryBar({
    super.key,
    required this.query,
    required this.onChanged,
  });
  final PlaceQuery query;
  final ValueChanged<PlaceQuery> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: placeCategories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => ChoiceChip(
        showCheckmark: false,
        label: Text(placeCategories[i].$2),
        selected: query.type == placeCategories[i].$1,
        onSelected: (_) =>
            onChanged(query.copyWith(type: placeCategories[i].$1, page: 1)),
      ),
    ),
  );
}

Future<PlaceQuery?> showPlaceFilters(BuildContext context, PlaceQuery query) =>
    showModalBottomSheet<PlaceQuery>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _PlaceFilters(query: query),
    );

class _PlaceFilters extends ConsumerStatefulWidget {
  const _PlaceFilters({required this.query});
  final PlaceQuery query;
  @override
  ConsumerState<_PlaceFilters> createState() => _PlaceFiltersState();
}

class _PlaceFiltersState extends ConsumerState<_PlaceFilters> {
  late var _query = widget.query;
  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(exploreCountriesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Find your kind of place',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          countries.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => TextButton(
              onPressed: () => ref.invalidate(exploreCountriesProvider),
              child: const Text('Retry country filters'),
            ),
            data: (items) => DropdownButtonFormField<String>(
              key: ValueKey(_query.countryId ?? 'world'),
              initialValue: items.any((c) => c.id == _query.countryId)
                  ? _query.countryId
                  : 'world',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Where'),
              items: [
                const DropdownMenuItem(
                  value: 'world',
                  child: Text('Worldwide'),
                ),
                for (final c in items)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) => setState(
                () => _query = _query.copyWith(
                  countryId: id == 'world' ? null : id,
                  clearCountry: id == 'world',
                  page: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Photos only'),
            subtitle: const Text('Show places with a photo available in Trav.'),
            value: _query.photosOnly,
            onChanged: (v) => setState(
              () => _query = _query.copyWith(photosOnly: v, page: 1),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context, _query),
            child: const Text('Show places'),
          ),
          TextButton(
            onPressed: () => setState(
              () => _query = PlaceQuery(
                type: widget.query.type,
                search: widget.query.search,
                size: widget.query.size,
              ),
            ),
            child: const Text('Reset filters'),
          ),
        ],
      ),
    );
  }
}

String? placeCountryName(WidgetRef ref, PlaceQuery query) {
  if (query.countryId == null) return null;
  final items = ref.watch(exploreCountriesProvider).asData?.value;
  return items?.where((c) => c.id == query.countryId).firstOrNull?.name ??
      'Selected country';
}
