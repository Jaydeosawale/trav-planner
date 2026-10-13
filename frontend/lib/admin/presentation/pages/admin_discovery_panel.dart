import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/network/api_client.dart';

class AdminDiscoveryPanel extends StatefulWidget {
  const AdminDiscoveryPanel({super.key, this.client});
  final Dio? client;
  @override
  State<AdminDiscoveryPanel> createState() => _AdminDiscoveryPanelState();
}

class _AdminDiscoveryPanelState extends State<AdminDiscoveryPanel> {
  Map<String, dynamic>? _status;
  List<Map<String, dynamic>> _candidates = [];
  String? _notice;
  bool _busy = false;
  int _page = 1;
  bool _enabled = true;
  int _limit = 200;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = Map<String, dynamic>.from(
        (await (widget.client ?? ApiClient.dio).get(
          '/discovery/admin/status',
        )).data,
      );
      final candidates =
          ((await (widget.client ?? ApiClient.dio).get(
                    '/discovery/admin/candidates',
                    queryParameters: {'page': _page},
                  )).data
                  as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      if (mounted) {
        setState(() {
          _status = status;
          _candidates = candidates;
          _enabled = status['enabled'] == true;
          _limit = (status['daily_calls'] as num).toInt();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Couldn’t load discovery controls.');
      }
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      if (mounted) setState(() => _notice = 'Discovery settings updated.');
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice =
              'Couldn’t complete this change. Your settings are still here.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null) return;
    final bytes = picked.files.single.bytes;
    if (bytes == null || bytes.length > 1024 * 1024) {
      if (mounted) {
        setState(() => _notice = 'Use a place pack smaller than 1 MB.');
      }
      return;
    }
    await _action(() async {
      final pack = jsonDecode(utf8.decode(bytes));
      await (widget.client ?? ApiClient.dio).post(
        '/discovery/admin/osm-pack',
        data: pack,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Worldwide discovery',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Free sources only. Requests pause at the limit. Imports and photos never activate a paid provider.',
          ),
          if (_status != null)
            Text(
              '${_status!['calls_today']} source requests today · ${_status!['cache_rows']} cached entries\nCache: ${_status!['cache_bytes']} / ${_status!['cache_limit_bytes']} bytes\nDatabase: ${_status!['database_bytes'] ?? 'Unavailable'} bytes; enrichment stops at ${_status!['database_stop_bytes']} bytes',
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable external discovery'),
            value: _enabled,
            onChanged: _busy ? null : (v) => setState(() => _enabled = v),
          ),
          Text('Daily source request limit: $_limit'),
          Slider(
            value: _limit.toDouble(),
            min: 0,
            max: 200,
            divisions: 20,
            onChanged: _busy ? null : (v) => setState(() => _limit = v.toInt()),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy || _status == null
                    ? null
                    : () => _action(() async {
                        await (widget.client ?? ApiClient.dio).put(
                          '/discovery/admin/settings',
                          data: {'enabled': _enabled, 'daily_calls': _limit},
                        );
                      }),
                child: const Text('Save discovery settings'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _load,
                child: const Text('Refresh discovery'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _import,
                child: const Text('Import regional place pack'),
              ),
            ],
          ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_notice!),
            ),
          const SizedBox(height: 12),
          const Text('Source candidates — review before publishing'),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _busy || _page == 1
                    ? null
                    : () {
                        setState(() => _page--);
                        _load();
                      },
                child: const Text('Previous candidates'),
              ),
              Text('Page $_page'),
              TextButton(
                onPressed: _busy || _candidates.length < 20
                    ? null
                    : () {
                        setState(() => _page++);
                        _load();
                      },
                child: const Text('More candidates'),
              ),
            ],
          ),
          for (final place in _candidates)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(place['name'].toString()),
              subtitle: Text('${place['provider']} · ${place['place_type']}'),
              trailing: TextButton(
                onPressed: _busy || place['reviewed'] == true
                    ? null
                    : () => _action(() async {
                        await (widget.client ?? ApiClient.dio).post(
                          '/discovery/admin/candidates/${place['id']}/publish',
                        );
                      }),
                child: Text(
                  place['reviewed'] == true ? 'Published' : 'Publish',
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
