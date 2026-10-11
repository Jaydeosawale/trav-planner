import '../../../core/network/api_client.dart';
import '../models/admin_ai_billing_model.dart';

class AdminAIBillingApi {
  // ==========================================================
  // GET CURRENT BILLING STATE
  // ==========================================================

  Future<AdminAIBillingModel> getBilling() async {
    final response = await ApiClient.dio.get(
      '/admin/ai-billing',
    );

    final data = response.data;

    return AdminAIBillingModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // SOFT ENABLE
  // ==========================================================

  Future<AdminAIBillingModel> softEnable({
    required String paidProvider,
    required double dailyBudget,
    required double monthlyBudget,
  }) async {
    final response = await ApiClient.dio.post(
      '/admin/ai-billing/soft-enable',
      data: {
        'paid_provider': paidProvider,
        'daily_budget': dailyBudget,
        'monthly_budget': monthlyBudget,
      },
    );

    final data = response.data;

    return AdminAIBillingModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // HARD ENABLE
  // ==========================================================

  Future<AdminAIBillingModel> hardEnable({
    required String paidProvider,
    required double dailyBudget,
    required double monthlyBudget,
  }) async {
    final response = await ApiClient.dio.post(
      '/admin/ai-billing/hard-enable',
      data: {
        'paid_provider': paidProvider,
        'daily_budget': dailyBudget,
        'monthly_budget': monthlyBudget,
      },
    );

    final data = response.data;

    return AdminAIBillingModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // DISABLE
  // ==========================================================

  Future<AdminAIBillingModel> disable() async {
    final response = await ApiClient.dio.post(
      '/admin/ai-billing/disable',
    );

    final data = response.data;

    return AdminAIBillingModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // CHANGE PROVIDER
  // ==========================================================

  Future<AdminAIBillingModel> setProvider({
    required String paidProvider,
  }) async {
    final response = await ApiClient.dio.patch(
      '/admin/ai-billing/provider',
      data: {
        'paid_provider': paidProvider,
      },
    );

    final data = response.data;

    return AdminAIBillingModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // CHANGE BUDGET
  // ==========================================================

  Future<AdminAIBillingModel> setBudget({
    double? dailyBudget,
    double? monthlyBudget,
  }) async {
    final payload = <String, dynamic>{};

    if (dailyBudget != null) {
      payload['daily_budget'] = dailyBudget;
    }

    if (monthlyBudget != null) {
      payload['monthly_budget'] = monthlyBudget;
    }

    final response = await ApiClient.dio.patch(
      '/admin/ai-billing/budget',
      data: payload,
    );

    final data = response.data;

    return AdminAIBillingModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // AUDIT LOGS
  // ==========================================================

  Future<List<AdminAIBillingAuditLogModel>> getAuditLogs({
    int limit = 50,
  }) async {
    final response = await ApiClient.dio.get(
      '/admin/ai-billing/audit-logs',
      queryParameters: {
        'limit': limit,
      },
    );

    final data = response.data;

    final items = data as List<dynamic>? ?? [];

    return items
        .map(
          (item) =>
              AdminAIBillingAuditLogModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}

class AdminAIBillingAuditLogModel {
  final String id;
  final String action;

  final String? previousMode;
  final String newMode;

  final bool paidEnabled;
  final String paidProvider;

  final double dailyBudget;
  final double monthlyBudget;

  final String? adminId;
  final String? details;
  final DateTime? createdAt;

  const AdminAIBillingAuditLogModel({
    required this.id,
    required this.action,
    required this.previousMode,
    required this.newMode,
    required this.paidEnabled,
    required this.paidProvider,
    required this.dailyBudget,
    required this.monthlyBudget,
    required this.adminId,
    required this.details,
    required this.createdAt,
  });

  factory AdminAIBillingAuditLogModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminAIBillingAuditLogModel(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      previousMode: json['previous_mode'] as String?,
      newMode: json['new_mode'] as String? ?? '',
      paidEnabled:
          json['paid_enabled'] as bool? ?? false,
      paidProvider:
          json['paid_provider'] as String? ?? '',
      dailyBudget:
          _parseDouble(json['daily_budget']),
      monthlyBudget:
          _parseDouble(json['monthly_budget']),
      adminId: json['admin_id'] as String?,
      details: json['details'] as String?,
      createdAt:
          _parseDate(json['created_at']),
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
