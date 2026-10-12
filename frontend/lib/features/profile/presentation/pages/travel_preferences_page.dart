import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/travel_preferences_api.dart';

final travelPreferencesApiProvider = Provider<TravelPreferencesApi>(
  (ref) => TravelPreferencesApi(),
);
final travelPreferencesProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  if (ref.watch(authProvider.select((auth) => auth.user?.id)) == null) {
    return {};
  }
  return ref.watch(travelPreferencesApiProvider).load();
});

class TravelPreferencesPage extends ConsumerStatefulWidget {
  const TravelPreferencesPage({super.key});
  @override
  ConsumerState<TravelPreferencesPage> createState() =>
      _TravelPreferencesPageState();
}

class _TravelPreferencesPageState extends ConsumerState<TravelPreferencesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(travelPreferencesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authProvider).user?.id;
    final profile = ref.watch(travelPreferencesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Preferences')),
      body: account == null
          ? const Center(
              child: Text('Sign in to edit your travel preferences.'),
            )
          : profile.when(
              skipLoadingOnReload: false,
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('We couldn’t load your preferences.'),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(travelPreferencesProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
              data: (data) => _PreferencesForm(
                key: ValueKey(account),
                account: account,
                data: data,
              ),
            ),
    );
  }
}

class _PreferencesForm extends ConsumerStatefulWidget {
  const _PreferencesForm({
    super.key,
    required this.account,
    required this.data,
  });
  final String account;
  final Map<String, dynamic> data;
  @override
  ConsumerState<_PreferencesForm> createState() => _PreferencesFormState();
}

class _PreferencesFormState extends ConsumerState<_PreferencesForm> {
  final _form = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final _choices = <String, String>{};
  final _interests = <String>{};
  String _mood = '';
  bool _saving = false;
  static const _fields = {
    'travel_style': (
      'Travel style',
      ['Solo', 'Couple', 'Family', 'Friends', 'Flexible'],
    ),
    'budget_level': (
      'Budget preference',
      ['Budget-friendly', 'Comfort', 'Premium', 'Flexible'],
    ),
    'preferred_transport': (
      'Getting around',
      ['Public transport', 'Walking', 'Car', 'Train', 'Flexible'],
    ),
    'accommodation_preference': (
      'Places to stay',
      ['Hotel', 'Hostel', 'Apartment', 'Homestay', 'Flexible'],
    ),
    'food_preference': (
      'Food preferences',
      ['Vegetarian', 'Vegan', 'Local food', 'No preference'],
    ),
  };
  static const _topics = [
    'Nature',
    'Beaches',
    'Culture',
    'Heritage',
    'Food',
    'Adventure',
    'Shopping',
    'Art',
  ];

  @override
  void initState() {
    super.initState();
    for (final field in _fields.keys) {
      _choices[field] = widget.data[field]?.toString() ?? '';
    }
    _interests.addAll(
      (widget.data['interests']?.toString() ?? '')
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );
    final other = widget.data['other_preferences']?.toString() ?? '';
    // Preserve existing free-text notes; structured choices use a versioned envelope.
    try {
      final parsed = jsonDecode(other);
      if (parsed is Map && parsed['trav_preferences_version'] == 1) {
        _notes.text = parsed['notes']?.toString() ?? '';
        _mood = parsed['mood']?.toString() ?? '';
      } else {
        _notes.text = other;
      }
    } catch (_) {
      _notes.text = other;
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      for (final field in _choices.entries)
        field.key: field.value.isEmpty ? null : field.value,
      'interests': _interests.isEmpty ? null : _interests.join(', '),
      'other_preferences': _mood.isEmpty && _notes.text.trim().isEmpty
          ? null
          : jsonEncode({
              'trav_preferences_version': 1,
              'mood': _mood,
              'notes': _notes.text.trim(),
            }),
    };
    try {
      await ref.read(travelPreferencesApiProvider).save(payload);
      if (!mounted || ref.read(authProvider).user?.id != widget.account) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Travel preferences saved.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t save preferences. Your choices are still here—try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
                'Travel your way.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep your choices ready for future plans. Everything here is optional.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Text(
                'What draws you in?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: {..._topics, ..._interests}
                    .map(
                      (topic) => FilterChip(
                        label: Text(topic),
                        selected: _interests.contains(topic),
                        onSelected: _saving
                            ? null
                            : (selected) => setState(() {
                                if (selected) {
                                  _interests.add(topic);
                                } else {
                                  _interests.remove(topic);
                                }
                              }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              for (final field in _fields.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: DropdownButtonFormField<String>(
                    initialValue: _choices[field.key],
                    isExpanded: true,
                    decoration: InputDecoration(labelText: field.value.$1),
                    items:
                        {
                              '',
                              ...field.value.$2,
                              if (_choices[field.key]!.isNotEmpty)
                                _choices[field.key]!,
                            }
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(
                                  option.isEmpty ? 'No preference' : option,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: _saving
                        ? null
                        : (value) =>
                              setState(() => _choices[field.key] = value ?? ''),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                'Your current travel mood',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose it yourself, or leave it open. You can change this whenever you like.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    {
                          '',
                          'Relaxed',
                          'Adventurous',
                          'Curious',
                          if (_mood.isNotEmpty) _mood,
                        }
                        .map(
                          (mood) => ChoiceChip(
                            label: Text(
                              mood.isEmpty ? 'Open to anything' : mood,
                            ),
                            selected: _mood == mood,
                            onSelected: _saving
                                ? null
                                : (_) => setState(() => _mood = mood),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _notes,
                enabled: !_saving,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Anything else?',
                  hintText:
                      'A slower pace, favorite activities, or other preferences',
                ),
                validator: (value) => (value?.length ?? 0) > 1000
                    ? 'Keep notes within 1,000 characters.'
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save preferences'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
