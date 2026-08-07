import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/home_mock_data.dart';

final destinationsProvider = Provider(
  (ref) => HomeMockData.destinations,
);