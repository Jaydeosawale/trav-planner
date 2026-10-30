import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/widgets/full_photo_frame.dart';

void main() {
  for (final size in [const Size(40, 80), const Size(80, 40)]) {
    testWidgets(
      'whole ${size.width}x${size.height} photo retains sharp corner markers',
      (tester) async {
        late Uint8List bytes;
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawRect(Offset.zero & size, Paint()..color = Colors.green);
          for (final offset in [
            Offset.zero,
            Offset(size.width - 4, 0),
            Offset(0, size.height - 4),
            Offset(size.width - 4, size.height - 4),
          ]) {
            canvas.drawRect(
              offset & const Size(4, 4),
              Paint()..color = Colors.red,
            );
          }
          final source = await recorder.endRecording().toImage(
            size.width.toInt(),
            size.height.toInt(),
          );
          bytes = (await source.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          source.dispose();
        });
        final provider = MemoryImage(bytes);
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: 120,
                    height: 80,
                    child: FullPhotoFrame(
                      image: Image(image: provider, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => precacheImage(provider, key.currentContext!),
        );
        await tester.pumpAndSettle();
        late ByteData pixels;
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final rendered = await boundary.toImage();
          pixels = (await rendered.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          rendered.dispose();
        });
        final corners = size.height > size.width
            ? [const Offset(41, 1), const Offset(78, 78)]
            : [const Offset(1, 11), const Offset(118, 68)];
        for (final corner in corners) {
          final index = (corner.dy.toInt() * 120 + corner.dx.toInt()) * 4;
          expect(pixels.getUint8(index), greaterThan(220));
          expect(
            pixels.getUint8(index + 1),
            lessThan(80),
            reason:
                'Original sharp corners must remain visible, not a blurred/cropped copy.',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
