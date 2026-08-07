import '../../domain/repositories/planner_repository.dart';
import '../datasource/planner_api.dart';
import '../models/planner_response.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  final PlannerApi api;

  PlannerRepositoryImpl(this.api);

  @override
  Future<PlannerResponse> generateTrip({
    required String destination,
    required int days,
    required int budget,
  }) {
    return api.createPlan(
      destination: destination,
      days: days,
      budget: budget,
    );
  }
}