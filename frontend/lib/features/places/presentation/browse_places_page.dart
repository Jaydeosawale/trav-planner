import '../../../app/router/navigation_actions.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/widgets/require_sign_in.dart';
import '../data/place_area.dart';
import 'area_selector.dart';
import '../../maps/places_map.dart';
import '../../destinations/data/place.dart';
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
  bool _discovering = false;
  String? _discoveryNotice;
  List<TravelPlace> _additional = [];
  List<TravelPlace> get _visibleAdditional {
    final known = <String>{};
    for (var page = 1; page <= _page; page++) {
      known.addAll(
        ref
                .read(placeCatalogueProvider(_query.copyWith(page: page)))
                .asData
                ?.value
                .items
                .map((p) => p.id) ??
            <String>[],
      );
    }
    return _additional
        .where(
          (place) =>
              !known.contains(place.id) &&
              (!_query.photosOnly || place.imageUrl != null) &&
              (_query.type == 'all' || place.type == _query.type) &&
              (_query.search.isEmpty ||
                  '${place.name} ${place.description ?? ''}'
                      .toLowerCase()
                      .contains(_query.search.toLowerCase())),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_next);
    if (_query.cityId != null) {
      Future.microtask(_restoreAreaLabel);
    }
    final area = ref.read(chosenPlaceAreaProvider);
    if (_query.search.isEmpty &&
        _query.cityId == null &&
        area != null &&
        (_query.countryId == null || area.countryId == _query.countryId)) {
      _query = _query.copyWith(cityId: area.cityId, countryId: area.countryId);
    }
  }

  Future<void> _restoreAreaLabel() async {
    final id = _query.cityId;
    if (id == null || ref.read(chosenPlaceAreaProvider)?.cityId == id) return;
    try {
      final response = await ref
          .read(placeAreaApiProvider)
          .client
          .get('/cities/${Uri.encodeComponent(id)}');
      if (!mounted || _query.cityId != id) return;
      final row = Map<String, dynamic>.from(response.data['data']);
      final point = validCoordinates(row['latitude'], row['longitude']);
      ref.read(chosenPlaceAreaProvider.notifier).state = PlaceArea(
        cityId: id,
        name: row['name'].toString(),
        countryId: row['country_id']?.toString(),
        latitude: point?.latitude,
        longitude: point?.longitude,
      );
    } catch (_) {
      /* Search remains usable if its area label cannot be loaded. */
    }
  }

  @override
  void didUpdateWidget(covariant BrowsePlacesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.initialQuery.copyWith(page: 1, size: 20);
    if (oldWidget.initialQuery != widget.initialQuery &&
        incoming != _query.copyWith(page: 1, size: 20)) {
      _debounce?.cancel();
      _query = incoming;
      _search.text = incoming.search;
      _page = 1;
      _additional = [];
      _discoveryNotice = null;
      Future.microtask(_restoreAreaLabel);
    }
  }

  void _change(PlaceQuery query) {
    _debounce?.cancel();
    setState(() {
      _query = query.copyWith(page: 1, size: 20, search: _search.text);
      _page = 1;
      _additional = [];
      _discoveryNotice = null;
    });
    final router = GoRouter.maybeOf(context);
    if (router != null &&
        router.routeInformationProvider.value.uri.path == '/explore') {
      router.replace(placeSearchUri(_query).toString());
    }
  }

  void _selectArea(PlaceArea area) {
    _search.clear();
    _change(
      _query.copyWith(
        cityId: area.cityId,
        countryId: area.countryId,
        search: '',
        photosOnly: false,
      ),
    );
  }

  Future<void> _discover() async {
    if (_discovering || _query.cityId == null) return;
    if (!await ensureSignedIn(context, ref)) return;
    if (!mounted) return;
    setState(() {
      _discovering = true;
      _discoveryNotice = null;
    });
    final request = _query;
    try {
      final response = await ref
          .read(placeAreaApiProvider)
          .client
          .get(
            '/discovery/cities/${_query.cityId}',
            options: Options(receiveTimeout: const Duration(seconds: 75)),
            queryParameters: {
              'kind': _query.type == 'all' ? 'local' : _query.type,
            },
          );
      if (!mounted || request != _query) return;
      setState(() {
        _additional = (response.data['items'] as List)
            .map((p) => TravelPlace.fromJson(Map<String, dynamic>.from(p)))
            .toList();
        _discoveryNotice = response.data['message']?.toString();
      });
    } catch (error) {
      if (mounted) setState(() => _discoveryNotice = areaFailure(error));
    } finally {
      if (mounted) setState(() => _discovering = false);
    }
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
    ref.listen<PlaceArea?>(chosenPlaceAreaProvider, (previous, next) {
      if (next != null && _query.cityId != next.cityId) _selectArea(next);
    });
    final area = ref.watch(chosenPlaceAreaProvider);
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
    if (_map) mapped.addAll(_visibleAdditional);
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
                      const SizedBox(height: 12),
                      const AreaSelector(),
                      if (_query.cityId != null && area != null) ...[
                        Text(
                          'Around ${area.name}${area.subtitle.isEmpty ? '' : ' · ${area.subtitle}'}',
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(chosenPlaceAreaProvider.notifier).state =
                                null;
                            _search.clear();
                            _change(
                              _query.copyWith(clearCity: true, search: ''),
                            );
                          },
                          child: const Text('Search worldwide'),
                        ),
                      ],
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
                      if (_query.search.trim().length >= 2) ...[
                        AreaCandidates(
                          query: _query.search,
                          countryId: _query.countryId,
                          onSelected: _selectArea,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Places',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
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
                              if (q != null && mounted) {
                                if (q.countryId != _query.countryId) {
                                  ref
                                          .read(
                                            chosenPlaceAreaProvider.notifier,
                                          )
                                          .state =
                                      null;
                                  _change(q.copyWith(clearCity: true));
                                } else {
                                  _change(q.copyWith(cityId: _query.cityId));
                                }
                              }
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
                              onPressed: () {
                                ref
                                        .read(chosenPlaceAreaProvider.notifier)
                                        .state =
                                    null;
                                _change(
                                  _query.copyWith(
                                    clearCountry: true,
                                    clearCity: true,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      if (_query.cityId != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _discovering ? null : _discover,
                          icon: const Icon(Icons.travel_explore),
                          label: Text(
                            _discovering
                                ? 'Finding local places…'
                                : 'Find more in this area',
                          ),
                        ),
                        const Text(
                          'Checks free sources only when you ask. Coverage and current hours may be incomplete.',
                          style: TextStyle(fontSize: 12),
                        ),
                        if (_discoveryNotice != null) Text(_discoveryNotice!),
                      ],
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
                        onSelect: (p) => openPlace(context, p),
                      ),
                    ),
                  ),
                ),
              ] else
                for (var page = 1; page <= _page; page++)
                  ..._pageSlivers(page, wide),
              if (!_map && _visibleAdditional.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList.builder(
                    itemCount: _visibleAdditional.length,
                    itemBuilder: (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        height: 330,
                        child: PlaceCard(place: _visibleAdditional[index]),
                      ),
                    ),
                  ),
                ),
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
        if (result.items.isEmpty && page == 1 && _visibleAdditional.isEmpty)
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
