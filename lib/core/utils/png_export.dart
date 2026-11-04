import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures the widget behind [key] and writes it as a PNG.
///
/// Returns the absolute file path, or null when capture fails.
Future<String?> exportPng(
  GlobalKey key,
  Directory directory,
  String prefix, {
  double pixelRatio = 3,
}) async {
  final context = key.currentContext;
  if (context == null) return null;
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) return null;
  try {
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return null;
    final bytes = data.buffer.asUint8List();
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}$prefix-${_timestamp()}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (_) {
    return null;
  }
}

String _timestamp() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}-'
      '${two(now.hour)}${two(now.minute)}${two(now.second)}';
}
