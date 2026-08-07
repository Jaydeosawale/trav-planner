import '../../data/models/planner_response.dart';

abstract class PlannerRepository {
  Future<PlannerResponse> generateTrip({
    required String destination,
    required int days,
    required int budget,
  });
}