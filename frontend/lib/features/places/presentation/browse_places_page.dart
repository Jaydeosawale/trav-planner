import '../../maps/places_map.dart';
import '../../destinations/data/place.dart';
import 'place_details_page.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/place_source_credit.dart';
import '../../explore/presentation/pages/explore_page.dart';
import '../data/place_catalogue.dart';
import 'widgets/place_card.dart';
import 'widgets/place_filters.dart';

class BrowsePlacesPage extends ConsumerStatefulWidget {
  const BrowsePlacesPage({super.key, this.initialQuery = const PlaceQuery()});
  final PlaceQuery initialQuery;
  @override
  ConsumerState<BrowsePlacesPage> createState() => _BrowsePlacesPageState();
}

class _BrowsePlacesPageState extends ConsumerState<BrowsePlacesPage> {
  late PlaceQuery _query = widget.initialQuery.copyWith(size: 20, page: 1);
  late final _search = TextEditingController(text: _query.search);
  final _scroll = ScrollController();
  Timer? _debounce;
  int _page = 1;
  bool _map = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_next);
  }

  void _change(PlaceQuery query) {
    _debounce?.cancel();
    setState(() {
      _query = query.copyWith(page: 1, size: 20, search: _search.text);
      _page = 1;
    });
  }

  void _next() {
    if (!_scroll.hasClients ||
        _scroll.position.extentAfter > 250 ||
        _scroll.position.userScrollDirection != ScrollDirection.reverse ||
        (_debounce?.isActive ?? false)) {
      return;
    }
    final result = ref
        .read(placeCatalogueProvider(_query.copyWith(page: _page)))
        .asData
        ?.value;
    if (result != null && _page < result.pages) setState(() => _page++);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final mapped = <TravelPlace>[];
    if (_map) {
      for (var page = 1; page <= _page; page++) {
        mapped.addAll(
          ref
                  .watch(placeCatalogueProvider(_query.copyWith(page: page)))
                  .asData
                  ?.value
                  .items ??
              [],
        );
      }
    }
    final current = ref.watch(
      placeCatalogueProvider(_query.copyWith(page: _page)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Discover places')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: CustomScrollView(
            controller: _scroll,
            key: const ValueKey('place-feed-scroll'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Find your next stop.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: 'Place, city or interest',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              _change(_query.copyWith(search: ''));
                            },
                          ),
                        ),
                        onChanged: (v) {
                          _debounce?.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 450),
                            () {
                              if (mounted) _change(_query.copyWith(search: v));
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      PlaceCategoryBar(query: _query, onChanged: _change),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final q = await showPlaceFilters(context, _query);
                              if (q != null && mounted) _change(q);
                            },
                            icon: const Icon(Icons.tune),
                            label: Text(
                              placeCountryName(ref, _query) ?? 'Filters',
                            ),
                          ),
                          FilterChip(
                            label: const Text('Photos only'),
                            selected: _query.photosOnly,
                            onSelected: (v) =>
                                _change(_query.copyWith(photosOnly: v)),
                          ),
                          if (_query.countryId != null)
                            ActionChip(
                              label: const Text('Clear country'),
                              onPressed: () =>
                                  _change(_query.copyWith(clearCountry: true)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.grid_view_outlined),
                            label: Text('Cards'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.map_outlined),
                            label: Text('Map'),
                          ),
                        ],
                        selected: {_map},
                        onSelectionChanged: (v) =>
                            setState(() => _map = v.first),
                      ),
                    ],
                  ),
                ),
              ),
              if (_map && current.hasError)
                ..._pageSlivers(_page, wide)
              else if (_map) ...[
                if (current.isLoading)
                  const SliverToBoxAdapter(child: LinearProgressIndicator()),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 480,
                      child: PlacesMap(
                        key: ValueKey(_query),
                        places: mapped,
                        onSelect: (p) => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailsPage(place: p),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else
                for (var page = 1; page <= _page; page++)
                  ..._pageSlivers(page, wide),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (current.asData?.value case final result?) ...[
                        Text(
                          result.total == 1
                              ? '1 place matches your filters'
                              : '${result.total} places match your filters',
                        ),
                        if (_page < result.pages)
                          TextButton.icon(
                            onPressed: () => setState(() => _page++),
                            icon: const Icon(Icons.expand_more),
                            label: const Text('Show more places'),
                          ),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'Looking somewhere else? Open a destination for more local places.',
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExplorePage(
                              initialQuery: _query.search,
                              placeKind: _query.type == 'all'
                                  ? 'attraction'
                                  : _query.type,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.public),
                        label: const Text('Explore destinations'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _pageSlivers(int page, bool wide) {
    final request = _query.copyWith(page: page);
    final state = ref.watch(placeCatalogueProvider(request));
    return state.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      error: (_, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'We couldn’t load these places. Your filters are kept.',
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(placeCatalogueProvider(request)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ],
      data: (result) => [
        if (result.items.isEmpty && page == 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Icon(Icons.travel_explore, size: 42),
                  const SizedBox(height: 12),
                  const Text('No places match yet.'),
                  const SizedBox(height: 8),
                  const Text(
                    'Try another category or include places without a photo.',
                  ),
                  if (_query.photosOnly)
                    TextButton(
                      onPressed: () =>
                          _change(_query.copyWith(photosOnly: false)),
                      child: const Text('Include places without photos'),
                    ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          sliver: SliverGrid.builder(
            itemCount: result.items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: wide
                  ? 3
                  : MediaQuery.sizeOf(context).width >= 600
                  ? 2
                  : 1,
              mainAxisExtent: wide ? 350 : 330,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
            itemBuilder: (_, i) => PlaceCard(place: result.items[i]),
          ),
        ),
        SliverToBoxAdapter(
          child: PlaceSourceCredit(
            data: result.items.map((p) => p.visitingNotes).toList(),
          ),
        ),
      ],
    );
  }
}
