import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../destinations/data/place.dart';
import '../../../maps/places_map.dart';
import '../../../saved/presentation/saved_places_provider.dart';
import '../../../trips/presentation/pages/trip_details_page.dart';
import '../../data/itinerary_api.dart';

final itineraryApiProvider = Provider<ItineraryApi>((ref) => ItineraryApi());
final itineraryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) async {
      ref.watch(authProvider.select((auth) => auth.user?.id));
      return ref.watch(itineraryApiProvider).load(id);
    });

class ItineraryPage extends ConsumerStatefulWidget {
  const ItineraryPage({super.key, required this.tripId});
  final String tripId;
  @override
  ConsumerState<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends ConsumerState<ItineraryPage> {
  bool _busy = false, _map = false;
  Future<void> _change(Future<void> Function(ItineraryApi) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(ref.read(itineraryApiProvider));
      ref.invalidate(itineraryProvider(widget.tripId));
      await ref.read(itineraryProvider(widget.tripId).future);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t update the day plan. Refresh and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: const Text('This removes it from your day plan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _day(
    Map<String, dynamic> trip, {
    Map<String, dynamic>? existing,
  }) async {
    final start = DateTime.parse(trip['start_date']),
        end = DateTime.parse(trip['end_date']);
    var initial =
        DateTime.tryParse(existing?['date']?.toString() ?? '') ?? start;
    if (initial.isBefore(start) || initial.isAfter(end)) initial = start;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: start,
      lastDate: end,
    );
    if (date == null || !mounted) return;
    var draftTitle = existing?['title']?.toString() ?? '';
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add a day' : 'Edit day'),
        content: TextFormField(
          initialValue: draftTitle,
          onChanged: (value) => draftTitle = value,
          maxLength: 200,
          decoration: const InputDecoration(labelText: 'Day title (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, draftTitle.trim()),
            child: const Text('Save day'),
          ),
        ],
      ),
    );
    if (title == null || !mounted) return;
    await _change(
      (api) => api.saveDay(widget.tripId, {
        'date': date.toIso8601String().split('T').first,
        'day_number': date.difference(start).inDays + 1,
        'title': title,
      }, id: existing?['id']?.toString()),
    );
  }

  Future<void> _activity(String dayId, {Map<String, dynamic>? existing}) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ActivityDialog(item: existing),
    );
    if (data != null && mounted) {
      await _change(
        (api) => api.saveItem(dayId, data, id: existing?['id']?.toString()),
      );
    }
  }

  Future<void> _saved(String dayId) async {
    try {
      final places = await ref.read(savedPlacesProvider.future);
      if (!mounted) return;
      final selected = await showModalBottomSheet<TravelPlace>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SizedBox(
            height: 400,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Add a saved place',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (places.isEmpty)
                  const Text(
                    'Save a place from its destination details first, then add it here.',
                  ),
                ...places.map(
                  (place) => ListTile(
                    title: Text(place.name),
                    subtitle: Text(place.type.replaceAll('_', ' ')),
                    onTap: () => Navigator.pop(context, place),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (selected != null && mounted) {
        await _change(
          (api) => api.saveItem(dayId, {
            'title': selected.name,
            'place_id': selected.id,
            'activity_type': selected.type,
          }),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn’t load saved places. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _move(Map<String, dynamic> day, int index, int offset) async {
    final ids = (day['items'] as List)
        .map((item) => item['id'].toString())
        .toList();
    final next = index + offset;
    if (next < 0 || next >= ids.length) return;
    final moved = ids.removeAt(index);
    ids.insert(next, moved);
    await _change((api) => api.order(day['id'], ids));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Day-by-day plan')),
    body: ref
        .watch(tripDetailsProvider(widget.tripId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Trip unavailable.')),
          data: (trip) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(itineraryProvider(widget.tripId));
              await ref.read(itineraryProvider(widget.tripId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          trip['title'].toString(),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: _busy ? null : () => _day(trip),
                              icon: const Icon(Icons.add),
                              label: const Text('Add day'),
                            ),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Timeline'),
                                  icon: Icon(Icons.view_list_outlined),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Map'),
                                  icon: Icon(Icons.map_outlined),
                                ),
                              ],
                              selected: {_map},
                              onSelectionChanged: (value) =>
                                  setState(() => _map = value.first),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_busy) const LinearProgressIndicator(),
                        ref
                            .watch(itineraryProvider(widget.tripId))
                            .when(
                              skipLoadingOnRefresh: false,
                              skipLoadingOnReload: false,
                              loading: () => const Padding(
                                padding: EdgeInsets.all(30),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (_, _) => Column(
                                children: [
                                  const Text(
                                    'Your day plan couldn’t be loaded.',
                                  ),
                                  TextButton(
                                    onPressed: () => ref.invalidate(
                                      itineraryProvider(widget.tripId),
                                    ),
                                    child: const Text('Try again'),
                                  ),
                                ],
                              ),
                              data: (days) {
                                if (_map) {
                                  final places = days
                                      .expand((day) => day['items'] as List)
                                      .map(
                                        (item) => TravelPlace(
                                          id: item['id'],
                                          name: item['title'],
                                          type:
                                              item['activity_type'] ??
                                              'activity',
                                          description: item['description'],
                                          point: validCoordinates(
                                            item['latitude'],
                                            item['longitude'],
                                          ),
                                        ),
                                      )
                                      .toList();
                                  return Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: SizedBox(
                                          height: 400,
                                          child: PlacesMap(
                                            places: places,
                                            onSelect: (place) => showDialog<void>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(place.name),
                                                content: Text(
                                                  place.description ??
                                                      'Added to your itinerary.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (places.any(
                                        (place) => place.point == null,
                                      ))
                                        const Padding(
                                          padding: EdgeInsets.all(14),
                                          child: Text(
                                            'Activities without a location remain available in the timeline.',
                                          ),
                                        ),
                                    ],
                                  );
                                }
                                if (days.isEmpty) {
                                  return const Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(28),
                                      child: Text(
                                        'Start with a day, then add saved places or your own activities.',
                                      ),
                                    ),
                                  );
                                }
                                return Column(
                                  children: days
                                      .map(
                                        (day) => Card(
                                          margin: const EdgeInsets.only(
                                            bottom: 18,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(18),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  'Day ${day['day_number']} · ${day['date']}',
                                                  style: const TextStyle(
                                                    color: AppColors.secondary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  day['title']
                                                              ?.toString()
                                                              .isNotEmpty ==
                                                          true
                                                      ? day['title']
                                                      : 'Your day',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleLarge,
                                                ),
                                                Wrap(
                                                  spacing: 8,
                                                  children: [
                                                    TextButton(
                                                      onPressed: _busy
                                                          ? null
                                                          : () => _day(
                                                              trip,
                                                              existing: day,
                                                            ),
                                                      child: const Text(
                                                        'Edit day',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: _busy
                                                          ? null
                                                          : () async {
                                                              if (await _confirm(
                                                                'Remove this day?',
                                                              )) {
                                                                await _change(
                                                                  (api) => api
                                                                      .removeDay(
                                                                        day['id'],
                                                                      ),
                                                                );
                                                              }
                                                            },
                                                      child: const Text(
                                                        'Remove day',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                for (
                                                  var index = 0;
                                                  index <
                                                      (day['items'] as List)
                                                          .length;
                                                  index++
                                                )
                                                  _item(day, index),
                                                const SizedBox(height: 12),
                                                Wrap(
                                                  spacing: 10,
                                                  runSpacing: 8,
                                                  children: [
                                                    OutlinedButton.icon(
                                                      onPressed: _busy
                                                          ? null
                                                          : () => _activity(
                                                              day['id'],
                                                            ),
                                                      icon: const Icon(
                                                        Icons.add,
                                                      ),
                                                      label: const Text(
                                                        'Add activity',
                                                      ),
                                                    ),
                                                    OutlinedButton.icon(
                                                      onPressed: _busy
                                                          ? null
                                                          : () => _saved(
                                                              day['id'],
                                                            ),
                                                      icon: const Icon(
                                                        Icons.bookmark_border,
                                                      ),
                                                      label: const Text(
                                                        'From Saved',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
  Widget _item(Map<String, dynamic> day, int index) {
    final item = Map<String, dynamic>.from(day['items'][index]);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item['title'],
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          if (item['start_time'] != null)
            item['start_time'].toString().substring(0, 5),
          if (item['estimated_duration_minutes'] != null)
            '${item['estimated_duration_minutes']} min',
          if (item['description']?.toString().isNotEmpty == true)
            item['description'],
        ].join(' · '),
      ),
      trailing: PopupMenuButton<String>(
        enabled: !_busy,
        tooltip: 'Activity options',
        onSelected: (action) async {
          switch (action) {
            case 'edit':
              await _activity(day['id'], existing: item);
            case 'up':
              await _move(day, index, -1);
            case 'down':
              await _move(day, index, 1);
            case 'remove':
              if (await _confirm('Remove this activity?')) {
                await _change((api) => api.removeItem(item['id']));
              }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit activity')),
          if (index > 0)
            const PopupMenuItem(value: 'up', child: Text('Move up')),
          if (index < (day['items'] as List).length - 1)
            const PopupMenuItem(value: 'down', child: Text('Move down')),
          const PopupMenuItem(value: 'remove', child: Text('Remove activity')),
        ],
      ),
    );
  }
}

class _ActivityDialog extends StatefulWidget {
  const _ActivityDialog({this.item});
  final Map<String, dynamic>? item;
  @override
  State<_ActivityDialog> createState() => _ActivityDialogState();
}

class _ActivityDialogState extends State<_ActivityDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController(),
      _start = TextEditingController(),
      _end = TextEditingController(),
      _duration = TextEditingController();
  @override
  void initState() {
    super.initState();
    final item = widget.item ?? {};
    _title.text = item['title'] ?? '';
    _description.text = item['description'] ?? '';
    _start.text = item['start_time']?.toString().substring(0, 5) ?? '';
    _end.text = item['end_time']?.toString().substring(0, 5) ?? '';
    _duration.text = item['estimated_duration_minutes']?.toString() ?? '';
  }

  @override
  void dispose() {
    for (final controller in [_title, _description, _start, _end, _duration]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _time(String? value) =>
      value?.trim().isEmpty != false ||
          RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value!.trim())
      ? null
      : 'Use HH:mm, such as 09:30.';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Add activity' : 'Edit activity'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('activity-title'),
              controller: _title,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Activity name'),
              validator: (value) => value?.trim().isEmpty != false
                  ? 'Add an activity name.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _start,
              decoration: const InputDecoration(
                labelText: 'Start time (optional)',
                hintText: '09:30',
              ),
              validator: _time,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _end,
              decoration: const InputDecoration(
                labelText: 'End time (optional)',
                hintText: '10:30',
              ),
              validator: (value) {
                final error = _time(value);
                if (error != null) return error;
                if (value?.isNotEmpty == true &&
                    _start.text.isNotEmpty &&
                    value!.compareTo(_start.text) < 0) {
                  return 'End time must follow start time.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated minutes (optional)',
              ),
              validator: (value) =>
                  value?.isNotEmpty == true &&
                      ((int.tryParse(value!) ?? 0) < 1 ||
                          (int.tryParse(value) ?? 0) > 1440)
                  ? 'Use 1–1,440 minutes.'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, <String, dynamic>{
              'title': _title.text.trim(),
              'description': _description.text.trim(),
              'start_time': _start.text.trim().isEmpty
                  ? null
                  : _start.text.trim(),
              'end_time': _end.text.trim().isEmpty ? null : _end.text.trim(),
              'estimated_duration_minutes': int.tryParse(_duration.text),
            });
          }
        },
        child: const Text('Save activity'),
      ),
    ],
  );
}
