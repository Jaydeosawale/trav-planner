import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Scalable wordmark using a bundled font.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40, this.compact = false});
  final double size;
  final bool compact;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Trav Planner',
    excludeSemantics: true,
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: compact ? 't' : 'trav',
            style: const TextStyle(color: AppColors.primary),
          ),
          const TextSpan(
            text: '.',
            style: TextStyle(color: AppColors.sunset),
          ),
        ],
      ),
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -size * .065,
      ),
    ),
  );
}
