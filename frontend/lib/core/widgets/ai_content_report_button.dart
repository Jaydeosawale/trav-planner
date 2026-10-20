import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../network/api_client.dart';

class AIContentReportButton extends StatelessWidget {
  const AIContentReportButton({
    super.key,
    required this.sourceKind,
    required this.referenceId,
    this.client,
  });
  final String sourceKind;
  final String referenceId;
  final Dio? client;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.flag_outlined),
    label: const Text('Report AI content'),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (_) => _ReportDialog(
        sourceKind: sourceKind,
        referenceId: referenceId,
        client: client ?? ApiClient.dio,
      ),
    ),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.sourceKind,
    required this.referenceId,
    required this.client,
  });
  final String sourceKind;
  final String referenceId;
  final Dio client;
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _details = TextEditingController();
  String _reason = 'unsafe';
  String? _error;
  bool _busy = false;
  bool _submitted = false;
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.client.post(
        '/ai/content-reports',
        data: {
          'source_kind': widget.sourceKind,
          'reference_id': widget.referenceId,
          'reason': _reason,
          'details': _details.text.trim(),
        },
      );
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Report could not be sent. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(_submitted ? 'Report received' : 'Report AI content'),
      content: _submitted
          ? const Text(
              'Thank you. Your report and the generated content were sent to the developer for review.',
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The generated answer or plan will be included. Please leave out passwords and other sensitive information.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _reason,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: const [
                      DropdownMenuItem(
                        value: 'unsafe',
                        child: Text('Unsafe or harmful'),
                      ),
                      DropdownMenuItem(
                        value: 'hate_or_harassment',
                        child: Text('Hate or harassment'),
                      ),
                      DropdownMenuItem(
                        value: 'sexual_content',
                        child: Text('Sexual content'),
                      ),
                      DropdownMenuItem(
                        value: 'misleading',
                        child: Text('Misleading information'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('Other concern'),
                      ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _reason = value!),
                  ),
                  TextField(
                    controller: _details,
                    enabled: !_busy,
                    maxLength: 1000,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Details (optional)',
                    ),
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
      actions: _submitted
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ]
          : [
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Sending…' : 'Send report'),
              ),
            ],
    ),
  );
}
