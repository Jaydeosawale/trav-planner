import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/explore_api.dart';
import '../../data/models/explore_city.dart';
import '../../data/models/explore_country.dart';
import '../../data/models/explore_state.dart';

final exploreApiProvider = Provider<ExploreApi>((ref) => ExploreApi.instance);

// ============================================================
// Countries
// ============================================================

final exploreCountriesProvider = FutureProvider<List<ExploreCountry>>((
  ref,
) async {
  return ref.read(exploreApiProvider).getActiveCountries();
});

// ============================================================
// States
// ============================================================

final exploreStatesProvider = FutureProvider.family<List<ExploreState>, String>(
  (ref, countryId) async {
    return ref.read(exploreApiProvider).getStatesByCountry(countryId);
  },
);

// ============================================================
// Cities
// ============================================================

final exploreCitiesProvider =
    FutureProvider.family<ExploreCitySearchResult, ExploreCitySearchRequest>((
      ref,
      request,
    ) async {
      return ref
          .read(exploreApiProvider)
          .searchCities(
            search: request.search,
            countryId: request.countryId,
            stateId: request.stateId,
            page: request.page,
            size: request.size,
          );
    });

class ExploreCitySearchRequest {
  final String? search;
  final String? countryId;
  final String? stateId;
  final int page;
  final int size;

  const ExploreCitySearchRequest({
    this.search,
    this.countryId,
    this.stateId,
    this.page = 1,
    this.size = 20,
  });

  @override
  bool operator ==(Object other) {
    return other is ExploreCitySearchRequest &&
        other.search == search &&
        other.countryId == countryId &&
        other.stateId == stateId &&
        other.page == page &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(search, countryId, stateId, page, size);
}
