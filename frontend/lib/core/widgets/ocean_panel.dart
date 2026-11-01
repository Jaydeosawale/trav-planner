import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared ocean surface for small summaries and highlighted actions.
class OceanPanel extends StatelessWidget {
  const OceanPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: AppColors.oceanGradient,
      borderRadius: BorderRadius.circular(22),
    ),
    child: IconTheme(
      data: const IconThemeData(color: Color(0xFFFFBF85)),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    ),
  );
}
