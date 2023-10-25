import 'dart:io';

import "package:flutter/material.dart";
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:draw_system/models/drawing_mode.dart';
import 'package:draw_system/models/sketch.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'package:svg_path_parser/svg_path_parser.dart';

class DrawingCanvas extends HookWidget {
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<bool> filled;
  final String imagePath;
  final double? imageHeight;
  final double? imageWidth;
  final GlobalKey imageKey;
  final int projectId;
  final ValueNotifier<String> pointerMode;
  final ValueNotifier<Sketch?> transformSketch;

  const DrawingCanvas({
    Key? key,
    required this.selectedColor,
    required this.strokeSize,
    required this.eraserSize,
    required this.drawingMode,
    required this.currentSketch,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.imagePath,
    required this.projectId,
    required this.imageKey,
    this.imageWidth,
    this.imageHeight,
    required this.pointerMode,
    required this.transformSketch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: imageKey,
          child: Stack(
            children: [
              Image.file(
                File(imagePath),
              ),
              ClipRRect(
                child: SizedBox(
                  width: 782,
                  height: 586,
                  child: buildAllPaths(),
                ),
              ),
              ClipRRect(
                child: SizedBox(
                  width: 782,
                  height: 586,
                  child: buildCurrentPath(context, pointerMode),
                ),
              ),
            ],
          ),
        ),
        RepaintBoundary(
          child: Stack(
            children: [
              const SizedBox(
                width: 782,
                height: 586,
              ),
              ClipRRect(
                child: SizedBox(
                  width: 782,
                  height: 586,
                  child: buildControllers(context, pointerMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildAllPaths() {
    return RepaintBoundary(
      child: SizedBox(
        child: CustomPaint(
          painter: SketchPainter(
            sketches: allSketches.value,
          ),
        ),
      ),
    );
  }

  Widget buildCurrentPath(
    BuildContext context,
    ValueNotifier<String> pointerMode,
  ) {
    return RepaintBoundary(
      child: SizedBox(
        child: CustomPaint(
          painter: SketchPainter(
              sketches:
                  currentSketch.value == null ? [] : [currentSketch.value!]),
        ),
      ),
    );
  }

  Widget buildControllers(
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

        if (buttons.isNotEmpty &&
            buttons[1].contains(offset) &&
            allSketches.value.last.type != SketchType.text) {
          transformSketch.value = allSketches.value.last;
          pointerMode.value = "scale";
        } else if (buttons.isNotEmpty &&
            buttons[2].contains(offset) &&
            allSketches.value.last.type != SketchType.square &&
            allSketches.value.last.type != SketchType.circle &&
            allSketches.value.last.type != SketchType.text) {
          transformSketch.value = allSketches.value.last;
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
              size: strokeSize.value,
            ),
            drawingMode.value,
            filled.value,
          );
        } else if (pointerMode.value == "move") {
          Sketch lastSketch = allSketches.value.removeLast();
          Offset moveOffset = lastSketch.calculateMove(offset);

          Path translatedPath = lastSketch.path.shift(moveOffset);

          Sketch updateSketch =
              Sketch.fromPath(lastSketch, translatedPath, lastSketch.size);

          allSketches.value = List.from(allSketches.value)..add(updateSketch);
        } else if (pointerMode.value == "rotate") {
          Sketch lastSketch = allSketches.value.removeLast();

          Offset center = transformSketch.value!.path.getBounds().center;

          double rotationAngle =
              lastSketch.calculateRotationAngle(center, offset);

          Matrix4 rotationMatrix = Matrix4.identity();
          rotationMatrix.translate(center.dx, center.dy);
          rotationMatrix.rotateZ(rotationAngle);
          rotationMatrix.translate(-center.dx, -center.dy);

          Path newPath =
              transformSketch.value!.path.transform(rotationMatrix.storage);

          Sketch updateSketch =
              Sketch.fromPath(lastSketch, newPath, lastSketch.size);

          allSketches.value = List.from(allSketches.value)..add(updateSketch);
        } else if (pointerMode.value == "scale") {
          Sketch lastSketch = allSketches.value.removeLast();

          Offset center = transformSketch.value!.path.getBounds().center;

          double scaleFactor = lastSketch.calculateResize(center, offset);

          List<double> matrixValues = <double>[
            scaleFactor,
            0,
            0,
            0,
            0,
            scaleFactor,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
          ];

          Path newPath = transformSketch.value!.path
              .transform(Float64List.fromList(matrixValues));

          Offset newCenter = newPath.getBounds().center;

          newPath = newPath.shift(center - newCenter);

          double newStrokeSize = (transformSketch.value!.size * scaleFactor);

          Sketch updateSketch = Sketch.fromPath(
            lastSketch,
            newPath,
            newStrokeSize,
          );

          allSketches.value = List.from(allSketches.value)..add(updateSketch);
        }
      },
      onPointerUp: (details) {
        if (pointerMode.value == "draw") {
          allSketches.value = List<Sketch>.from(allSketches.value)
            ..add(currentSketch.value!);
          currentSketch.value = null;
        }

        transformSketch.value = null;
        pointerMode.value = "draw";
      },
      child: RepaintBoundary(
        child: SizedBox(
          child: CustomPaint(
            painter: ControllersPainter(
              sketches: allSketches.value,
              displayTransformersControls: allSketches.value.isNotEmpty &&
                  currentSketch.value == null &&
                  pointerMode.value == "draw",
            ),
          ),
        ),
      ),
    );
  }
}

class SketchPainter extends CustomPainter {
  final List<Sketch> sketches;

  SketchPainter({
    required this.sketches,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (Sketch sketch in sketches) {
      if (sketch.type != SketchType.text) {
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
      } else {
        TextStyle textStyle = const TextStyle(
          color: Colors.black,
          fontSize: 30,
        );

        final textSpan = TextSpan(
          text: sketch.text,
          style: textStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );

        final offset = sketch.path.getBounds().center -
            Offset(textPainter.width / 2, textPainter.height / 2);

        Rect backgroundRect = Rect.fromCenter(
          center: sketch.path.getBounds().center,
          width: textPainter.width * 1.2,
          height: textPainter.height * 1.2,
        );

        RRect roundedBackgroundRect =
            RRect.fromRectAndRadius(backgroundRect, const Radius.circular(10));

        Paint backgroundPaint = Paint()
          ..color = sketch.color
          ..style = PaintingStyle.fill;

        Paint borderPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawRRect(roundedBackgroundRect, backgroundPaint);
        canvas.drawRRect(roundedBackgroundRect, borderPaint);

        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

Path resizeIconPath(Path path, Rect buttonRect, double scaleFactor) {
  Rect rect = Rect.fromCenter(
    center: buttonRect.center,
    width: (buttonRect.width * scaleFactor),
    height: (buttonRect.height * scaleFactor),
  );

  double scaleX = rect.width / path.getBounds().width;
  double scaleY = rect.height / path.getBounds().height;

  Path resizedPath =
      path.transform(Matrix4.diagonal3Values(scaleX, scaleY, 1).storage);

  double offsetX = rect.left - resizedPath.getBounds().left;
  double offsetY = rect.top - resizedPath.getBounds().top;
  resizedPath = resizedPath.shift(Offset(offsetX, offsetY));

  return resizedPath;
}

class ControllersPainter extends CustomPainter {
  final List<Sketch> sketches;
  bool displayTransformersControls;

  ControllersPainter({
    required this.sketches,
    this.displayTransformersControls = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (displayTransformersControls && sketches.isNotEmpty) {
      Sketch sketch = sketches.last;

      List<Rect> buttons = sketch.calculateButtonPositions();

      Paint buttonPaint = Paint()
        ..color = Colors.white
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.fill;

      Paint shadowPaint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      Paint iconPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      Path resizeButtonIconPath =
          parseSvgPath("M15 3h6v6M14 10l6.1-6.1M9 21H3v-6M10 14l-6.1 6.1");
      resizeButtonIconPath =
          resizeIconPath(resizeButtonIconPath, buttons[1], .55);

      Path rotateButtonIconPath = parseSvgPath(
        "M941.728 137.152C941.728 122.304 932.576 109.152 919.456 103.424 905.728 97.728 889.728 100.576 879.456 111.424L805.152 185.152C724.576 109.152 615.456 64 502.88 64 261.152 64 64 261.152 64 502.88 64 744.576 261.152 941.728 502.88 941.728 633.728 941.728 757.152 884 840.576 783.424 846.304 776 846.304 765.152 839.456 758.88L761.152 680C757.152 676.576 752 674.88 746.88 674.88 741.728 675.424 736.576 677.728 733.728 681.728 677.728 754.304 593.728 795.424 502.88 795.424 341.728 795.424 210.304 664 210.304 502.88 210.304 341.728 341.728 210.304 502.88 210.304 577.728 210.304 648.576 238.88 702.304 288.576L623.456 367.424C612.576 377.728 609.728 393.728 615.456 406.88 621.152 420.576 634.304 429.728 649.152 429.728L905.152 429.728C925.152 429.728 941.728 413.152 941.728 393.152L941.728 137.152Z",
      );
      rotateButtonIconPath =
          resizeIconPath(rotateButtonIconPath, buttons[2], .65);

      Path moveButtonIconPath = parseSvgPath(
          "M5.2 9l-3 3 3 3M9 5.2l3-3 3 3M15 18.9l-3 3-3-3M18.9 9l3 3-3 3M3.3 12h17.4M12 3.2v17.6");
      moveButtonIconPath = resizeIconPath(moveButtonIconPath, buttons[3], .7);

      if (sketch.type != SketchType.text) {
        canvas.drawOval(buttons[1], buttonPaint);
        canvas.drawOval(buttons[1], shadowPaint);
        canvas.drawPath(resizeButtonIconPath, iconPaint);
      }

      if (sketch.type != SketchType.circle &&
          sketch.type != SketchType.square &&
          sketch.type != SketchType.text) {
        canvas.drawOval(buttons[2], buttonPaint);
        canvas.drawOval(buttons[2], shadowPaint);
        canvas.drawPath(rotateButtonIconPath, iconPaint);
      }

      canvas.drawOval(buttons[3], buttonPaint);
      canvas.drawOval(buttons[3], shadowPaint);
      canvas.drawPath(moveButtonIconPath, iconPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
