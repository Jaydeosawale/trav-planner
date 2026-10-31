import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'trip_editor_page.dart';

/// Edit the planned budget directly without rebuilding the trip or calling AI.
class TripBudgetPage extends ConsumerStatefulWidget {
  const TripBudgetPage({super.key, required this.trip});
  final Map<String, dynamic> trip;
  @override
  ConsumerState<TripBudgetPage> createState() => _TripBudgetPageState();
}

class _TripBudgetPageState extends ConsumerState<TripBudgetPage> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.trip['budget_amount']?.toString() ?? '',
  );
  late final _currency = TextEditingController(
    text: widget.trip['budget_currency']?.toString() ?? '',
  );
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _amount.dispose();
    _currency.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final account = ref.read(authProvider).user?.id;
    if (account == null) {
      setState(() => _error = 'Sign in again to update this trip.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref.read(tripsApiProvider).save({
        'budget_amount': _amount.text.trim().isEmpty
            ? null
            : _amount.text.trim(),
        'budget_currency': _currency.text.trim().toUpperCase(),
      }, id: widget.trip['id'].toString());
      if (mounted && account == ref.read(authProvider).user?.id) {
        Navigator.pop(context, updated);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Couldn’t save the budget. Your changes are kept; try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final travelers = (widget.trip['travelers'] as num?)?.toInt() ?? 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Trip budget')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.trip['title']?.toString() ?? 'Your trip',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Plan for $travelers ${travelers == 1 ? 'traveler' : 'travelers'}. This amount is a budget, not a live price quote.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const ValueKey('budget-amount'),
                      controller: _amount,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Total planned budget',
                        hintText: 'Leave empty if undecided',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final amount = double.tryParse(v.trim());
                        return amount == null || !amount.isFinite || amount < 0
                            ? 'Enter a valid non-negative amount.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('budget-currency'),
                      controller: _currency,
                      enabled: !_saving,
                      maxLength: 3,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        hintText: 'INR, EUR, USD…',
                      ),
                      validator: (v) =>
                          RegExp(r'^[A-Za-z]{3}$').hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Enter a three-letter currency code.',
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save budget'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
