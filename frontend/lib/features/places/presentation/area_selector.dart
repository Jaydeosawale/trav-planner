import '../../auth/presentation/widgets/require_sign_in.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/place_area.dart';

String areaFailure(Object error) {
  if (error is DioException && error.response?.statusCode == 401) {
    return 'Sign in to open this destination. Your search is kept.';
  }
  if (error is DioException && error.response?.statusCode == 409) {
    return 'This location cannot be added within the current free storage limit. Choose a known destination.';
  }
  return 'We couldn’t open this destination. Please try again.';
}

class AreaCandidates extends ConsumerStatefulWidget {
  const AreaCandidates({
    super.key,
    required this.query,
    this.countryId,
    this.onSelected,
  });
  final String query;
  final String? countryId;
  final ValueChanged<PlaceArea>? onSelected;
  @override
  ConsumerState<AreaCandidates> createState() => _AreaCandidatesState();
}

class _AreaCandidatesState extends ConsumerState<AreaCandidates> {
  bool _busy = false;
  int _limit = 8;
  @override
  void didUpdateWidget(covariant AreaCandidates oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.countryId != widget.countryId) {
      _limit = 8;
      _notice = null;
    }
  }

  String? _notice;
  @override
  Widget build(BuildContext context) {
    if (widget.query.trim().length < 2) return const SizedBox.shrink();
    final request = PlaceAreaSearch(
      widget.query.trim(),
      countryId: widget.countryId,
    );
    return ref
        .watch(areaSearchProvider(request))
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(areaSearchProvider(request)),
            child: const Text('Retry destination search'),
          ),
          data: (result) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Destinations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (result.notice != null) Text(result.notice!),
              if (_notice != null) Text(_notice!),
              if (_busy) const LinearProgressIndicator(),
              if (result.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No matching destinations. Try a nearby town or another spelling.',
                  ),
                ),
              for (final area in result.items.take(_limit))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(area.name),
                  subtitle: Text(
                    area.subtitle.isEmpty
                        ? 'Destination · map location available'
                        : area.subtitle,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy
                      ? null
                      : () async {
                          setState(() {
                            _busy = true;
                            _notice = null;
                          });
                          try {
                            if (area.cityId == null &&
                                !await ensureSignedIn(context, ref)) {
                              return;
                            }
                            final selected = await ref
                                .read(placeAreaApiProvider)
                                .open(area);
                            if (!mounted) return;
                            ref.read(chosenPlaceAreaProvider.notifier).state =
                                selected;
                            widget.onSelected?.call(selected);
                          } catch (error) {
                            if (mounted) {
                              setState(() => _notice = areaFailure(error));
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                ),
              if (result.items.length > _limit)
                TextButton(
                  onPressed: () => setState(() => _limit = result.items.length),
                  child: const Text('More matching destinations'),
                ),
            ],
          ),
        );
  }
}

Future<void> showPlaceAreaPicker(
  BuildContext context, {
  ValueChanged<PlaceArea>? onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _AreaSheet(onChanged: onChanged),
);

class AreaSelector extends ConsumerWidget {
  const AreaSelector({super.key, this.onChanged, this.compact = false});
  final bool compact;
  final ValueChanged<PlaceArea>? onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(chosenPlaceAreaProvider);
    return OutlinedButton.icon(
      style: compact
          ? OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              minimumSize: const Size(0, 44),
            )
          : null,
      icon: Icon(Icons.location_on_outlined, size: compact ? 17 : 22),
      label: Text(
        area == null
            ? (compact ? 'Choose area' : 'Choose an area')
            : '${area.name} · Change',
        maxLines: compact ? 1 : 2,
        overflow: TextOverflow.ellipsis,
        style: compact ? const TextStyle(fontSize: 12) : null,
      ),
      onPressed: () => showPlaceAreaPicker(context, onChanged: onChanged),
    );
  }
}

class _AreaSheet extends StatefulWidget {
  const _AreaSheet({this.onChanged});
  final ValueChanged<PlaceArea>? onChanged;
  @override
  State<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends State<_AreaSheet> {
  String _query = '';
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Where would you like to explore?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'City or small town',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () {
                if (mounted) setState(() => _query = value);
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: AreaCandidates(
                query: _query,
                onSelected: (area) {
                  widget.onChanged?.call(area);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
