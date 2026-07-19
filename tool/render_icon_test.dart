import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

Future<void> _registerMaterialIcons() async {
  final fontPath = _findMaterialIconsFont();
  final bytes = await File(fontPath).readAsBytes();
  final loader = FontLoader('MaterialIcons');
  loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
  // ignore: avoid_print
  print('loaded MaterialIcons from $fontPath');
}

String _findMaterialIconsFont() {
  const rel = 'artifacts/material_fonts/MaterialIcons-Regular.otf';
  final candidates = <String>[];

  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) {
    candidates.add('$env/bin/cache/$rel');
  }

  final exe = File(Platform.resolvedExecutable);
  candidates.add('${exe.parent.parent.parent.path}/$rel');

  var dir = Directory.current;
  for (var i = 0; i < 16; i++) {
    candidates.add('${dir.path}/bin/cache/$rel');
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }

  for (final c in candidates) {
    if (File(c).existsSync()) return c;
  }
  throw FileSystemException(
    'MaterialIcons font not found. Tried:\n  ${candidates.join("\n  ")}',
  );
}

const Color _kGradientStart = Color(0xFF6366F1);
const Color _kGradientEnd = Color(0xFF8B5CF6);

const double _kBoxSize = 72;
const double _kCornerRadius = 18;
const double _kIconSize = 44;

Future<ui.Image> _renderRoundedGradientWithCloud({
  required double size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, size, size);

  final scale = size / _kBoxSize;

  final paint = Paint()
    ..shader = const LinearGradient(
      colors: [_kGradientStart, _kGradientEnd],
    ).createShader(rect);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(_kCornerRadius * scale)),
    paint,
  );

  _drawCloud(canvas, size: size, iconSize: _kIconSize * scale);

  final picture = recorder.endRecording();
  return picture.toImage(size.toInt(), size.toInt());
}

Future<ui.Image> _renderCloudOnly({required double size}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const adaptiveCanvas = 108.0;
  final cloudLogical = (_kIconSize / _kBoxSize) * adaptiveCanvas * 0.86;
  final cloudPx = cloudLogical * (size / adaptiveCanvas);
  _drawCloud(canvas, size: size, iconSize: cloudPx);

  final picture = recorder.endRecording();
  return picture.toImage(size.toInt(), size.toInt());
}

Future<ui.Image> _renderGradientFill({required double size}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, size, size);

  final paint = Paint()
    ..shader = const LinearGradient(
      colors: [_kGradientStart, _kGradientEnd],
    ).createShader(rect);
  canvas.drawRect(rect, paint);

  final picture = recorder.endRecording();
  return picture.toImage(size.toInt(), size.toInt());
}

void _drawCloud(Canvas canvas,
    {required double size, required double iconSize}) {
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.cloud_outlined.codePoint),
      style: TextStyle(
        fontFamily: 'MaterialIcons',
        color: Colors.white,
        fontSize: iconSize,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
  tp.layout();
  final dx = (size - tp.width) / 2;
  final dy = (size - tp.height) / 2 - iconSize * 0.08;
  tp.paint(canvas, Offset(dx, dy));
}

Future<void> _writePng(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw StateError('Failed to encode PNG for $path');
  }
  final file = File(path);
  await file.writeAsBytes(bytes.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $path  (${file.statSync().size} bytes)');
}

void main() {
  test('render FamilyVault launcher & splash PNGs', () async {
    await _registerMaterialIcons();

    final assets = Directory('assets');
    if (!assets.existsSync()) {
      assets.createSync(recursive: true);
    }

    final icon = await _renderRoundedGradientWithCloud(size: 1024);
    await _writePng(icon, 'assets/icon.png');

    final fg = await _renderCloudOnly(size: 1024);
    await _writePng(fg, 'assets/icon_fg.png');

    final bg = await _renderGradientFill(size: 1024);
    await _writePng(bg, 'assets/icon_bg.png');

    final splash = await _renderRoundedGradientWithCloud(size: 768);
    await _writePng(splash, 'assets/splash_icon.png');
  });
}
