import 'package:flutter/material.dart';
import '../../../auth/presentation/widgets/require_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/trips_api.dart';

final tripsApiProvider = Provider<TripsApi>((ref) => TripsApi());

class TripEditorPage extends ConsumerStatefulWidget {
  const TripEditorPage({
    super.key,
    this.trip,
    this.draftNotes,
    this.initialCity,
  });
  final Map<String, dynamic>? initialCity;
  final Map<String, dynamic>? trip;
  final String? draftNotes;
  @override
  ConsumerState<TripEditorPage> createState() => _TripEditorPageState();
}

class _TripEditorPageState extends ConsumerState<TripEditorPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _query = TextEditingController(),
      _travelers = TextEditingController(),
      _budget = TextEditingController(),
      _currency = TextEditingController(),
      _notes = TextEditingController();
  DateTime? _start, _end;
  Map<String, dynamic>? _city;
  List<Map<String, dynamic>> _cities = [];
  bool _loading = false, _saving = false;
  String? _error;
  String _status = 'planned';
  @override
  void initState() {
    super.initState();
    final trip = widget.trip ?? {};
    _city = widget.initialCity;
    _query.text = _city?['name']?.toString() ?? '';
    _title.text =
        trip['title']?.toString() ??
        (_city == null ? '' : '${_city!['name']} trip');
    _travelers.text = (trip['travelers'] ?? 1).toString();
    _budget.text = trip['budget_amount']?.toString() ?? '';
    _currency.text = trip['budget_currency']?.toString() ?? 'INR';
    _notes.text = trip['notes']?.toString() ?? widget.draftNotes ?? '';
    _start = DateTime.tryParse(trip['start_date']?.toString() ?? '');
    _end = DateTime.tryParse(trip['end_date']?.toString() ?? '');
    _status = trip['status']?.toString() ?? 'planned';
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _query,
      _travelers,
      _budget,
      _currency,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _date(DateTime? value) => value == null
      ? 'Choose date'
      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  Future<void> _pick(bool start) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null && mounted) {
      setState(() {
        if (start) {
          _start = selected;
        } else {
          _end = selected;
        }
      });
    }
  }

  Future<void> _search() async {
    if (_loading || _query.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cities = await ref
          .read(tripsApiProvider)
          .cities(_query.text.trim());
      if (mounted) {
        setState(() {
          _cities = cities;
          if (cities.isEmpty) _error = 'No cities found. Try another name.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Couldn’t search cities. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_city == null && widget.trip == null) {
      setState(() => _error = 'Search and select a city for this trip.');
      return;
    }
    if (_start == null || _end == null || _end!.isBefore(_start!)) {
      setState(
        () => _error = 'Choose dates with the end on or after the start.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final payload = <String, dynamic>{
      'title': _title.text.trim(),
      'start_date': _date(_start),
      'end_date': _date(_end),
      'travelers': int.parse(_travelers.text),
      'budget_amount': _budget.text.trim().isEmpty ? null : _budget.text.trim(),
      'budget_currency': _currency.text.trim().toUpperCase(),
      'notes': _notes.text.trim(),
      if (_city != null) 'city_id': _city!['id'],
      if (widget.trip != null) 'status': _status,
    };
    try {
      if (!await ensureSignedIn(context, ref) || !mounted) return;
      final trip = await ref
          .read(tripsApiProvider)
          .save(payload, id: widget.trip?['id']?.toString());
      if (mounted) Navigator.of(context).pop(trip);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Couldn’t save this trip. Your draft is still here. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.draftNotes != null
            ? 'Review AI draft'
            : widget.trip == null
            ? 'Create a trip'
            : 'Edit trip',
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.draftNotes != null
                      ? 'Make this plan yours.'
                      : 'Make room for adventure.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (widget.draftNotes != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Review the draft notes below, then choose a destination and dates. This saves the suggestion to My Trips; day-by-day activities can be added separately.',
                  ),
                ],
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  key: const ValueKey('trip-title'),
                  controller: _title,
                  enabled: !_saving,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Trip name'),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Add a name with at least two characters.'
                      : null,
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const ValueKey('trip-city-search'),
                  controller: _query,
                  enabled: !_saving,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    labelText: widget.trip == null
                        ? 'Destination city'
                        : 'Change destination city (optional)',
                    hintText: 'Search any city',
                    suffixIcon: IconButton(
                      tooltip: 'Search cities',
                      onPressed: _loading ? null : _search,
                      icon: const Icon(Icons.search),
                    ),
                  ),
                ),
                if (_loading) const LinearProgressIndicator(),
                if (_city != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Selected: ${_city!['name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                if (_cities.isNotEmpty)
                  ..._cities.map(
                    (city) => ListTile(
                      selected: _city?['id'] == city['id'],
                      leading: const Icon(Icons.location_city_outlined),
                      title: Text(city['name'].toString()),
                      subtitle: Text(
                        city['country']?.toString() ?? 'Select this city',
                      ),
                      onTap: _saving
                          ? null
                          : () => setState(() {
                              _city = city;
                              _cities = [];
                            }),
                    ),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pick(true),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('Start: ${_date(_start)}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pick(false),
                      icon: const Icon(Icons.event_outlined),
                      label: Text('End: ${_date(_end)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _travelers,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Travelers'),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                      ? 'Enter at least one traveler.'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _budget,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Planned budget (optional)',
                  ),
                  validator: (value) =>
                      value?.trim().isNotEmpty == true &&
                          ((double.tryParse(value!) ?? -1) < 0 ||
                              !(double.tryParse(value) ?? double.nan).isFinite)
                      ? 'Enter a valid non-negative amount.'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _currency,
                  enabled: !_saving,
                  maxLength: 3,
                  decoration: const InputDecoration(
                    labelText: 'Currency code',
                    hintText: 'INR, USD, EUR…',
                  ),
                  validator: (value) =>
                      RegExp(r'^[A-Za-z]{3}$').hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Use a three-letter currency code.',
                ),
                const SizedBox(height: 18),
                if (widget.trip != null)
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Trip status'),
                    items:
                        {
                              'draft',
                              'planned',
                              'ongoing',
                              'completed',
                              'cancelled',
                              _status,
                            }
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                    onChanged: _saving
                        ? null
                        : (value) =>
                              setState(() => _status = value ?? 'planned'),
                  ),
                const SizedBox(height: 18),
                TextFormField(
                  key: const ValueKey('trip-notes'),
                  controller: _notes,
                  enabled: !_saving,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 30000,
                  validator: (value) => (value?.length ?? 0) > 30000
                      ? 'Shorten the notes to 30,000 characters before saving.'
                      : null,
                  decoration: const InputDecoration(labelText: 'Trip notes'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save trip'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
