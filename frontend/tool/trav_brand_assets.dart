import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final symbol = img.decodePng(
    File('assets/images/branding/trav-symbol.png').readAsBytesSync(),
  )!;
  img.Image icon(int size, {bool maskable = false}) {
    final canvas = img.Image(width: size, height: size, numChannels: 4);
    img.fill(canvas, color: img.ColorRgba8(248, 250, 252, 255));
    final edge = (size * (maskable ? .62 : .82)).round();
    final mark = img.copyResize(
      symbol,
      width: edge,
      height: edge,
      interpolation: img.Interpolation.cubic,
    );
    img.compositeImage(
      canvas,
      mark,
      dstX: (size - edge) ~/ 2,
      dstY: (size - edge) ~/ 2,
    );
    return canvas;
  }

  void save(String path, int size, {bool maskable = false}) {
    File(path).writeAsBytesSync(img.encodePng(icon(size, maskable: maskable)));
  }

  for (final entry in {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  }.entries) {
    save(
      'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      entry.value,
    );
  }
  save('web/favicon.png', 48);
  for (final size in [192, 512]) {
    save('web/icons/Icon-$size.png', size);
    save('web/icons/Icon-maskable-$size.png', size, maskable: true);
  }
  for (final directory in [
    'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    'macos/Runner/Assets.xcassets/AppIcon.appiconset',
  ]) {
    final config = jsonDecode(
      File('$directory/Contents.json').readAsStringSync(),
    );
    for (final entry in config['images']) {
      final filename = entry['filename'];
      if (filename == null) continue;
      final points = double.parse((entry['size'] as String).split('x')[0]);
      final scale = double.parse(
        (entry['scale'] as String).replaceAll('x', ''),
      );
      save('$directory/$filename', (points * scale).round());
    }
  }
  File('windows/runner/resources/app_icon.ico').writeAsBytesSync(
    img.IcoEncoder().encodeImages([
      for (final size in [16, 32, 48, 64, 128, 256]) icon(size),
    ]),
  );
  File('assets/images/branding/travplanner_symbol_1024.png').writeAsBytesSync(
    img.encodePng(img.copyResize(symbol, width: 1024, height: 1024)),
  );
  stdout.writeln('Exported Android, iOS, macOS, Windows and web branding.');
}
