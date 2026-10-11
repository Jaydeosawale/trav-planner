import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shared identity for app headers, authentication, navigation and admin screens.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40, this.compact = false});
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Trav',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/branding/trav-symbol.png',
          width: size * 1.12,
          height: size * 1.12,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        if (!compact) ...[
          SizedBox(width: size * .16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'trav',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.primary,
                  ),
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
        ],
      ],
    ),
  );
}
