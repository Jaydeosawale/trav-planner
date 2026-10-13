import 'package:flutter/material.dart';
import '../../data/datasources/ai_api.dart';

class TripBriefPage extends StatefulWidget {
  const TripBriefPage({super.key, required this.api, this.session});
  final AIApi api;
  final Map<String, dynamic>? session;
  @override
  State<TripBriefPage> createState() => _TripBriefPageState();
}

class _TripBriefPageState extends State<TripBriefPage> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  bool _saving = false;
  String? _error;
  static const labels = {
    'title': 'Plan name',
    'origin': 'Starting from',
    'destination': 'Destination',
    'dates': 'Dates or flexibility',
    'travelers': 'Travelers',
    'budget': 'Budget and currency',
    'transport': 'Travel choices',
    'interests': 'Interests and mood',
    'food': 'Food preferences',
    'pace': 'Travel pace',
  };
  @override
  void initState() {
    super.initState();
    final brief = widget.session?['brief'] as Map? ?? {};
    for (final key in labels.keys) {
      _fields[key] = TextEditingController(
        text: key == 'title'
            ? (widget.session?['title']?.toString() ?? 'My travel ideas')
            : (brief[key]?.toString() ?? (key == 'travelers' ? '1' : '')),
      );
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.api.saveBrief({
        'title': _fields['title']!.text.trim(),
        'brief': {
          for (final key in labels.keys.where((k) => k != 'title'))
            key: key == 'travelers'
                ? int.parse(_fields[key]!.text.trim())
                : _fields[key]!.text.trim(),
        },
        if (widget.session != null) 'version': widget.session!['version'],
      }, id: widget.session?['id']?.toString());
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Couldn’t save. Your draft is still here. If another screen edited this plan, reopen it from Recent plans.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your trip brief')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'A trip that fits you.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Add what you know. Leave undecided details empty. This brief and recent messages are saved to your account and sent to the AI when you ask for a plan.',
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                for (final entry in labels.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      key: ValueKey('brief-${entry.key}'),
                      controller: _fields[entry.key],
                      enabled: !_saving,
                      maxLength: entry.key == 'title'
                          ? 120
                          : entry.key == 'interests'
                          ? 500
                          : entry.key == 'food'
                          ? 300
                          : entry.key == 'pace'
                          ? 100
                          : 200,
                      decoration: InputDecoration(
                        labelText: entry.value,
                        hintText: entry.key == 'transport'
                            ? 'Flight, train, bus, car, walking…'
                            : entry.key == 'budget'
                            ? 'For example: INR 20,000 total'
                            : null,
                      ),
                      validator: (value) {
                        if (entry.key == 'title' &&
                            (value?.trim().isEmpty ?? true)) {
                          return 'Give this plan a name.';
                        }
                        if (entry.key == 'travelers') {
                          final count = int.tryParse(value?.trim() ?? '');
                          if (count == null || count < 1 || count > 100) {
                            return 'Enter 1–100 travelers.';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save brief'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
