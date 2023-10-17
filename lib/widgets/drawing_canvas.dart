import 'dart:io';

import "package:flutter/material.dart";
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:draw_system/models/drawing_mode.dart';
import 'package:draw_system/models/sketch.dart';

class DrawingCanvas extends HookWidget {
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final AnimationController sideBarController;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<bool> filled;
  final String imagePath;
  final double? imageHeight;
  final double? imageWidth;

  const DrawingCanvas({
    Key? key,
    required this.selectedColor,
    required this.strokeSize,
    required this.eraserSize,
    required this.drawingMode,
    required this.sideBarController,
    required this.currentSketch,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.imagePath,
    this.imageWidth,
    this.imageHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.file(
          File(imagePath),
        ),
        ClipRRect(
          child: SizedBox(
            width: 200,
            height: 200,
            child: buildAllPaths(),
          ),
        ),
        ClipRRect(
          child: SizedBox(
            width: 200,
            height: 200,
            child: buildCurrentPath(context),
          ),
        ),
      ],
    );
  }

  Widget buildAllPaths() {
    return RepaintBoundary(
      child: CustomPaint(
        painter: SketchPainter(sketches: allSketches.value),
      ),
    );
  }

  Widget buildCurrentPath(BuildContext context) {
    return Listener(
      onPointerDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.globalToLocal(details.position);

        currentSketch.value = Sketch.fromDrawingMode(
          Sketch(
            points: [offset],
            color: selectedColor.value,
            size: strokeSize.value,
          ),
          drawingMode.value,
          filled.value,
        );
      },
      onPointerMove: (details) {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.globalToLocal(details.position);
        final points = List<Offset>.from(currentSketch.value?.points ?? [])
          ..add(offset);

        currentSketch.value = Sketch.fromDrawingMode(
            Sketch(
                points: points,
                color: selectedColor.value,
                size: strokeSize.value),
            drawingMode.value,
            filled.value);
      },
      onPointerUp: (details) {
        allSketches.value = List<Sketch>.from(allSketches.value)
          ..add(currentSketch.value!);
      },
      child: RepaintBoundary(
        child: SizedBox(
          child: CustomPaint(
            painter: SketchPainter(
                sketches:
                    currentSketch.value == null ? [] : [currentSketch.value!]),
          ),
        ),
      ),
    );
  }
}

class SketchPainter extends CustomPainter {
  final List<Sketch> sketches;

  SketchPainter({required this.sketches});

  @override
  void paint(Canvas canvas, Size size) {
    for (Sketch sketch in sketches) {
      final points = sketch.points;

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

      Paint paint = Paint()
        ..color = sketch.color
        ..strokeCap = StrokeCap.round;

      if (!sketch.filled) {
        paint.strokeWidth = sketch.size;
        paint.style = PaintingStyle.stroke;
      }

      Offset firstPoint = sketch.points.first;
      Offset lastPoint = sketch.points.last;

      Rect rect = Rect.fromPoints(firstPoint, lastPoint);

      if (sketch.type == SketchType.scribble) {
        canvas.drawPath(path, paint);
      } else if (sketch.type == SketchType.line) {
        canvas.drawLine(firstPoint, lastPoint, paint);
      } else if (sketch.type == SketchType.circle) {
        canvas.drawOval(rect, paint);
      } else if (sketch.type == SketchType.square) {
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
