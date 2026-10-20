import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/widgets/require_sign_in.dart';
import '../../destinations/data/place.dart';
import '../../itinerary/presentation/pages/itinerary_page.dart';
import '../../trips/presentation/pages/trip_editor_page.dart';
import '../../trips/presentation/pages/trip_details_page.dart';

/// Adds the same sourced place to an existing day without changing its identity.
class PlaceTripPicker extends ConsumerStatefulWidget {
  const PlaceTripPicker({super.key, required this.place});
  final TravelPlace place;
  @override
  ConsumerState<PlaceTripPicker> createState() => _PlaceTripPickerState();
}

class _PlaceTripPickerState extends ConsumerState<PlaceTripPicker> {
  bool _busy = false;
  void _notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!await ensureSignedIn(context, ref) || !mounted) return;
      final trips = ref.read(tripsApiProvider);
      final choices = <Map<String, dynamic>>[];
      var page = 1;
      while (true) {
        final data = await trips.list(page);
        choices.addAll(
          (data['items'] as List).map((v) => Map<String, dynamic>.from(v)),
        );
        if (page >= ((data['pages'] as num?)?.toInt() ?? 1)) break;
        page++;
      }
      if (!mounted) return;
      final trip = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Add to which trip?'),
          children: [
            if (choices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Create a trip in My Trips first, then add this place to a day.',
                ),
              ),
            for (final trip in choices)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, trip),
                child: Text(
                  '${trip['title']}\n${trip['start_date']} — ${trip['end_date']}',
                ),
              ),
          ],
        ),
      );
      if (trip == null || !mounted) return;
      final id = trip['id'].toString();
      final itinerary = ref.read(itineraryApiProvider);
      var days = await itinerary.load(id);
      if (!mounted) return;
      if (days.isEmpty) {
        final start = DateTime.parse(trip['start_date'].toString());
        final end = DateTime.parse(trip['end_date'].toString());
        final date = await showDatePicker(
          context: context,
          initialDate: start,
          firstDate: start,
          lastDate: end,
        );
        if (date == null || !mounted) return;
        await itinerary.saveDay(id, {
          'date': date.toIso8601String().split('T').first,
          'day_number': date.difference(start).inDays + 1,
          'title': 'Places to explore',
        });
        days = await itinerary.load(id);
      }
      if (!mounted) return;
      final day = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Choose a day'),
          children: [
            for (final d in days)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, d),
                child: Text(
                  'Day ${d['day_number']} · ${d['date']}\n${d['title'] ?? ''}',
                ),
              ),
          ],
        ),
      );
      if (day == null || !mounted) return;
      // Re-read immediately before adding: prevent duplicate taps and stale lists.
      final latest = (await itinerary.load(
        id,
      )).firstWhere((d) => d['id'] == day['id']);
      final items = latest['items'] as List? ?? [];
      if (items.any(
        (item) => item['place_id']?.toString() == widget.place.id,
      )) {
        _notice('This place is already in that day.');
        return;
      }
      final place = widget.place;
      final sequence =
          items.fold<int>(0, (highest, item) {
            final n = (item['sequence'] as num?)?.toInt() ?? 0;
            return n > highest ? n : highest;
          }) +
          1;
      await itinerary.saveItem(day['id'].toString(), {
        'title': place.name,
        'place_id': place.id,
        'activity_type': place.type,
        'sequence': sequence,
        if (place.point != null) 'latitude': place.point!.latitude,
        if (place.point != null) 'longitude': place.point!.longitude,
      });
      ref.invalidate(itineraryProvider(id));
      ref.invalidate(tripDetailsProvider(id));
      _notice('Added ${place.name} to your trip.');
    } catch (_) {
      _notice(
        'Couldn’t finish adding this place. Check your day plan before retrying.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _busy ? null : _add,
    icon: _busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.add_rounded),
    label: const Text('Add to trip'),
  );
}
