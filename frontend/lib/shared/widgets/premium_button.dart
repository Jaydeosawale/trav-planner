import 'package:flutter/material.dart';

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}