import '../../data/models/planner_request.dart';
import '../../data/models/planner_response.dart';

abstract class PlannerRepository {
  Future<PlannerResponse> createPlan(
    PlannerRequest request,
  );
}