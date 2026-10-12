import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class AdminAIRoutingPanel extends StatefulWidget {
  const AdminAIRoutingPanel({super.key, this.client});
  final Dio? client;
  @override
  State<AdminAIRoutingPanel> createState() => _AdminAIRoutingPanelState();
}

class _AdminAIRoutingPanelState extends State<AdminAIRoutingPanel> {
  List<String> _order = [];
  Map<String, dynamic> _providers = {};
  List<dynamic>? _usage;
  bool _enabled = true, _loading = true, _saving = false;
  String? _error, _notice;
  Dio get _client => widget.client ?? ApiClient.dio;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = (await _client.get('/admin/ai-billing/routing')).data;
      try {
        final usage = (await _client.get('/admin/ai-billing/usage')).data;
        _usage = List<dynamic>.from(usage['providers']);
      } catch (_) {
        _usage = null;
      }
      if (!mounted) return;
      setState(() {
        _order = List<String>.from(data['provider_order']);
        _enabled = data['enabled'] == true;
        _providers = Map<String, dynamic>.from(data['providers']);
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn’t load provider settings.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    try {
      final data = (await _client.put(
        '/admin/ai-billing/routing',
        data: {'enabled': _enabled, 'provider_order': _order},
      )).data;
      if (mounted) {
        setState(() {
          _providers = Map<String, dynamic>.from(data['providers']);
          _notice = 'Provider settings saved.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Couldn’t save. Your changes are kept—try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_providers.isEmpty) {
      return Column(
        children: [
          Text(_error ?? 'Settings unavailable.'),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    final names = [
      ..._order,
      ...['openai', 'groq', 'gemini'].where((p) => !_order.contains(p)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('AI providers', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Zero-cost mode. Trav tries enabled providers in this order. OpenAI needs verified free access before it can run.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('AI available to users'),
              value: _enabled,
              onChanged: _saving ? null : (v) => setState(() => _enabled = v),
            ),
            ...names.map((name) {
              final status = _providers[name] as Map? ?? {};
              final index = _order.indexOf(name);
              final selected = index >= 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        '${selected ? '${index + 1}. ' : ''}${name.toUpperCase()}',
                      ),
                      subtitle: Text(
                        status['configured'] != true
                            ? 'Not connected'
                            : status['reason']?.toString() ??
                                  'Connection status unavailable',
                      ),
                      value: selected,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() {
                              if (value == true) {
                                _order.add(name);
                              } else {
                                _order.remove(name);
                              }
                              _notice = null;
                            }),
                    ),
                    if (selected)
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: _saving || index == 0
                                ? null
                                : () => setState(() {
                                    _order.removeAt(index);
                                    _order.insert(index - 1, name);
                                  }),
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            label: const Text('Earlier'),
                          ),
                          TextButton.icon(
                            onPressed: _saving || index == _order.length - 1
                                ? null
                                : () => setState(() {
                                    _order.removeAt(index);
                                    _order.insert(index + 1, name);
                                  }),
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            label: const Text('Later'),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
            if (_order.isEmpty)
              const Text(
                'All providers are disabled. Users can still open trips and saved places.',
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_notice != null) Text(_notice!),
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            Text(
              'Last 24 hours',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Provider attempts and reported tokens. Usage before this update is not included.',
            ),
            if (_usage == null)
              const Text('Usage is unavailable. Refresh to try again.'),
            if (_usage != null && _usage!.isEmpty)
              const Text('No AI usage recorded yet.'),
            ...?_usage?.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${row['provider'].toString().toUpperCase()}: ${row['attempts']} attempts • ${row['total_tokens'] ?? "Unknown"} reported tokens',
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save provider settings'),
            ),
          ],
        ),
      ),
    );
  }
}
