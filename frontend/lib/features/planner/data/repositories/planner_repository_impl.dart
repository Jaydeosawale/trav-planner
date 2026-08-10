import '../../domain/repositories/planner_repository.dart';
import '../datasources/planner_api.dart';
import '../models/planner_request.dart';
import '../models/planner_response.dart';

class PlannerRepositoryImpl
    implements PlannerRepository {
  final PlannerApi api;

  PlannerRepositoryImpl(this.api);

  @override
  Future<PlannerResponse> createPlan(
    PlannerRequest request,
  ) {
    return api.createPlan(request);
  }
}