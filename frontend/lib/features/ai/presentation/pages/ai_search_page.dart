import '../../../places/data/current_location.dart';
import '../../../places/data/nearby_origin.dart';
import '../../../places/data/place_area.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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

class AISearchPage extends ConsumerStatefulWidget {
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
  ConsumerState<AISearchPage> createState() => _AISearchPageState();
}

class _AISearchPageState extends ConsumerState<AISearchPage> {
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

  Map<String, dynamic>? _usage;
  Future<void> _loadUsage() async {
    if (widget.api != null || !ref.read(authProvider).isAuthenticated) return;
    final account = ref.read(authProvider).user?.id;
    try {
      final usage = await _api.planUsage();
      if (mounted && account == ref.read(authProvider).user?.id) {
        setState(() => _usage = usage);
      }
    } catch (_) {
      /* The generation endpoint remains authoritative. */
    }
  }

  bool _locating = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsage());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _shareLocation() async {
    if (_locating || _loading) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Plan around you?'),
        content: const Text(
          'Share your approximate location with Trav’s AI provider for nearby ideas. Remember this area and AI sharing on this device until you change or remove it. You can enter a town instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Use current location'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final account = ref.read(authProvider).user?.id;
    setState(() => _locating = true);
    try {
      final position = await ref.read(currentLocationServiceProvider).request();
      if (!mounted || account != ref.read(authProvider).user?.id) return;
      ref.read(chosenPlaceAreaProvider.notifier).state = null;
      ref.read(nearbyOriginProvider.notifier).state = position;
      ref.read(aiLocationEnabledProvider.notifier).state = true;
      ScaffoldMessenger.of(context).clearSnackBars();
    } catch (error) {
      if (!mounted) return;
      ref.read(aiLocationEnabledProvider.notifier).state = false;
      final failure = error is LocationAccessFailure
          ? error
          : const LocationAccessFailure(
              'Couldn’t get your location. Try again or enter a town.',
            );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          action: failure.openSettings || failure.deviceLocationSettings
              ? SnackBarAction(
                  label: 'Settings',
                  onPressed: () => failure.deviceLocationSettings
                      ? ref
                            .read(currentLocationServiceProvider)
                            .openDeviceSettings()
                      : ref.read(currentLocationServiceProvider).openSettings(),
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _askAI([String? suggestion]) async {
    final message = (suggestion ?? _controller.text).trim();

    if (message.isEmpty || _loading || _authorizing || _locating) {
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
        location:
            ref.read(aiLocationEnabledProvider) &&
                ref.read(nearbyOriginProvider) != null
            ? {
                'latitude': ref.read(nearbyOriginProvider)!.latitude,
                'longitude': ref.read(nearbyOriginProvider)!.longitude,
              }
            : null,
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
          if (response.metadata['plan_usage'] is Map) {
            _usage = Map<String, dynamic>.from(response.metadata['plan_usage']);
          }
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

  void _newChat() => setState(() {
    _session = null;
    _history.clear();
    _response = null;
    _lastMessage = null;
    _error = null;
    _savedTripId = null;
    _controller.clear();
  });

  void _aiDetails() => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('About AI planning'),
      content: const Text(
        'Your messages and trip preferences are sent to the AI provider enabled by Trav’s administrator, including Gemini or Groq. Gemini’s free service may use submissions to improve its models. Avoid personal, sensitive or confidential details. AI can make mistakes; check travel details before you go. Each signed-in account can generate 5 completed plans per day, resetting at 00:00 UTC. Clarifying questions and failed generations do not count.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final signedIn =
        widget.api != null || ref.watch(authProvider).isAuthenticated;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'AI Planner',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: signedIn
            ? [
                IconButton(
                  tooltip: 'Recent plans',
                  onPressed: _loading ? null : _recentPlans,
                  icon: const Icon(Icons.history),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Planner options',
                  enabled: !_loading,
                  onSelected: (value) {
                    switch (value) {
                      case 'location':
                        _shareLocation();
                      case 'clear_location':
                        ref.read(aiLocationEnabledProvider.notifier).state =
                            false;
                        ref.read(nearbyOriginProvider.notifier).state = null;
                      case 'new':
                        _newChat();
                      case 'details':
                        _editBrief(newPlan: _session == null);
                      case 'daily':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StructuredPlanPage(
                              session: _session,
                              initialPlace: widget.initialPlace,
                            ),
                          ),
                        );
                      case 'nearby':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NearbyPlacesPage(),
                          ),
                        );
                      case 'book':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BookingLinksPage(),
                          ),
                        );
                      case 'forget':
                        _forgetPlan();
                      case 'about':
                        _aiDetails();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'new', child: Text('New chat')),
                    const PopupMenuItem(
                      value: 'location',
                      child: Text('Use current location'),
                    ),
                    if (ref.watch(aiLocationEnabledProvider))
                      const PopupMenuItem(
                        value: 'clear_location',
                        child: Text('Remove shared location'),
                      ),
                    const PopupMenuItem(
                      value: 'details',
                      child: Text('Trip details'),
                    ),
                    const PopupMenuItem(
                      value: 'daily',
                      child: Text('Build daily plan'),
                    ),
                    const PopupMenuItem(
                      value: 'nearby',
                      child: Text('Places nearby'),
                    ),
                    const PopupMenuItem(
                      value: 'book',
                      child: Text('Book travel directly'),
                    ),
                    if (_session != null)
                      const PopupMenuItem(
                        value: 'forget',
                        child: Text('Forget conversation'),
                      ),
                    const PopupMenuItem(
                      value: 'about',
                      child: Text('About AI planning'),
                    ),
                  ],
                ),
              ]
            : [],
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBar: signedIn
          ? SafeArea(
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
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        prefixIcon: _locating
                            ? const Padding(
                                padding: EdgeInsets.all(15),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: ref.watch(aiLocationEnabledProvider)
                                    ? 'Location shared · refresh'
                                    : 'Use my location',
                                onPressed: _loading ? null : _shareLocation,
                                icon: Icon(
                                  ref.watch(aiLocationEnabledProvider)
                                      ? Icons.my_location
                                      : Icons.location_searching,
                                  color: AppColors.primary,
                                ),
                              ),
                        hintText: _lastMessage == null
                            ? 'Ask Trav to plan a trip…'
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Send message',
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _locating ? null : _askAI,
                                icon: const Icon(Icons.arrow_upward_rounded),
                              ),
                      ),
                      onSubmitted: (_) => _askAI(),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: signedIn
          ? Center(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_lastMessage == null && _session == null) ...[
                        const SizedBox(height: 32),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 38,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Where shall we go?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tell us a place. Fine-tune the plan anytime.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _useSuggestion(
                                  ref.read(chosenPlaceAreaProvider) == null
                                      ? 'Help me plan a trip.'
                                      : 'Plan a trip to ${ref.read(chosenPlaceAreaProvider)!.name}, ${ref.read(chosenPlaceAreaProvider)!.countryName}. Use sensible defaults for anything I have not specified.',
                                ),
                                icon: const Icon(Icons.route_outlined),
                                label: const Text('Plan a trip'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _useSuggestion(
                                  ref.read(chosenPlaceAreaProvider) == null
                                      ? 'Help me find places to visit.'
                                      : 'Suggest places to visit in ${ref.read(chosenPlaceAreaProvider)!.name}, ${ref.read(chosenPlaceAreaProvider)!.countryName}.',
                                ),
                                icon: const Icon(Icons.explore_outlined),
                                label: const Text('Find places'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_usage?['remaining'] ?? 5} of 5 AI plans left today',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (widget.initialPlace != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Planning around ${widget.initialPlace!.name}',
                          ),
                        ),
                      if (_session != null && _lastMessage == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _session!['title'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
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
                        if (_response!.metadata['planning_stage'] !=
                            'questions')
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
                      TextButton.icon(
                        onPressed: _aiDetails,
                        icon: const Icon(Icons.info_outline, size: 15),
                        label: const Text('AI can make mistakes · About AI'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Let’s plan your next trip.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sign in for 5 AI plans per day. You can explore places without signing in.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => ensureSignedIn(context),
                      child: const Text('Sign in to plan'),
                    ),
                  ],
                ),
              ),
            ),
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
