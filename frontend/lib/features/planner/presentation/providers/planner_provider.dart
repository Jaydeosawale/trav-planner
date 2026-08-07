import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/planner_api.dart';
import '../../data/repositories/planner_repository_impl.dart';

final plannerRepositoryProvider = Provider(
  (ref) => PlannerRepositoryImpl(
    PlannerApi(),
  ),
);