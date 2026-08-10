import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/responsive/responsive_values.dart';

class PremiumSearchBar extends StatefulWidget {
  final bool compact;

  const PremiumSearchBar({
    super.key,
    this.compact = false,
  });

  @override
  State<PremiumSearchBar> createState() =>
      _PremiumSearchBarState();
}

class _PremiumSearchBarState
    extends State<PremiumSearchBar> {
  final FocusNode _focusNode = FocusNode();

  bool _focused = false;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _focused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.compact
        ? 24.0
        : ResponsiveValues.largeRadius(context);

    final height = widget.compact
        ? 48.0
        : ResponsiveValues.searchBarHeight(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _focused ? 24 : 18,
          sigmaY: _focused ? 24 : 18,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 250,
          ),
          height: height,
          decoration: BoxDecoration(
            color: widget.compact
                ? const Color(0xFFF4F6FA)
                : Colors.white.withValues(
                    alpha: _focused ? .58 : .18,
                  ),
            borderRadius:
                BorderRadius.circular(radius),
            border: Border.all(
              color: widget.compact
                  ? const Color(0xFFE2E7EF)
                  : Colors.white.withValues(
                      alpha: _focused ? .40 : .22,
                    ),
            ),
            boxShadow: widget.compact
                ? const []
                : [
                    BoxShadow(
                      blurRadius:
                          _focused ? 28 : 18,
                      color: Colors.black.withValues(
                        alpha: .10,
                      ),
                      offset:
                          const Offset(0, 8),
                    ),
                  ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme:
                  const InputDecorationTheme(
                filled: false,
                fillColor:
                    Colors.transparent,
                border: InputBorder.none,
                enabledBorder:
                    InputBorder.none,
                focusedBorder:
                    InputBorder.none,
              ),
            ),
            child: TextField(
              focusNode: _focusNode,
              textAlignVertical:
                  TextAlignVertical.center,
              style: TextStyle(
                color: widget.compact
                    ? const Color(0xFF1F2937)
                    : (_focused
                        ? Colors.black87
                        : Colors.white),
                fontWeight: FontWeight.w600,
                fontSize:
                    widget.compact ? 14 : 16,
              ),
              decoration:
                  InputDecoration(
                isDense: true,
                filled: false,
                fillColor:
                    Colors.transparent,
                border: InputBorder.none,
                enabledBorder:
                    InputBorder.none,
                focusedBorder:
                    InputBorder.none,
                disabledBorder:
                    InputBorder.none,
                errorBorder:
                    InputBorder.none,
                focusedErrorBorder:
                    InputBorder.none,

                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
                ),

                hintText:
                    'Where would you like to go?',

                hintStyle: TextStyle(
                  color: widget.compact
                      ? const Color(0xFF6B7280)
                      : (_focused
                          ? Colors.black54
                          : Colors.white.withValues(
                              alpha: .90,
                            )),
                  fontSize:
                      widget.compact ? 14 : 16,
                  fontWeight:
                      FontWeight.w500,
                ),

                prefixIcon: SizedBox(
                  width:
                      widget.compact ? 42 : 48,
                  child: Icon(
                    Icons.search,
                    size:
                        widget.compact ? 20 : 22,
                    color: widget.compact
                        ? const Color(0xFF6B7280)
                        : (_focused
                            ? Colors.black54
                            : Colors.white),
                  ),
                ),

                suffixIcon: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size:
                          widget.compact ? 17 : 20,
                      color: widget.compact
                          ? const Color(0xFF2563EB)
                          : (_focused
                              ? Colors.blue
                              : Colors.white),
                    ),

                    const SizedBox(width: 10),

                    Icon(
                      Icons.mic_none_rounded,
                      size:
                          widget.compact ? 19 : 22,
                      color: widget.compact
                          ? const Color(0xFF6B7280)
                          : (_focused
                              ? Colors.black54
                              : Colors.white),
                    ),

                    SizedBox(
                      width:
                          widget.compact ? 12 : 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}