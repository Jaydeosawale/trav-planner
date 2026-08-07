import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/responsive/responsive_values.dart';

class PremiumSearchBar extends StatefulWidget {
  const PremiumSearchBar({super.key});

  @override
  State<PremiumSearchBar> createState() => _PremiumSearchBarState();
}

class _PremiumSearchBarState extends State<PremiumSearchBar> {
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
    final radius = ResponsiveValues.largeRadius(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _focused ? 24 : 18,
          sigmaY: _focused ? 24 : 18,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: ResponsiveValues.searchBarHeight(context),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: _focused ? .58 : .18,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: _focused ? .40 : .22,
              ),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: _focused ? 28 : 18,
                color: Colors.black.withValues(alpha: .10),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            child: TextField(
              focusNode: _focusNode,
              style: TextStyle(
                color: _focused ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18),
                hintText: "Where do you want to travel?",
                hintStyle: TextStyle(
                  color: _focused
                      ? Colors.black54
                      : Colors.white.withValues(alpha: .90),
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color:
                      _focused ? Colors.black54 : Colors.white,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color:
                          _focused ? Colors.blue : Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.mic_none_rounded,
                      color: _focused
                          ? Colors.black54
                          : Colors.white,
                    ),
                    const SizedBox(width: 16),
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