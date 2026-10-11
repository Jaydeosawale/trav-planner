import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../data/datasources/ai_api.dart';
import '../../data/models/ai_response_model.dart';

class AISearchPage extends StatefulWidget {
  const AISearchPage({super.key});

  @override
  State<AISearchPage> createState() => _AISearchPageState();
}

class _AISearchPageState extends State<AISearchPage> {
  final TextEditingController _controller = TextEditingController();
  final AIApi _api = AIApi();

  bool _loading = false;
  String? _error;
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
      _error = null;
      _response = null;
    });

    try {
      final response = await _api.chat(message: message);

      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
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
            Text(
              'Trav Planner AI',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
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
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),

                const SizedBox(height: 20),

                const Text(
                  'The idea is yours.\nThe plan is on us.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 10),

                Text(
                  'Share your dates, budget and interests. Ask trav. AI about '
                  'places, or trip planning.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                TextField(
                  controller: _controller,
                  enabled: !_loading,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Ask anything about your trip...',
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

                if (_loading) const _LoadingCard(),

                if (_error != null)
                  _ErrorCard(message: _error!, onRetry: _askAI),

                if (_response != null) _ResponseCard(response: _response!),
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
              'Trav Planner AI is thinking...',
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
                  'Trav Planner AI',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (response.metadata['provider'] != null)
                Text(
                  response.metadata['provider'].toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          SelectableText(
            response.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),

          if (response.metadata['tools_used'] is List &&
              (response.metadata['tools_used'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Tools used: ${(response.metadata['tools_used'] as List).join(', ')}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
