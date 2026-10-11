import 'package:trav_planner/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const GradientText({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppColors.accent, AppColors.primary],
      ).createShader(bounds),
      child: Text(text, style: style.copyWith(color: AppColors.textPrimary)),
    );
  }
}
