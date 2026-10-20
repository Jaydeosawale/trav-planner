import 'package:trav_planner/core/widgets/ai_content_report_button.dart';
import '../../../auth/presentation/widgets/require_sign_in.dart';
import '../../../destinations/data/place.dart';
import '../../../../core/widgets/place_source_credit.dart';

import 'package:dio/dio.dart';

import 'structured_plan_page.dart';
import '../../../explore/presentation/pages/nearby_places_page.dart';
import '../../../booking/presentation/pages/booking_links_page.dart';

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
  const AISearchPage({
    super.key,
    this.api,
    this.initialMessage,
    this.initialPlace,
  });
  final String? initialMessage;
  final TravelPlace? initialPlace;
  final AIApi? api;

  @override
  State<AISearchPage> createState() => _AISearchPageState();
}

class _AISearchPageState extends State<AISearchPage> {
  final TextEditingController _controller = TextEditingController();
  final _scroll = ScrollController();
  void _scrollToLatest() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  });
  late final AIApi _api = widget.api ?? AIApi();

  bool _loading = false;
  bool _authorizing = false;
  String? _savedTripId;
  Map<String, dynamic>? _session;
  bool _reviewing = false;
  String? _error;
  String? _lastMessage;
  AIResponseModel? _response;
  final List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialMessage ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _askAI([String? suggestion]) async {
    final message = (suggestion ?? _controller.text).trim();

    if (message.isEmpty || _loading || _authorizing) {
      return;
    }

    if (widget.api == null) {
      _authorizing = true;
      bool signedIn;
      try {
        signedIn = await ensureSignedIn(context);
      } finally {
        _authorizing = false;
      }
      if (!signedIn || !mounted) return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      if (_response != null && _lastMessage != null) {
        _history.addAll([
          {'role': 'user', 'content': _lastMessage!},
          {'role': 'assistant', 'content': _response!.content},
        ]);
        if (_history.length > 6) _history.removeRange(0, _history.length - 6);
      }
      _loading = true;
      _lastMessage = message;
      _error = null;
      _response = null;
      _savedTripId = null;
    });

    _scrollToLatest();
    try {
      final response = await _api.chat(
        message: message,
        sessionId: _session?['id']?.toString(),
      );
      Map<String, dynamic>? refreshed;
      final sessionId =
          _session?['id']?.toString() ??
          response.metadata['session_id']?.toString();
      if (response.success && sessionId != null) {
        try {
          refreshed = await _api.session(sessionId);
        } catch (_) {}
      }

      if (!mounted) {
        return;
      }

      setState(() {
        if (response.success) {
          _response = response;
          if (_controller.text.trim() == message) _controller.clear();
          if (refreshed != null) {
            _session = refreshed;
          } else if (sessionId != null && _session == null) {
            _session = {
              'id': sessionId,
              'title': message,
              'brief': <String, dynamic>{},
              'version': 0,
            };
          }
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
        _error = error is DioException && error.response?.data is Map
            ? error.response!.data['detail']?.toString() ??
                  'Couldn’t send the message. Please retry.'
            : 'Couldn’t send the message. Please retry.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _scrollToLatest();
      }
    }
  }

  Future<void> _editBrief({bool newPlan = false}) async {
    if (_loading) return;
    if (widget.api == null && !await ensureSignedIn(context)) return;
    if (!mounted) return;
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
          _history.clear();
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
    if (widget.api == null && !await ensureSignedIn(context)) return;
    if (!mounted) return;
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
        _history.clear();
        if (turns.length > 2) {
          _history.addAll(
            turns
                .take(turns.length - 2)
                .map(
                  (t) => {
                    'role': t['role'].toString(),
                    'content': t['content'].toString(),
                  },
                ),
          );
        }
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
          _history.clear();
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            12 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: TextField(
                controller: _controller,
                enabled: !_loading,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: _lastMessage == null
                      ? 'Where would you like to go? Tell me your dates and budget…'
                      : 'Ask a follow-up or change your plans…',
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
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your prompts and trip preferences are sent to Gemini or Groq to generate a plan. Gemini’s free service may use submissions to improve its models. Do not include personal, sensitive or confidential details. AI suggestions can be inaccurate.',
                ),
                const SizedBox(height: 16),
                if (_lastMessage == null && _session == null) ...[
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
                ],
                if (widget.initialPlace != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Planning around ${widget.initialPlace!.name}'),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StructuredPlanPage(
                                  session: _session,
                                  initialPlace: widget.initialPlace,
                                ),
                              ),
                            ),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Build daily plan'),
                    ),
                    if (_lastMessage == null && _session == null)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NearbyPlacesPage(),
                          ),
                        ),
                        icon: const Icon(Icons.near_me_outlined),
                        label: const Text('Places nearby'),
                      ),
                    if (_lastMessage == null && _session == null)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BookingLinksPage(),
                          ),
                        ),
                        child: const Text('Book travel directly'),
                      ),
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
                const SizedBox(height: 24),

                if (_lastMessage == null && _session == null)
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

                for (final turn in _history) ...[
                  Align(
                    alignment: turn['role'] == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: turn['role'] == 'user'
                            ? AppColors.surfaceVariant
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: turn['role'] == 'user'
                          ? Text(turn['content']!)
                          : TravelMarkdown(content: turn['content']!),
                    ),
                  ),
                ],
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
                  _ErrorCard(
                    message: _error!,
                    onRetry: () => _askAI(_lastMessage),
                  ),

                if (_response != null) ...[
                  _ResponseCard(response: _response!),
                  if (_session?['id'] != null)
                    AIContentReportButton(
                      sourceKind: 'chat',
                      referenceId: _session!['id'].toString(),
                    ),
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
                const SizedBox(height: 16),
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
          PlaceSourceCredit(data: response.data),
        ],
      ),
    );
  }
}
