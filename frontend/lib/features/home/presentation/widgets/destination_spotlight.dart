import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/models/banner_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Destination photography rotates without adding controls to the hero.
class DestinationSpotlight extends StatefulWidget {
  const DestinationSpotlight({
    super.key,
    required this.banners,
    required this.onSearch,
    this.search,
  });
  final List<BannerModel> banners;
  final ValueChanged<String> onSearch;
  final Widget? search;

  @override
  State<DestinationSpotlight> createState() => _DestinationSpotlightState();
}

class _DestinationSpotlightState extends State<DestinationSpotlight>
    with WidgetsBindingObserver {
  final _pages = PageController();
  bool _hovered = false;
  bool _focused = false;
  Timer? _timer;
  int _index = 0;
  bool _foreground = true;
  bool _tabVisible = true;
  bool _interacting = false;
  bool _reduceMotion = false;
  static const _places = [
    ('Bali, Indonesia', 'bali'),
    ('Goa, India', 'goa'),
    ('Paris, France', 'paris'),
  ];

  int get _count => widget.banners.length + _places.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tabVisible = TickerMode.valuesOf(context).enabled;
    _schedule();
  }

  @override
  void didUpdateWidget(DestinationSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _index = 0;
      if (_pages.hasClients) _pages.jumpToPage(0);
      _schedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_tabVisible ||
        _reduceMotion ||
        !_foreground ||
        _interacting ||
        _hovered ||
        _focused ||
        !mounted) {
      return;
    }
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_pages.hasClients) return;
      _pages.animateToPage(
        (_index + 1) % _count,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _interaction(bool active) {
    _interacting = active;
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final label = _index < widget.banners.length
        ? widget.banners[_index].title
        : _places[_index - widget.banners.length].$1;
    return Focus(
      onFocusChange: (value) {
        _focused = value;
        _schedule();
      },
      child: MouseRegion(
        onEnter: (_) {
          _hovered = true;
          _schedule();
        },
        onExit: (_) {
          _hovered = false;
          _schedule();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification &&
                        notification.dragDetails != null) {
                      _interaction(true);
                    } else if (notification is ScrollEndNotification) {
                      _interaction(false);
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _count,
                    onPageChanged: (index) {
                      setState(() => _index = index);
                      _schedule();
                    },
                    itemBuilder: (context, index) {
                      if (index < widget.banners.length) {
                        return Image.network(
                          widget.banners[index].imageUrl,
                          fit: BoxFit.cover,
                          semanticLabel: widget.banners[index].title,
                          errorBuilder: (_, error, stack) =>
                              const ColoredBox(color: AppColors.ocean),
                        );
                      }
                      return Image.asset(
                        'assets/images/destinations/${_places[index - widget.banners.length].$2}_1.jpg',
                        fit: BoxFit.cover,
                        semanticLabel:
                            _places[index - widget.banners.length].$1,
                      );
                    },
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x20123E46), Color(0xEF102F39)],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: widget.search == null
                      ? (wide ? 260 : 200)
                      : (wide ? 340 : 260),
                ),
                padding: EdgeInsets.all(wide ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.ocean,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 2,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ocean,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: wide ? 40 : 24),
                    IgnorePointer(
                      child: Text(
                        'Somewhere worth going.',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontSize: wide ? 44 : 30,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    if (widget.search != null) ...[
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: widget.search!,
                      ),
                    ],
                    const SizedBox(height: 18),
                    Semantics(
                      label:
                          'Featured destination ${_index + 1} of $_count: $label',
                      child: ExcludeSemantics(
                        child: SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 7,
                            children: List.generate(
                              _count,
                              (index) => Container(
                                width: index == _index ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: index == _index
                                      ? AppColors.sunset
                                      : Colors.white54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
