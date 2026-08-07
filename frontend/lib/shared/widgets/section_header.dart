import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

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
          style: AppTextStyles.heading,
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