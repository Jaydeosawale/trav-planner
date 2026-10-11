import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/banner_api.dart';
import '../../data/datasources/destination_api.dart';
import '../../data/models/banner_model.dart';
import '../../data/models/destination_model.dart';

final destinationApiProvider = Provider<DestinationApi>(
  (ref) {
    return DestinationApi();
  },
);

final destinationsProvider =
    FutureProvider<List<DestinationModel>>(
  (ref) async {
    final api = ref.read(
      destinationApiProvider,
    );

    return api.getDestinations();
  },
);

final bannerApiProvider = Provider<BannerApi>(
  (ref) {
    return BannerApi();
  },
);

final bannersProvider =
    FutureProvider<List<BannerModel>>(
  (ref) async {
    final api = ref.read(
      bannerApiProvider,
    );

    return api.getBanners();
  },
);