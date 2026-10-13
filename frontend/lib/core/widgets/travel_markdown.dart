import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../theme/app_colors.dart';

/// Render AI and saved notes without loading model-supplied image URLs.
class TravelMarkdown extends StatelessWidget {
  const TravelMarkdown({super.key, required this.content});
  final String content;

  @override
  Widget build(BuildContext context) => MarkdownBody(
    data: content,
    selectable: true,
    imageBuilder: (uri, title, alt) => Text(alt ?? 'Image unavailable'),
    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: const TextStyle(
        fontSize: 15,
        height: 1.6,
        color: AppColors.textPrimary,
      ),
      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      h2: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      blockSpacing: 16,
      tableCellsPadding: const EdgeInsets.all(8),
      tableBorder: TableBorder.all(color: AppColors.surfaceVariant),
      tableHead: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
