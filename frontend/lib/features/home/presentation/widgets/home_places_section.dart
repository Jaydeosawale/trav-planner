import 'package:flutter/rendering.dart';
import '../../../../app/router/navigation_actions.dart';
import '../../../places/data/place_area.dart';
import '../../../explore/presentation/pages/nearby_places_page.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/place_source_credit.dart';
import '../../../places/data/place_catalogue.dart';
import '../../../places/presentation/widgets/place_card.dart';
import '../../../places/presentation/widgets/place_filters.dart';

class HomePlacesSection extends ConsumerStatefulWidget {
  const HomePlacesSection({super.key});
  @override
  ConsumerState<HomePlacesSection> createState() => _HomePlacesSectionState();
}

class _HomePlacesSectionState extends ConsumerState<HomePlacesSection> {
  PlaceQuery _query = const PlaceQuery(photosOnly: true, size: 8);
  int _page = 1;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_next);
      _position = position;
      _position?.addListener(_next);
    }
  }

  void _next() {
    if (_position == null ||
        _position!.extentAfter > 400 ||
        _position!.pixels <= 0 ||
        _position!.userScrollDirection != ScrollDirection.reverse) {
      return;
    }
    final area = ref.read(chosenPlaceAreaProvider);
    final query = _query.copyWith(
      cityId: area?.cityId,
      clearCity: area?.cityId == null,
      page: _page,
    );
    final result = ref.read(placeCatalogueProvider(query)).asData?.value;
    if (result != null && _page < result.pages) setState(() => _page++);
  }

  @override
  void dispose() {
    _position?.removeListener(_next);
    super.dispose();
  }

  void _change(PlaceQuery q) {
    if (q.countryId != _query.countryId) {
      ref.read(chosenPlaceAreaProvider.notifier).state = null;
    }
    setState(() {
      _query = q.copyWith(size: 8, page: 1);
      _page = 1;
    });
  }

  void _browse() => openPlaceSearch(context, _query);
  @override
  Widget build(BuildContext context) {
    ref.listen<PlaceArea?>(chosenPlaceAreaProvider, (previous, next) {
      if (previous?.cityId != next?.cityId) setState(() => _page = 1);
    });
    final area = ref.watch(chosenPlaceAreaProvider);
    final effectiveQuery = _query.copyWith(
      cityId: area?.cityId,
      clearCity: area?.cityId == null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                area == null ? 'Places to explore' : 'Explore ${area.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Filters',
              icon: const Icon(Icons.tune, size: 20),
              onPressed: () async {
                final q = await showPlaceFilters(context, _query);
                if (q != null && mounted) _change(q);
              },
            ),
            TextButton(onPressed: _browse, child: const Text('See all')),
          ],
        ),
        if (placeCountryName(ref, _query) case final country?)
          Text(country, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        PlaceCategoryBar(query: _query, onChanged: _change),
        const SizedBox(height: 10),
        for (var page = 1; page <= _page; page++)
          ref
              .watch(
                placeCatalogueProvider(effectiveQuery.copyWith(page: page)),
              )
              .when(
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Places are taking a little longer to load.'),
                      TextButton(
                        onPressed: () => ref.invalidate(
                          placeCatalogueProvider(effectiveQuery),
                        ),
                        child: const Text('Retry places'),
                      ),
                    ],
                  ),
                ),
                data: (result) => result.items.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _query.photosOnly
                                  ? 'No photos for this selection yet.'
                                  : 'No places match this selection yet.',
                            ),
                            if (_query.photosOnly)
                              TextButton(
                                onPressed: () =>
                                    _change(_query.copyWith(photosOnly: false)),
                                child: const Text(
                                  'Include places without photos',
                                ),
                              ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => NearbyPlacesPage(
                                    initialKind: _query.type,
                                  ),
                                ),
                              ),
                              child: const Text('Find places nearby'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExplorePage(
                                    placeKind: _query.type == 'all'
                                        ? 'attraction'
                                        : _query.type,
                                  ),
                                ),
                              ),
                              child: const Text('Choose a destination'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 900
                                  ? 3
                                  : constraints.maxWidth >= 600
                                  ? 2
                                  : 1;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: result.items.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisExtent:
                                          330 +
                                          (MediaQuery.textScalerOf(
                                                    context,
                                                  ).scale(14) -
                                                  14) *
                                              6,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                itemBuilder: (_, i) =>
                                    PlaceCard(place: result.items[i]),
                              );
                            },
                          ),
                          if (page == _page && page < result.pages)
                            TextButton.icon(
                              onPressed: () => setState(() => _page++),
                              icon: const Icon(Icons.expand_more),
                              label: const Text('More places'),
                            ),
                          PlaceSourceCredit(
                            data: result.items
                                .map((p) => p.visitingNotes)
                                .toList(),
                          ),
                        ],
                      ),
              ),
      ],
    );
  }
}
