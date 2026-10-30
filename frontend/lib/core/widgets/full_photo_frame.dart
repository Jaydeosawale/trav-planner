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
                sigmaX: 16,
                sigmaY: 16,
                tileMode: ui.TileMode.clamp,
              ),
              child: Opacity(
                opacity: .32,
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
