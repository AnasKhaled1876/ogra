import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String _masterIconPath = 'assets/icons/app_icon-master.png';

const Map<String, int> _androidIcons = <String, int>{
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
  'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
};

const Map<String, int> _iosIcons = <String, int>{
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate branded app icons', () async {
    final masterIcon = await _renderMasterIcon();
    await _writeImage(masterIcon, _masterIconPath);

    for (final entry in <MapEntry<String, int>>[
      ..._androidIcons.entries,
      ..._iosIcons.entries,
    ]) {
      final resized = await _resizeImage(masterIcon, entry.value);
      await _writeImage(resized, entry.key);
      resized.dispose();
    }

    masterIcon.dispose();
  });
}

Future<ui.Image> _renderMasterIcon() async {
  const int size = 1024;
  final iconSvg = File('assets/images/minibus_icon.svg').readAsStringSync();
  final darkBusSvg = iconSvg.replaceAll(
    'fill="var(--fill-0, #F5A623)"',
    'fill="#14181C"',
  );
  final pictureInfo = await vg.loadPicture(SvgStringLoader(darkBusSvg), null);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
  );
  final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
  const bgStart = Color(0xFF0D0F12);
  const bgEnd = Color(0xFF181D23);
  const amberLight = Color(0xFFFFC34A);
  const amber = Color(0xFFF5A623);
  const amberDark = Color(0xFFD48806);

  final background = RRect.fromRectAndRadius(
    rect,
    const Radius.circular(232),
  );

  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(size.toDouble(), size.toDouble()),
        const <Color>[bgStart, bgEnd],
      ),
  );

  canvas.drawRRect(
    background,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(size.toDouble(), size.toDouble()),
        const <Color>[bgStart, bgEnd],
      ),
  );

  canvas.drawCircle(
    const Offset(294, 208),
    312,
    Paint()..color = const Color(0x14F5A623),
  );

  canvas.drawCircle(
    const Offset(512, 512),
    376,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..color = const Color(0x2EF5A623),
  );

  canvas.drawCircle(
    const Offset(512, 512),
    324,
    Paint()
      ..shader = ui.Gradient.radial(
        const Offset(420, 380),
        420,
        const <Color>[amberLight, amber, amberDark],
        const <double>[0.0, 0.68, 1.0],
      ),
  );

  canvas.drawCircle(
    const Offset(512, 512),
    324,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0x22FFFFFF),
  );

  final targetWidth = 500.0;
  final targetHeight = targetWidth * pictureInfo.size.height / pictureInfo.size.width;
  final targetRect = Rect.fromCenter(
    center: const Offset(512, 510),
    width: targetWidth,
    height: targetHeight,
  );

  canvas.save();
  canvas.translate(targetRect.left, targetRect.top);
  canvas.scale(
    targetRect.width / pictureInfo.size.width,
    targetRect.height / pictureInfo.size.height,
  );
  canvas.drawPicture(pictureInfo.picture);
  canvas.restore();

  pictureInfo.picture.dispose();
  final picture = recorder.endRecording();
  return picture.toImage(size, size);
}

Future<ui.Image> _resizeImage(ui.Image source, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
  );

  canvas.drawImageRect(
    source,
    Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high,
  );

  return recorder.endRecording().toImage(size, size);
}

Future<void> _writeImage(ui.Image image, String path) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode icon image for $path');
  }

  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(byteData.buffer.asUint8List(), flush: true);

  if (path.contains('ios/Runner/Assets.xcassets/AppIcon.appiconset/')) {
    _stripAlphaChannel(path);
  }
}

void _stripAlphaChannel(String path) {
  final tempDir = Directory.systemTemp.createTempSync('ogra-icon-strip-');
  final jpegPath = '${tempDir.path}/icon.jpg';

  final toJpeg = Process.runSync(
    '/usr/bin/sips',
    <String>[
      '-s',
      'format',
      'jpeg',
      '-s',
      'formatOptions',
      'best',
      path,
      '--out',
      jpegPath,
    ],
  );
  if (toJpeg.exitCode != 0) {
    tempDir.deleteSync(recursive: true);
    throw StateError('Failed converting $path to JPEG: ${toJpeg.stderr}');
  }

  final backToPng = Process.runSync(
    '/usr/bin/sips',
    <String>[
      '-s',
      'format',
      'png',
      jpegPath,
      '--out',
      path,
    ],
  );
  tempDir.deleteSync(recursive: true);

  if (backToPng.exitCode != 0) {
    throw StateError('Failed converting $path back to PNG: ${backToPng.stderr}');
  }
}
