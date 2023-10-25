import 'dart:math';

import 'package:flutter/material.dart';
import 'package:draw_system/models/drawing_mode.dart';

class Sketch {
  final List<Offset> points;
  final Color color;
  final double size;
  final SketchType type;
  final bool filled;
  final Path path;
  final String text;

  Sketch(
      {required this.points,
      required this.path,
      this.color = Colors.black,
      this.type = SketchType.scribble,
      this.filled = true,
      this.size = 10,
      this.text = "Not a text"});

  static Path calculatePath(points) {
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length - 1; ++i) {
      final p0 = points[i];
      final p1 = points[i + 1];
      path.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2,
      );
    }

    return path;
  }

  List<Rect> calculateButtonPositions() {
    Rect pathRect = path.getBounds();

    double centerX = pathRect.center.dx;
    double centerY = pathRect.center.dy;

    Rect rect = Rect.fromCenter(
        center: Offset(centerX, centerY), width: 200, height: 200);

    Rect resizeButton = Rect.fromPoints(
        Offset(rect.right, rect.top), Offset(rect.right + 30, rect.top - 30));

    Rect rotateButton = Rect.fromPoints(Offset(centerX + 15, centerY - 100),
        Offset(centerX - 15, centerY - 130));

    Rect moveButton = Rect.fromCenter(
        center: Offset(centerX, centerY), width: 30, height: 30);

    if (type == SketchType.text) {
      //? TODO: implement difetent possitions for text sketches?

      return [
        rect,
        resizeButton,
        rotateButton,
        moveButton.shift(const Offset(0, 30))
      ];
    }

    return [rect, resizeButton, rotateButton, moveButton];
  }

  factory Sketch.fromDrawingMode(
    Sketch sketch,
    DrawingMode drawingMode,
    bool filled,
  ) {
    return Sketch(
      points: sketch.points,
      path: calculatePath(sketch.points),
      color: sketch.color,
      size: sketch.size,
      filled: drawingMode == DrawingMode.line ||
              drawingMode == DrawingMode.pencil ||
              drawingMode == DrawingMode.eraser
          ? false
          : filled,
      type: () {
        switch (drawingMode) {
          case DrawingMode.eraser:
          case DrawingMode.pencil:
            return SketchType.scribble;
          case DrawingMode.line:
            return SketchType.line;
          case DrawingMode.square:
            return SketchType.square;
          case DrawingMode.circle:
            return SketchType.circle;
          default:
            return SketchType.scribble;
        }
      }(),
    );
  }

  factory Sketch.fromPath(
    Sketch sketch,
    Path path,
    double size,
  ) {
    return Sketch(
      points: sketch.points,
      path: path,
      color: sketch.color,
      size: size,
      filled: sketch.filled,
      type: sketch.type,
      text: sketch.text,
    );
  }

  factory Sketch.fromText(String text) {
    const TextStyle textStyle = TextStyle(
      color: Colors.black,
      fontSize: 30,
    );

    TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: double.infinity);

    Offset offset = Offset(textPainter.width, textPainter.height);

    return Sketch(
      points: [offset],
      path: calculatePath([offset]),
      type: SketchType.text,
      text: text,
      color: Colors.white,
    );
  }

  Offset calculateMove(Offset offset) {
    Rect pathRect = path.getBounds();

    double centerX = pathRect.center.dx;
    double centerY = pathRect.center.dy;

    return Offset((offset.dx - centerX), (offset.dy - centerY));
  }

  double calculateRotationAngle(Offset center, Offset offset) {
    Offset touchVector = offset - center;

    double angleInRadians = (atan2(touchVector.dy, touchVector.dx) + (pi / 2));
    return angleInRadians;
  }

  double calculateResize(Offset center, Offset offset) {
    double minDistance = 0;
    double maxDistance = 141.4213562373095;
    double minScale = 0.3;
    double maxScale = 1;

    double distance =
        sqrt(pow(offset.dx - center.dx, 2) + pow(offset.dy - center.dy, 2));

    double scaleFactor = (distance - minDistance) *
            ((maxScale - minScale) / (maxDistance - minDistance)) +
        minScale;

    return scaleFactor;
  }

  Map<String, dynamic> toJson() {
    List<Map> pointsMap = points.map((e) => {'dx': e.dx, 'dy': e.dy}).toList();
    return {
      'points': pointsMap,
      'color': color.toHex(),
      'size': size,
      'filled': filled,
      'type': type.toRegularString(),
    };
  }

  factory Sketch.fromJson(Map<String, dynamic> json) {
    List<Offset> points =
        (json['points'] as List).map((e) => Offset(e['dx'], e['dy'])).toList();
    return Sketch(
      path: calculatePath(points),
      points: points,
      color: (json['color'] as String).toColor(),
      size: json['size'],
      filled: json['filled'],
      type: (json['type'] as String).toSketchTypeEnum(),
    );
  }
}

enum SketchType { scribble, line, square, circle, text }

extension SketchTypeX on SketchType {
  toRegularString() => toString().split('.')[1];
}

extension SketchTypeExtension on String {
  toSketchTypeEnum() =>
      SketchType.values.firstWhere((e) => e.toString() == 'SketchType.$this');
}

extension ColorExtension on String {
  Color toColor() {
    var hexColor = replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    } else {
      return Colors.black;
    }
  }
}

extension ColorExtensionX on Color {
  String toHex() => '#${value.toRadixString(16).substring(2, 8)}';
}
