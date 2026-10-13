import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../data/datasources/admin_ai_billing_api.dart';
import '../../data/models/admin_ai_billing_model.dart';
import 'admin_ai_routing_panel.dart';
import 'admin_discovery_panel.dart';

class AdminAIBillingPage extends StatefulWidget {
  const AdminAIBillingPage({super.key});

  @override
  State<AdminAIBillingPage> createState() => _AdminAIBillingPageState();
}

class _AdminAIBillingPageState extends State<AdminAIBillingPage> {
  final AdminAIBillingApi _api = AdminAIBillingApi();

  AdminAIBillingModel? _billing;
  List<AdminAIBillingAuditLogModel> _auditLogs = [];

  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  String? _success;

  String _provider = 'groq';

  final TextEditingController _dailyBudgetController = TextEditingController();

  final TextEditingController _monthlyBudgetController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBilling();
  }

  @override
  void dispose() {
    _dailyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  Future<void> _loadBilling() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final billing = await _api.getBilling();

      final logs = await _api.getAuditLogs();

      if (!mounted) {
        return;
      }

      setState(() {
        _billing = billing;
        _auditLogs = logs;
        _provider = billing.paidProvider;

        _dailyBudgetController.text = billing.dailyBudget.toString();

        _monthlyBudgetController.text = billing.monthlyBudget.toString();

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _softEnable() async {
    await _runAction(() async {
      final billing = await _api.softEnable(
        paidProvider: _provider,
        dailyBudget: _parseBudget(_dailyBudgetController.text),
        monthlyBudget: _parseBudget(_monthlyBudgetController.text),
      );

      _updateBilling(billing);

      _success = 'Paid AI enabled in SOFT mode.';
    });
  }

  Future<void> _hardEnable() async {
    await _runAction(() async {
      final billing = await _api.hardEnable(
        paidProvider: _provider,
        dailyBudget: _parseBudget(_dailyBudgetController.text),
        monthlyBudget: _parseBudget(_monthlyBudgetController.text),
      );

      _updateBilling(billing);

      _success = 'Paid AI enabled in HARD mode.';
    });
  }

  Future<void> _disable() async {
    await _runAction(() async {
      final billing = await _api.disable();

      _updateBilling(billing);

      _success = 'Paid AI has been disabled.';
    });
  }

  Future<void> _changeProvider() async {
    await _runAction(() async {
      final billing = await _api.setProvider(paidProvider: _provider);

      _updateBilling(billing);

      _success = 'Paid AI provider updated.';
    });
  }

  Future<void> _changeBudget() async {
    await _runAction(() async {
      final billing = await _api.setBudget(
        dailyBudget: _parseBudget(_dailyBudgetController.text),
        monthlyBudget: _parseBudget(_monthlyBudgetController.text),
      );

      _updateBilling(billing);

      _success = 'AI billing budgets updated.';
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_actionLoading) {
      return;
    }

    setState(() {
      _actionLoading = true;
      _error = null;
      _success = null;
    });

    try {
      await action();

      final logs = await _api.getAuditLogs();

      if (!mounted) {
        return;
      }

      setState(() {
        _auditLogs = logs;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  void _updateBilling(AdminAIBillingModel billing) {
    setState(() {
      _billing = billing;
      _provider = billing.paidProvider;
      _dailyBudgetController.text = billing.dailyBudget.toString();
      _monthlyBudgetController.text = billing.monthlyBudget.toString();
    });
  }

  double _parseBudget(String value) {
    return double.tryParse(value.trim()) ?? 0.0;
  }

  String _money(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_billing == null) {
      return _buildErrorState();
    }

    final billing = _billing!;

    return RefreshIndicator(
      onRefresh: _loadBilling,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(billing),

            const SizedBox(height: 24),

            if (_error != null) _buildMessage(_error!, isError: true),

            if (_success != null) _buildMessage(_success!, isError: false),

            const SizedBox(height: 8),

            _buildOverview(billing),

            const SizedBox(height: 24),

            const AdminAIRoutingPanel(),
            const SizedBox(height: 20),
            const AdminDiscoveryPanel(),
            const SizedBox(height: 24),
            const Text(
              'Paid requests are blocked in the current zero-cost release.',
            ),
            Offstage(
              offstage: true,
              child: ExcludeFocus(child: _buildControls(billing)),
            ),

            const SizedBox(height: 24),

            _buildAuditLogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AdminAIBillingModel billing) {
    final enabled = billing.paidEnabled;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Platform',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage AI providers, paid fallback, budgets and usage.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _statusBadge(enabled ? 'PAID AI ENABLED' : 'PAID AI DISABLED', enabled),
      ],
    );
  }

  Widget _buildOverview(AdminAIBillingModel billing) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 48) / 4
            : constraints.maxWidth >= 650
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: width,
              child: _statCard(
                title: 'Billing Mode',
                value: billing.mode.replaceAll('_', ' ').toUpperCase(),
                icon: Icons.tune_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                title: 'Legacy billing provider',
                value: billing.paidProvider.toUpperCase(),
                icon: Icons.smart_toy_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                title: 'Daily Spent',
                value: _money(billing.dailySpent),
                icon: Icons.today_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                title: 'Monthly Spent',
                value: _money(billing.monthlySpent),
                icon: Icons.calendar_month_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(AdminAIBillingModel billing) {
    return _panel(
      title: 'Billing Controls',
      icon: Icons.settings_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paid AI Provider',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _provider,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.smart_toy_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'groq', child: Text('Groq')),
              DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
              DropdownMenuItem(value: 'ollama', child: Text('Ollama')),
            ],
            onChanged: _actionLoading
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _provider = value;
                    });
                  },
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _actionLoading ? null : _changeProvider,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Change Provider'),
            ),
          ),

          const Divider(height: 32),

          const Text(
            'AI Budgets',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 650;

              final fields = [
                Expanded(
                  child: TextField(
                    controller: _dailyBudgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Daily budget (USD)',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _monthlyBudgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monthly budget (USD)',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ];

              if (stacked) {
                return Column(
                  children: [fields[0], const SizedBox(height: 12), fields[1]],
                );
              }

              return Row(
                children: [fields[0], const SizedBox(width: 16), fields[1]],
              );
            },
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _actionLoading ? null : _changeBudget,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Budgets'),
            ),
          ),

          const Divider(height: 32),

          const Text(
            'Paid AI Actions',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _actionLoading ? null : _softEnable,
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text('Enable Soft'),
              ),
              ElevatedButton.icon(
                onPressed: _actionLoading ? null : _hardEnable,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Enable Hard'),
              ),
              OutlinedButton.icon(
                onPressed: _actionLoading ? null : _disable,
                icon: const Icon(Icons.power_settings_new_rounded),
                label: const Text('Disable Paid AI'),
              ),
            ],
          ),

          if (_actionLoading) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],

          const SizedBox(height: 20),

          Text(
            billing.paidEnabled
                ? 'Paid AI is currently available as a fallback after free providers are exhausted.'
                : 'Paid AI is currently blocked. Free providers remain the preferred path.',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogs() {
    return _panel(
      title: 'AI Billing Audit Logs',
      icon: Icons.history_rounded,
      child: _auditLogs.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No billing audit logs yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: _auditLogs.map((log) => _auditLogTile(log)).toList(),
            ),
    );
  }

  Widget _auditLogTile(AdminAIBillingAuditLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceVariant,
            child: Icon(
              Icons.receipt_long_rounded,
              size: 19,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.paidProvider.toUpperCase()} • ${log.newMode}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (log.details != null && log.details!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.details!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (log.createdAt != null)
            Text(
              _formatDate(log.createdAt!),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _statusBadge(String text, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: enabled ? AppColors.successContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: enabled ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  Widget _buildMessage(String message, {required bool isError}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorContainer : AppColors.successContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: isError ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load AI billing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadBilling,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
