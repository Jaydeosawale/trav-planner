import '../../../../core/theme/app_colors.dart';
import 'package:trav_planner/core/widgets/ai_content_report_button.dart';
import '../../../auth/presentation/widgets/require_sign_in.dart';
import 'planning_brief_values.dart';
import '../../../../core/widgets/place_source_credit.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/plan_postcard.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../trips/data/trips_api.dart';
import '../../../trips/presentation/pages/my_trips_page.dart';
import '../../../trips/presentation/pages/trip_details_page.dart';
import '../../../destinations/data/place.dart';
import '../../../maps/places_map.dart';

class StructuredPlanPage extends ConsumerStatefulWidget {
  const StructuredPlanPage({
    super.key,
    this.client,
    this.session,
    this.initialPlace,
  });
  final Dio? client;
  final TravelPlace? initialPlace;
  final Map<String, dynamic>? session;
  @override
  ConsumerState<StructuredPlanPage> createState() => _StructuredPlanPageState();
}

class _StructuredPlanPageState extends ConsumerState<StructuredPlanPage> {
  final _form = GlobalKey<FormState>();
  final _query = TextEditingController(),
      _preferences = TextEditingController(),
      _title = TextEditingController(),
      _travelers = TextEditingController(text: '1'),
      _budget = TextEditingController();
  DateTime _start = DateUtils.dateOnly(DateTime.now()),
      _end = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 2));
  String _currency = 'INR';
  bool _currencyExplicit = false;
  bool _startAssumed = true, _endAssumed = true;
  Map<String, dynamic>? _city, _draft;
  List<Map<String, dynamic>> _cities = [];
  final Set<String> _selected = {};
  String? _notice, _tripId;
  bool _busy = false, _map = false;
  bool _authorizing = false;
  Dio get _client => widget.client ?? ApiClient.dio;
  @override
  void initState() {
    super.initState();
    final b = widget.session?['brief'] as Map?;
    final values = PlanningBriefValues(b ?? {});
    _query.text =
        b?['destination']?.toString() ?? widget.initialPlace?.cityName ?? '';
    _travelers.text = values.travelers;
    if (values.start != null) {
      _start = values.start!;
      _startAssumed = false;
    }
    if (values.end != null) {
      _end = values.end!;
      _endAssumed = false;
    }
    if (values.currency != null &&
        RegExp(r'^[A-Z]{3}$').hasMatch(values.currency!)) {
      _currency = values.currency!;
      _currencyExplicit = true;
    }
    _budget.text = values.amount ?? '';
    _preferences.text = [
      values.context,
      if (widget.initialPlace != null)
        'Include ${widget.initialPlace!.name} (place ID: ${widget.initialPlace!.id}) in the selected destination where practical.',
    ].where((x) => x.isNotEmpty).join('; ');
    final place = widget.initialPlace;
    if (place?.cityId != null) {
      _city = {'id': place!.cityId, 'name': place.cityName ?? _query.text};
    }
  }

  @override
  void dispose() {
    for (final c in [_query, _preferences, _title, _travelers, _budget]) {
      c.dispose();
    }
    super.dispose();
  }

  String _date(DateTime d) => d.toIso8601String().split('T').first;
  Future<void> _pick(bool start) async {
    final d = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) {
      setState(() {
        if (start) {
          _start = d;
          _startAssumed = false;
          if (_end.isBefore(d)) {
            _end = d;
            _endAssumed = true;
          }
        } else {
          _end = d;
          _endAssumed = false;
        }
      });
    }
  }

  Future<void> _find() async {
    if (_query.text.trim().length < 2) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      var rows = await TripsApi(client: _client).cities(_query.text.trim());
      if (rows.isEmpty) {
        final r = await _client.get(
          '/discovery/locations',
          queryParameters: {'q': _query.text.trim()},
        );
        rows = (r.data['items'] as List)
            .map(
              (e) => {
                ...Map<String, dynamic>.from(e),
                'source_id': e['id'],
                'country': e['country_name'],
              },
            )
            .toList();
      }
      if (mounted) setState(() => _cities = rows);
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Couldn’t find cities. Try another spelling.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(Map<String, dynamic> c) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      if (c['source_id'] != null) {
        c = Map<String, dynamic>.from(
          (await _client.post(
            '/discovery/locations/${c['source_id']}/open',
          )).data,
        );
      }
      if (mounted) {
        setState(() {
          _city = c;
          final currency = c['currency']?.toString().toUpperCase();
          if (!_currencyExplicit &&
              currency != null &&
              RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
            _currency = currency;
          }
          _query.text = c['name'].toString();
          _cities = [];
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Couldn’t open this destination. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _review(Map<String, dynamic> draft) {
    _draft = draft;
    _title.text = draft['plan']['title'].toString();
    _tripId = draft['trip_id']?.toString();
    _selected.clear();
    final days = draft['plan']['days'] as List;
    for (var i = 0; i < days.length; i++) {
      for (var j = 0; j < (days[i]['activities'] as List).length; j++) {
        _selected.add('$i:$j');
      }
    }
  }

  Future<void> _generate() async {
    if (_busy || _authorizing) return;
    if (!_form.currentState!.validate()) return;
    if (_city == null) {
      setState(() => _notice = 'Choose a destination from the city results.');
      return;
    }
    if (_end.isBefore(_start) || _end.difference(_start).inDays > 6) {
      setState(() => _notice = 'Choose between one and seven days.');
      return;
    }
    if (widget.client == null) {
      _authorizing = true;
      bool signedIn;
      try {
        signedIn = await ensureSignedIn(context);
      } finally {
        _authorizing = false;
      }
      if (!signedIn || !mounted) return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final r = await _client.post(
        '/ai/itinerary-drafts',
        data: {
          'city_id': _city!['id'],
          if (widget.initialPlace != null &&
              widget.initialPlace!.cityId == _city!['id'])
            'selected_place_ids': [widget.initialPlace!.id],
          'start_date': _date(_start),
          'end_date': _date(_end),
          'travelers': int.parse(_travelers.text),
          'currency': _currency,
          'budget_amount': _budget.text.trim().isEmpty
              ? null
              : double.parse(_budget.text),
          'preferences': _preferences.text,
          if (widget.session != null) 'session_id': widget.session!['id'],
        },
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      if (mounted) setState(() => _review(Map<String, dynamic>.from(r.data)));
    } on DioException catch (e) {
      if (mounted) {
        setState(
          () => _notice = e.response?.data is Map
              ? e.response!.data['detail']?.toString() ??
                    'Couldn’t generate a plan. Your choices are still here.'
              : 'AI is unavailable. Your choices are still here.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice = 'Couldn’t generate a plan. No trip was saved.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recent() async {
    setState(() => _busy = true);
    try {
      final rows = (await _client.get('/ai/itinerary-drafts')).data as List;
      if (!mounted) return;
      final id = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Drafts to review'),
          children: [
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No pending drafts.'),
              ),
            for (final r in rows)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, r['id'].toString()),
                child: Text(r['title'].toString()),
              ),
          ],
        ),
      );
      if (id != null) {
        final r = await _client.get('/ai/itinerary-drafts/$id');
        if (mounted) setState(() => _review(Map<String, dynamic>.from(r.data)));
      }
    } catch (_) {
      if (mounted) setState(() => _notice = 'Couldn’t load drafts.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_selected.isEmpty || _title.text.trim().length < 2) {
      setState(() => _notice = 'Add a title and select at least one activity.');
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final r = await _client.post(
        '/ai/itinerary-drafts/${_draft!['id']}/save',
        data: {'title': _title.text.trim(), 'selected': _selected.toList()},
      );
      ref.invalidate(myTripsProvider);
      if (mounted) {
        setState(() {
          _tripId = r.data['trip_id'].toString();
          _notice = 'Your trip and daily itinerary are saved in My Trips.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice =
              'Couldn’t save the full plan. Keep this preview and retry; no partial itinerary is saved.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    setState(() => _busy = true);
    try {
      await _client.delete('/ai/itinerary-drafts/${_draft!['id']}');
      if (mounted) {
        setState(() {
          _draft = null;
          _tripId = null;
          _notice = 'Draft discarded.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _notice = 'Couldn’t discard this draft.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  final _postcardKey = GlobalKey();
  Future<void> _sharePostcard() async {
    try {
      final boundary =
          _postcardKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null || !mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png'),
          ],
          fileNameOverrides: ['trav-plan.png'],
          title: 'My Trav plan',
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t export the plan image. Your draft is still here.',
            ),
          ),
        );
      }
    }
  }

  Widget _preview() {
    final plan = _draft!['plan'] as Map;
    final days = plan['days'] as List;
    final places = _draft!['places'] as Map;
    final selectedPlaces = <String>{
      for (var i = 0; i < days.length; i++)
        for (var j = 0; j < (days[i]['activities'] as List).length; j++)
          if (_selected.contains('$i:$j') &&
              days[i]['activities'][j]['place_id'] != null)
            days[i]['activities'][j]['place_id'].toString(),
    };
    final linked = places.entries
        .where((entry) => selectedPlaces.contains(entry.key.toString()))
        .map((entry) => entry.value)
        .map((p) => TravelPlace.fromJson(Map<String, dynamic>.from(p)))
        .toList();
    final start = DateTime.parse(_draft!['request']['start_date']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review your daily plan',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        RepaintBoundary(
          key: _postcardKey,
          child: PlanPostcard(
            destination:
                _draft!['city_name']?.toString() ?? plan['title'].toString(),
            days: days.length,
            activities: _selected.length,
            stops: linked.map((p) => p.name).toList(),
          ),
        ),
        TextButton.icon(
          onPressed: _busy ? null : _sharePostcard,
          icon: const Icon(Icons.ios_share),
          label: const Text('Share plan image'),
        ),
        const SizedBox(height: 12),
        const Text(
          'AI suggestions, not confirmed bookings. Durations are estimates; verify hours, access and travel arrangements. Untick activities you don’t want. You can edit and reorder the saved itinerary later.',
        ),
        const SizedBox(height: 12),
        AIContentReportButton(
          sourceKind: 'itinerary',
          referenceId: _draft!['id'].toString(),
          client: _client,
        ),
        TextField(
          controller: _title,
          enabled: !_busy && _tripId == null,
          maxLength: 150,
          decoration: const InputDecoration(labelText: 'Trip title'),
        ),
        Text(plan['summary']?.toString() ?? ''),
        PlaceSourceCredit(data: _draft),
        if (linked.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _map = !_map),
            icon: const Icon(Icons.map_outlined),
            label: Text(_map ? 'Hide plan map' : 'Show plan map'),
          ),
          if (_map)
            SizedBox(
              height: 350,
              child: PlacesMap(
                places: linked,
                onSelect: (place) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(place.name)));
                },
              ),
            ),
        ],
        for (var i = 0; i < days.length; i++)
          Card(
            color: [
              const Color(0xFFE1F0E8),
              const Color(0xFFE5EDFC),
              const Color(0xFFFBE7D6),
            ][i % 3],
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Day ${i + 1} · ${_date(start.add(Duration(days: i)))}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    days[i]['title'].toString(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (
                    var j = 0;
                    j < (days[i]['activities'] as List).length;
                    j++
                  )
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _selected.contains('$i:$j'),
                      onChanged: _busy || _tripId != null
                          ? null
                          : (v) => setState(() {
                              if (v == true) {
                                _selected.add('$i:$j');
                              } else {
                                _selected.remove('$i:$j');
                              }
                            }),
                      title: Text(
                        places[days[i]['activities'][j]['place_id']]?['name']
                                ?.toString() ??
                            days[i]['activities'][j]['title'].toString(),
                      ),
                      subtitle: Text(
                        '${days[i]['activities'][j]['duration_minutes']} min estimated · ${days[i]['activities'][j]['place_id'] == null ? 'Unlinked suggestion' : 'Sourced place'}\n${days[i]['activities'][j]['notes'] ?? ''}',
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (_tripId == null) ...[
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Save reviewed itinerary'),
          ),
          TextButton(
            onPressed: _busy ? null : _discard,
            child: const Text('Discard draft'),
          ),
        ] else
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TripDetailsPage(id: _tripId!)),
            ),
            child: const Text('Open saved trip'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daily itinerary')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your prompts and trip preferences are sent to Gemini or Groq to generate a plan. Gemini’s free service may use submissions to improve its models. Do not include personal, sensitive or confidential details. AI suggestions can be inaccurate.',
              ),
              const SizedBox(height: 16),
              if (_draft == null)
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'A plan you can make your own.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text(
                        'Choose a destination and exact dates. The AI drafts up to seven days using sourced places and your choices; nothing is booked or saved until you review it.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _query,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          labelText: 'Destination city',
                        ),
                        onChanged: (_) => setState(() => _city = null),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : _find,
                        child: const Text('Find destination'),
                      ),
                      for (final c in _cities)
                        ListTile(
                          title: Text(c['name'].toString()),
                          subtitle: Text(
                            '${c['country'] ?? ''} · ${c['latitude']}, ${c['longitude']}',
                          ),
                          selected: _city?['id'] == c['id'],
                          onTap: _busy ? null : () => _choose(c),
                        ),
                      if (_city != null) Text('Selected: ${_city!['name']}'),
                      if (_startAssumed || _endAssumed)
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            'Draft dates · change to match your trip.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _busy ? null : () => _pick(true),
                            child: Text('Start: ${_date(_start)}'),
                          ),
                          OutlinedButton(
                            onPressed: _busy ? null : () => _pick(false),
                            child: Text('End: ${_date(_end)}'),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _travelers,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Travelers',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n < 1 || n > 20
                              ? 'Choose 1–20 travelers'
                              : null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        key: ValueKey('planner-currency-$_currency'),
                        initialValue: _currency,
                        decoration: const InputDecoration(
                          labelText: 'Budget currency',
                        ),
                        items:
                            {
                                  'INR',
                                  'USD',
                                  'EUR',
                                  'GBP',
                                  'AUD',
                                  'CAD',
                                  'JPY',
                                  _currency,
                                }
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: _busy
                            ? null
                            : (c) => setState(() {
                                _currency = c!;
                                _currencyExplicit = true;
                              }),
                      ),
                      TextFormField(
                        controller: _budget,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total budget (optional)',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = double.tryParse(v);
                          return n == null ||
                                  !n.isFinite ||
                                  n < 0 ||
                                  n > 1000000
                              ? 'Enter a valid budget'
                              : null;
                        },
                      ),
                      TextFormField(
                        controller: _preferences,
                        enabled: !_busy,
                        maxLength: 1000,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Interests, food, pace and transport',
                        ),
                      ),
                      FilledButton(
                        onPressed: _busy ? null : _generate,
                        child: const Text('Generate daily plan'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _recent,
                        child: const Text('Review recent drafts'),
                      ),
                    ],
                  ),
                )
              else
                _preview(),
              if (_busy) const LinearProgressIndicator(),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(_notice!),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
