import 'dart:ui';

import "package:flutter/material.dart";
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:draw_system/models/drawing_mode.dart';
import 'package:draw_system/models/sketch.dart';

class DrawingCanvas extends HookWidget {
  final double height;
  final double width;
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final AnimationController sideBarController;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<bool> filled;
  final ValueNotifier<String> pointerMode;
  final ValueNotifier<Path> rotatePath;

  const DrawingCanvas({
    Key? key,
    required this.height,
    required this.width,
    required this.selectedColor,
    required this.strokeSize,
    required this.eraserSize,
    required this.drawingMode,
    required this.sideBarController,
    required this.currentSketch,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.pointerMode,
    required this.rotatePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildAllPaths(),
        buildCurrentPath(context, pointerMode),
      ],
    );
  }

  Widget buildAllPaths() {
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: width,
        child: CustomPaint(
          painter: SketchPainter(
            sketches: allSketches.value,
            displayTransformersControls:
                allSketches.value.isNotEmpty && currentSketch.value == null,
          ),
        ),
      ),
    );
  }

  Widget buildCurrentPath(
    BuildContext context,
    ValueNotifier<String> pointerMode,
  ) {
    return Listener(
      onPointerDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.globalToLocal(details.position);

        List<Rect> buttons = [];

        if (allSketches.value.isNotEmpty) {
          buttons = allSketches.value.last.calculateButtonPositions();
        }

        if (buttons.isNotEmpty && buttons[1].contains(offset)) {
          print("scaleButton");
          pointerMode.value = "scale";
        } else if (buttons.isNotEmpty && buttons[2].contains(offset)) {
          rotatePath.value = allSketches.value.last.path;
          pointerMode.value = "rotate";
        } else if (buttons.isNotEmpty && buttons[3].contains(offset)) {
          pointerMode.value = "move";
        } else {
          pointerMode.value = "draw";
          currentSketch.value = Sketch.fromDrawingMode(
            Sketch(
              path: Path(),
              points: [offset],
              color: selectedColor.value,
              size: strokeSize.value,
            ),
            drawingMode.value,
            filled.value,
          );
        }
      },
      onPointerMove: (details) {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.globalToLocal(details.position);

        if (pointerMode.value == "draw") {
          final points = List<Offset>.from(currentSketch.value?.points ?? [])
            ..add(offset);

          currentSketch.value = Sketch.fromDrawingMode(
            Sketch(
                path: Path(),
                points: points,
                color: selectedColor.value,
                size: strokeSize.value),
            drawingMode.value,
            filled.value,
          );
        } else if (pointerMode.value == "move") {
          Sketch lastSketch = allSketches.value.removeLast();
          Offset moveOffset = lastSketch.calculateMove(offset);

          Path translatedPath = lastSketch.path.shift(moveOffset);

          Sketch updateSketch = Sketch.fromPath(lastSketch, translatedPath);

          allSketches.value = List.from(allSketches.value)..add(updateSketch);
        } else if (pointerMode.value == "rotate") {
          Sketch lastSketch = allSketches.value.removeLast();

          Offset center = rotatePath.value.getBounds().center;

          double rotationAngle =
              lastSketch.calculateRotationAngle(center, offset);

          Matrix4 rotationMatrix = Matrix4.identity();
          rotationMatrix.translate(center.dx, center.dy);
          rotationMatrix.rotateZ(rotationAngle);
          rotationMatrix.translate(-center.dx, -center.dy);

          Path newPath = rotatePath.value.transform(rotationMatrix.storage);

          Sketch updateSketch = Sketch.fromPath(lastSketch, newPath);

          allSketches.value = List.from(allSketches.value)..add(updateSketch);
        } else if (pointerMode.value == "scale") {
          print("handle resize");
        }
      },
      onPointerUp: (details) {
        if (pointerMode.value == "draw") {
          allSketches.value = List<Sketch>.from(allSketches.value)
            ..add(currentSketch.value!);
          currentSketch.value = null;
        } else if (pointerMode.value == "rotate") {
          rotatePath.value = Path();
        }
      },
      child: RepaintBoundary(
        child: SizedBox(
          height: height,
          width: width,
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
  bool displayTransformersControls;

  SketchPainter(
      {required this.sketches, this.displayTransformersControls = false});

  @override
  void paint(Canvas canvas, Size size) {
    for (Sketch sketch in sketches) {
      Path path = sketch.path;

      Paint paint = Paint()
        ..color = sketch.color
        ..strokeCap = StrokeCap.round;

      if (!sketch.filled) {
        paint.strokeWidth = sketch.size;
        paint.style = PaintingStyle.stroke;
      }

      List<PathMetric> pathMetrics = path.computeMetrics().toList();
      if (pathMetrics.isNotEmpty) {
        PathMetric pathMetric = pathMetrics.first;

        dynamic firstPointTangent = pathMetric.getTangentForOffset(0.0);
        Offset firstPoint = firstPointTangent.position;

        double pathLength = pathMetric.length;
        dynamic lastPointTangent = pathMetric.getTangentForOffset(pathLength);
        Offset lastPoint = lastPointTangent.position;

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

    if (displayTransformersControls && sketches.isNotEmpty) {
      Sketch sketch = sketches.last;

      Paint paint = Paint()
        ..color = Colors.black
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      List<Rect> buttons = sketch.calculateButtonPositions();

      canvas.drawRect(buttons[0], paint);
      canvas.drawRect(buttons[1], paint);
      canvas.drawRect(buttons[2], paint);
      canvas.drawRect(buttons[3], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
