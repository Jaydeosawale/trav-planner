import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../destinations/data/place.dart';
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
  const HomePlacesSection({super.key, this.curated = false});
  final bool curated;
  @override
  ConsumerState<HomePlacesSection> createState() => _HomePlacesSectionState();
}

class _HomePlacesSectionState extends ConsumerState<HomePlacesSection> {
  PlaceQuery _query = const PlaceQuery(photosOnly: false, size: 8);
  int _page = 1;
  AsyncValue<List<TravelPlace>> _local = const AsyncData([]);
  final Map<String, List<TravelPlace>> _localCache = {};
  String? _localKey;
  String? _localNotice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocal());
  }

  Future<void> _loadLocal() async {
    if (!mounted) return;
    final area = ref.read(chosenPlaceAreaProvider);
    if (area?.cityId == null || !ref.read(authProvider).isAuthenticated) {
      setState(() {
        _localKey = null;
        _local = const AsyncData([]);
      });
      return;
    }
    final key = '${area!.cityId}:${_query.type}';
    _localKey = key;
    _localNotice = null;
    if (_localCache.containsKey(key)) {
      setState(() => _local = AsyncData(_localCache[key]!));
      return;
    }
    setState(() => _local = const AsyncLoading());
    try {
      final response = await ref
          .read(placeAreaApiProvider)
          .client
          .get(
            '/discovery/cities/${area.cityId}',
            queryParameters: {
              'kind': _query.type == 'all' ? 'local' : _query.type,
            },
          );
      final found = (response.data['items'] as List)
          .map((p) => TravelPlace.fromJson(Map<String, dynamic>.from(p)))
          .toList();
      _localCache[key] = found;
      if (_localCache.length > 8) _localCache.remove(_localCache.keys.first);
      if (mounted && _localKey == key) {
        setState(() {
          _local = AsyncData(found);
          _localNotice = response.data['message']?.toString();
        });
      }
    } catch (error, stack) {
      if (mounted && _localKey == key) {
        setState(() => _local = AsyncError(error, stack));
      }
    }
  }

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
    if (widget.curated) return;
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
    _loadLocal();
  }

  void _browse() => openPlaceSearch(context, _query);
  @override
  Widget build(BuildContext context) {
    ref.listen<PlaceArea?>(chosenPlaceAreaProvider, (previous, next) {
      if (previous?.cityId != next?.cityId) {
        setState(() => _page = 1);
        _loadLocal();
      }
    });
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) _loadLocal();
    });
    final area = ref.watch(chosenPlaceAreaProvider);
    final effectiveQuery = _query.copyWith(
      cityId: area?.cityId,
      clearCity: area?.cityId == null,
    );

    final first = ref.watch(
      placeCatalogueProvider(effectiveQuery.copyWith(page: 1)),
    );
    if (widget.curated &&
        first.asData?.value.items.isEmpty == true &&
        !_local.isLoading &&
        (_local.asData?.value.isEmpty ?? true) &&
        !_local.hasError) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.curated
                    ? (area == null
                          ? 'Travel inspiration'
                          : 'Around ${area.name}')
                    : (area == null
                          ? 'Places to explore'
                          : 'Explore ${area.name}'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (!widget.curated)
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
        if (!widget.curated)
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
                data: (result) =>
                    result.items.isEmpty &&
                        (_local.isLoading ||
                            (_local.asData?.value.isNotEmpty ?? false))
                    ? const SizedBox.shrink()
                    : result.items.isEmpty
                    ? widget.curated
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    area == null
                                        ? 'Find places in a town you want to visit.'
                                        : 'No local places loaded here yet.',
                                  ),
                                  TextButton(
                                    onPressed: () => openPlaceSearch(
                                      context,
                                      effectiveQuery,
                                      focusSearch: true,
                                    ),
                                    child: const Text('Search a town'),
                                  ),
                                ],
                              ),
                            )
                          : Container(
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
                                      onPressed: () => _change(
                                        _query.copyWith(photosOnly: false),
                                      ),
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
                          if (widget.curated)
                            SizedBox(
                              height:
                                  290 +
                                  (MediaQuery.textScalerOf(context).scale(14) -
                                          14) *
                                      6,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: result.items.length > 4
                                    ? 4
                                    : result.items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (_, i) => SizedBox(
                                  width: 250,
                                  child: PlaceCard(place: result.items[i]),
                                ),
                              ),
                            )
                          else
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
                          if (!widget.curated &&
                              page == _page &&
                              page < result.pages)
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
        _local.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: _loadLocal,
            child: const Text('Retry local places'),
          ),
          data: (items) {
            final known = <String>{};
            for (var page = 1; page <= _page; page++) {
              known.addAll(
                ref
                        .watch(
                          placeCatalogueProvider(
                            effectiveQuery.copyWith(page: page),
                          ),
                        )
                        .asData
                        ?.value
                        .items
                        .map((p) => p.id) ??
                    <String>[],
              );
            }
            final extra = items
                .where(
                  (p) =>
                      !known.contains(p.id) &&
                      (!_query.photosOnly || p.imageUrl != null),
                )
                .toList();
            if (extra.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                if (widget.curated)
                  SizedBox(
                    height:
                        290 +
                        (MediaQuery.textScalerOf(context).scale(14) - 14) * 6,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: extra.length > 4 ? 4 : extra.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => SizedBox(
                        width: 250,
                        child: PlaceCard(place: extra[i]),
                      ),
                    ),
                  )
                else
                  for (final place in extra)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        height:
                            330 +
                            (MediaQuery.textScalerOf(context).scale(14) - 14) *
                                6,
                        child: PlaceCard(place: place),
                      ),
                    ),
                PlaceSourceCredit(
                  data: extra.map((p) => p.visitingNotes).toList(),
                ),
              ],
            );
          },
        ),
        if (_localNotice != null && !(_local.asData?.value.isNotEmpty ?? false))
          Text(_localNotice!, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
