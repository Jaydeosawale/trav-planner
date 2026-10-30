import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/destinations/data/place.dart';
import '../../features/places/data/place_catalogue.dart';
import '../../features/places/presentation/browse_places_page.dart';
import '../../features/places/presentation/place_details_page.dart';
import '../../features/trips/presentation/pages/trip_details_page.dart';

Uri placeSearchUri(PlaceQuery query) => Uri(
  path: '/explore',
  queryParameters: {
    if (query.search.isNotEmpty) 'search': query.search,
    if (query.countryId != null) 'country': query.countryId,
    if (query.cityId != null) 'city': query.cityId,
    if (query.type != 'all') 'category': query.type,
    if (query.photosOnly) 'photos': 'true',
  },
);

void openPlaceSearch(
  BuildContext context,
  PlaceQuery query, {
  bool focusSearch = false,
}) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    final uri = placeSearchUri(query);
    router.go(
      uri
          .replace(
            queryParameters: {
              ...uri.queryParameters,
              if (focusSearch) 'focus': 'true',
            },
          )
          .toString(),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BrowsePlacesPage(initialQuery: query, focusSearch: focusSearch),
      ),
    );
  }
}

void openPlace(BuildContext context, TravelPlace place) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.push('/places/${Uri.encodeComponent(place.id)}', extra: place);
  } else {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlaceDetailsPage(place: place)));
  }
}

void openTrip(BuildContext context, String id) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.push('/trips/${Uri.encodeComponent(id)}');
  } else {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TripDetailsPage(id: id)));
  }
}
