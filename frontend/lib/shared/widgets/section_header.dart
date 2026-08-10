import 'package:flutter/material.dart';

import '../../core/theme/app_text_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextTheme.textTheme.titleLarge,
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: const Text("See All"),
        ),
      ],
    );
  }
}