class PlannerResponse {
  final String id;
  final String userId;
  final String destinationId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;
  final double? budgetAmount;
  final String budgetCurrency;
  final String? travelStyle;
  final String? preferences;
  final String status;

  const PlannerResponse({
    required this.id,
    required this.userId,
    required this.destinationId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    this.budgetAmount,
    required this.budgetCurrency,
    this.travelStyle,
    this.preferences,
    required this.status,
  });

  factory PlannerResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return PlannerResponse(
      id: json["id"] as String,
      userId: json["user_id"] as String,
      destinationId: json["destination_id"] as String,
      title: json["title"] as String,
      startDate: DateTime.parse(
        json["start_date"] as String,
      ),
      endDate: DateTime.parse(
        json["end_date"] as String,
      ),
      travelers: json["travelers"] as int,
      budgetAmount: json["budget_amount"] == null
          ? null
          : (json["budget_amount"] as num).toDouble(),
      budgetCurrency: json["budget_currency"] as String,
      travelStyle: json["travel_style"] as String?,
      preferences: json["preferences"] as String?,
      status: json["status"] as String,
    );
  }
}