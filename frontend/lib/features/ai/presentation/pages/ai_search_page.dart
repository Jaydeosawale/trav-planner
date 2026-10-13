import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/travel_markdown.dart';
import 'trip_brief_page.dart';
import '../../../trips/presentation/pages/trip_editor_page.dart';
import '../../../trips/presentation/pages/trip_details_page.dart';
import '../../../trips/presentation/pages/my_trips_page.dart';

import '../../data/datasources/ai_api.dart';
import '../../data/models/ai_response_model.dart';

class AISearchPage extends StatefulWidget {
  const AISearchPage({super.key, this.api});
  final AIApi? api;

  @override
  State<AISearchPage> createState() => _AISearchPageState();
}

class _AISearchPageState extends State<AISearchPage> {
  final TextEditingController _controller = TextEditingController();
  late final AIApi _api = widget.api ?? AIApi();

  bool _loading = false;
  String? _savedTripId;
  Map<String, dynamic>? _session;
  bool _reviewing = false;
  String? _error;
  String? _lastMessage;
  AIResponseModel? _response;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _askAI([String? suggestion]) async {
    final message = (suggestion ?? _controller.text).trim();

    if (message.isEmpty || _loading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _lastMessage = message;
      _error = null;
      _response = null;
      _savedTripId = null;
    });

    try {
      final response = await _api.chat(
        message: message,
        sessionId: _session?['id']?.toString(),
      );
      Map<String, dynamic>? refreshed;
      if (response.success && _session != null) {
        try {
          refreshed = await _api.session(_session!['id'].toString());
        } catch (_) {}
      }

      if (!mounted) {
        return;
      }

      setState(() {
        if (response.success) {
          _response = response;
          if (refreshed != null) _session = refreshed;
        } else {
          _error = response.content.isNotEmpty
              ? response.content
              : response.message ??
                    'AI is temporarily unavailable. Please try again.';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _editBrief({bool newPlan = false}) async {
    if (_loading) return;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) =>
            TripBriefPage(api: _api, session: newPlan ? null : _session),
      ),
    );
    if (mounted && result != null) {
      setState(() {
        _session = result;
        if (newPlan) {
          _response = null;
          _lastMessage = null;
          _savedTripId = null;
          _controller.clear();
        }
        _error = null;
      });
    }
  }

  Future<void> _recentPlans() async {
    if (_loading) return;
    try {
      final plans = await _api.sessions();
      if (!mounted) return;
      final id = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Recent plans'),
          children: plans.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Save a trip brief to start a conversation.'),
                  ),
                ]
              : plans
                    .map(
                      (plan) => SimpleDialogOption(
                        onPressed: () =>
                            Navigator.pop(context, plan['id'].toString()),
                        child: Text(plan['title'].toString()),
                      ),
                    )
                    .toList(),
        ),
      );
      if (id == null) return;
      final saved = await _api.session(id);
      if (!mounted) return;
      final turns = saved['turns'] as List? ?? [];
      setState(() {
        _session = saved;
        _savedTripId = null;
        _error = null;
        _controller.clear();
        _lastMessage = turns.length >= 2
            ? turns[turns.length - 2]['content'].toString()
            : null;
        _response = turns.isNotEmpty
            ? AIResponseModel(
                success: true,
                content: turns.last['content'].toString(),
                agent: 'travel_planning',
                data: {},
                metadata: {},
              )
            : null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Couldn’t reopen your plans. Please try again.',
        );
      }
    }
  }

  Future<void> _forgetPlan() async {
    if (_session == null || _loading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forget this conversation?'),
        content: const Text(
          'This permanently removes its saved brief and recent messages. Trips already saved to My Trips stay available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.forgetSession(_session!['id'].toString());
      if (mounted) {
        setState(() {
          _session = null;
          _response = null;
          _lastMessage = null;
          _savedTripId = null;
          _controller.clear();
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Couldn’t forget this conversation. Please try again.',
        );
      }
    }
  }

  Future<void> _reviewPlan() async {
    if (_reviewing || _response == null) return;
    if (_savedTripId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TripDetailsPage(id: _savedTripId!)),
      );
      return;
    }
    setState(() => _reviewing = true);
    try {
      final trip = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => TripEditorPage(
            draftNotes:
                'AI travel draft — check details before travel.\n\n${_response!.content}',
          ),
        ),
      );
      if (!mounted || trip == null) return;
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(tripPageProvider.notifier).state = 1;
      container.invalidate(myTripsProvider);
      setState(() => _savedTripId = trip['id'].toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved to My Trips.')));
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  void _useSuggestion(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );

    _askAI(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('AI Planner', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFE0ECFF), Color(0xFFD6F5EF)],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Where will curiosity\ntake you?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 10),

                Text(
                  'Tell us your destination, dates and budget. We’ll help you put the journey together.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _editBrief(newPlan: true),
                      icon: const Icon(Icons.add),
                      label: const Text('New plan'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _recentPlans,
                      icon: const Icon(Icons.history),
                      label: const Text('Recent plans'),
                    ),
                    if (_session != null)
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _editBrief,
                        icon: const Icon(Icons.tune),
                        label: const Text('Edit brief'),
                      ),
                    if (_session != null)
                      TextButton(
                        onPressed: _loading ? null : _forgetPlan,
                        child: const Text('Forget conversation'),
                      ),
                  ],
                ),
                if (_session != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _session!['title'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    (_session!['brief'] as Map).entries
                        .where((e) => e.value.toString().isNotEmpty)
                        .map((e) => '${e.key}: ${e.value}')
                        .join(' · '),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  enabled: !_loading,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText:
                        'A 5-day trip to Japan in April, with food and quiet places…',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(18),
                    suffixIcon: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Send message',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _askAI,
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                  ),
                  onSubmitted: (_) => _askAI(),
                ),

                const SizedBox(height: 24),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _SuggestionChip(
                      text: 'Plan a trip to Japan',
                      onPressed: () {
                        _useSuggestion('Plan a trip to Japan');
                      },
                    ),
                    _SuggestionChip(
                      text: 'Visa requirements',
                      onPressed: () {
                        _useSuggestion(
                          'What are the current visa requirements for Japan for an Indian tourist?',
                        );
                      },
                    ),
                    _SuggestionChip(
                      text: 'Best places in Goa',
                      onPressed: () {
                        _useSuggestion(
                          'What are the best places to visit in Goa?',
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                if (_lastMessage != null) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _lastMessage!,
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_loading) const _LoadingCard(),

                if (_error != null)
                  _ErrorCard(message: _error!, onRetry: _askAI),

                if (_response != null) ...[
                  _ResponseCard(response: _response!),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _reviewing ? null : _reviewPlan,
                    icon: Icon(
                      _savedTripId == null
                          ? Icons.bookmark_add_outlined
                          : Icons.luggage_outlined,
                    ),
                    label: Text(
                      _savedTripId == null
                          ? 'Review & save to My Trips'
                          : 'Open saved trip',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AI suggestions are a starting point. Check opening hours, prices and travel details before you go.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _SuggestionChip({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: onPressed,
      avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Putting your ideas together…',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error),
              SizedBox(width: 10),
              Text(
                'AI request failed',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final AIResponseModel response;

  const _ResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Your AI travel companion',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TravelMarkdown(content: response.content),
        ],
      ),
    );
  }
}
