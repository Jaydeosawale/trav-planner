class PlannerRequest {
  final String destinationId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;
  final double? budgetAmount;
  final String budgetCurrency;
  final String? travelStyle;
  final String? preferences;

  const PlannerRequest({
    required this.destinationId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    this.budgetAmount,
    required this.budgetCurrency,
    this.travelStyle,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      "destination_id": destinationId,
      "title": title,
      "start_date": _formatDate(startDate),
      "end_date": _formatDate(endDate),
      "travelers": travelers,
      "budget_amount": budgetAmount,
      "budget_currency": budgetCurrency,
      "travel_style": travelStyle,
      "preferences": preferences,
    };
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, "0");
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");

    return "$year-$month-$day";
  }
}