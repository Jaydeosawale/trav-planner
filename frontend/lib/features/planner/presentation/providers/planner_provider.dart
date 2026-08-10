import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/planner_api.dart';
import '../../data/repositories/planner_repository_impl.dart';

final plannerRepositoryProvider =
    Provider<PlannerRepositoryImpl>(
  (ref) {
    return PlannerRepositoryImpl(
      PlannerApi(),
    );
  },
);