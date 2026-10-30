import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Keep the complete photo sharp; fill spare frame space with its own colours.
/// Both layers share the same provider/cache, so this adds no image API request.
class FullPhotoFrame extends StatelessWidget {
  const FullPhotoFrame({super.key, required this.image});
  final Image image;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: image.width,
    height: image.height,
    child: ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.surfaceVariant),
          ExcludeSemantics(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: 4,
                sigmaY: 4,
                tileMode: ui.TileMode.clamp,
              ),
              child: Opacity(
                opacity: .95,
                child: Image(
                  image: image.image,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.expand(),
                ),
              ),
            ),
          ),
          image,
        ],
      ),
    ),
  );
}
