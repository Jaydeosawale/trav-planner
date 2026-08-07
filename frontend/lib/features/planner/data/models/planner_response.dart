class PlannerResponse {
  final String destination;
  final int estimatedBudget;
  final List<String> itinerary;

  PlannerResponse({
    required this.destination,
    required this.estimatedBudget,
    required this.itinerary,
  });

  factory PlannerResponse.fromJson(Map<String, dynamic> json) {
    return PlannerResponse(
      destination: json["destination"] as String,
      estimatedBudget: json["estimated_budget"] as int,
      itinerary: List<String>.from(json["itinerary"] as List),
    );
  }
}