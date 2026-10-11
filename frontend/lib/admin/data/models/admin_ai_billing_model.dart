class AdminAIBillingModel {
  final bool paidEnabled;
  final String mode;
  final String paidProvider;

  final double dailyBudget;
  final double monthlyBudget;

  final double dailySpent;
  final double monthlySpent;

  final String? updatedBy;

  const AdminAIBillingModel({
    required this.paidEnabled,
    required this.mode,
    required this.paidProvider,
    required this.dailyBudget,
    required this.monthlyBudget,
    required this.dailySpent,
    required this.monthlySpent,
    required this.updatedBy,
  });

  factory AdminAIBillingModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminAIBillingModel(
      paidEnabled: json['paid_enabled'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'free_only',
      paidProvider:
          json['paid_provider'] as String? ?? 'groq',
      dailyBudget: _parseDouble(json['daily_budget']),
      monthlyBudget: _parseDouble(json['monthly_budget']),
      dailySpent: _parseDouble(json['daily_spent']),
      monthlySpent: _parseDouble(json['monthly_spent']),
      updatedBy: json['updated_by'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }
}
