import 'dart:io';

import 'package:draw_system/models/selection.dart';
import "package:flutter/material.dart";
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:draw_system/models/drawing_mode.dart';
import 'package:draw_system/models/sketch.dart';
import 'dart:ui';
import 'dart:typed_data';

class DrawingCanvas extends HookWidget {
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<Selection?> currentSelection;
  final ValueNotifier<List<Sketch>> allSketches;
  final ValueNotifier<List<Sketch>> selectedSketches;
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
    required this.selectedSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.imagePath,
    required this.projectId,
    required this.imageKey,
    this.imageWidth,
    this.imageHeight,
    required this.pointerMode,
    required this.transformSketch,
    required this.currentSelection,
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
            sketches: [...allSketches.value, ...selectedSketches.value],
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
    ValueNotifier<String> magicPenMode = useState("select");
    ValueNotifier<Offset?> referencePoint = useState(null);

    return Listener(
      onPointerDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.globalToLocal(details.position);

        if (drawingMode.value != DrawingMode.magicPen) {
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
        } else if (drawingMode.value == DrawingMode.magicPen &&
            selectedSketches.value.isEmpty) {
          currentSelection.value = Selection.fromPoints([offset]);
          pointerMode.value = "magicPen";
        } else if (drawingMode.value == DrawingMode.magicPen &&
            selectedSketches.value.isNotEmpty) {
          if (currentSelection.value!.path.contains(offset)) {
            magicPenMode.value = "move";
            referencePoint.value =
                offset - currentSelection.value!.path.getBounds().center;
          } else {
            allSketches.value = List<Sketch>.from([
              ...allSketches.value,
              ...selectedSketches.value,
            ]);

            currentSelection.value = Selection.fromPoints([offset]);
            selectedSketches.value = [];
          }
        }
      },
      onPointerMove: (details) {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.globalToLocal(details.position);

        if (pointerMode.value == "draw" &&
            drawingMode.value == DrawingMode.pencil) {
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
        } else if (pointerMode.value == "draw" &&
            drawingMode.value == DrawingMode.line &&
            currentSketch.value != null) {
          Path path = Path();
          path.moveTo(currentSketch.value!.points.first.dx,
              currentSketch.value!.points.first.dy);
          path.lineTo(offset.dx, offset.dy);

          currentSketch.value = Sketch.fromPath(
              currentSketch.value!, path, currentSketch.value!.size);
        } else if (pointerMode.value == "draw" &&
            drawingMode.value == DrawingMode.square &&
            currentSketch.value != null) {
          Path path = Path();

          path.addRect(Rect.fromPoints(
              Offset(currentSketch.value!.points.first.dx,
                  currentSketch.value!.points.first.dy),
              Offset(offset.dx, offset.dy)));

          currentSketch.value = Sketch.fromPath(
              currentSketch.value!, path, currentSketch.value!.size);
        } else if (pointerMode.value == "draw" &&
            drawingMode.value == DrawingMode.circle &&
            currentSketch.value != null) {
          Path path = Path();

          path.addOval(Rect.fromPoints(
              Offset(currentSketch.value!.points.first.dx,
                  currentSketch.value!.points.first.dy),
              Offset(offset.dx, offset.dy)));

          currentSketch.value = Sketch.fromPath(
              currentSketch.value!, path, currentSketch.value!.size);
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
        } else if (pointerMode.value == "magicPen" &&
            currentSelection.value != null &&
            selectedSketches.value.isEmpty) {
          final points = List<Offset>.from(currentSelection.value?.points ?? [])
            ..add(offset);

          currentSelection.value = Selection.fromPoints(points);
        } else if (pointerMode.value == "magicPen" &&
            currentSelection.value != null &&
            selectedSketches.value.isNotEmpty) {
          if (magicPenMode.value == "move") {
            Offset movementOffset = currentSelection.value!
                .calculateMove(offset, referencePoint.value!);

            List<Sketch> updatedSelectedIcons = [];
            for (Sketch sketch in selectedSketches.value) {
              updatedSelectedIcons.add(Sketch.fromPath(
                sketch,
                sketch.path.shift(movementOffset),
                sketch.size,
              ));
            }

            selectedSketches.value = updatedSelectedIcons;

            Path newPath = currentSelection.value!.path.shift(movementOffset);
            Selection updatedSelection = Selection(
                points: currentSelection.value!.points, path: newPath);

            currentSelection.value = updatedSelection;
          }
        }
      },
      onPointerUp: (details) {
        if (pointerMode.value == "draw") {
          allSketches.value = List<Sketch>.from(allSketches.value)
            ..add(currentSketch.value!);
          currentSketch.value = null;
        }
        if (pointerMode.value != "magicPen") {
          transformSketch.value = null;
          pointerMode.value = "draw";
        }
        if (pointerMode.value == "magicPen" && selectedSketches.value.isEmpty) {
          Path path = currentSelection.value!.path;
          path.close();

          currentSelection.value = Selection(
            points: currentSelection.value!.points,
            path: path,
          );

          selectedSketches.value = getSelectedSketches(allSketches, path);

          if (selectedSketches.value.isEmpty) {
            currentSelection.value = null;
          } else {
            allSketches.value.removeWhere(
                (sketch) => selectedSketches.value.contains(sketch));
          }
        }
      },
      child: RepaintBoundary(
        child: SizedBox(
          child: CustomPaint(
            painter: ControllersPainter(
              sketches: allSketches.value,
              displayTransformersControls:
                  allSketches.value.isNotEmpty && currentSketch.value == null,
              currentSelection: currentSelection,
              pointerMode: pointerMode,
              drawingMode: drawingMode.value,
            ),
          ),
        ),
      ),
    );
  }

  List<Sketch> getSelectedSketches(
    ValueNotifier<List<Sketch>> allSketches,
    Path selectionPath,
  ) {
    List<Sketch> selectedSketches = [];

    for (Sketch sketch in allSketches.value) {
      Path path = sketch.path;

      PathMetrics metrics = path.computeMetrics();

      for (PathMetric metric in metrics) {
        for (double i = 0; i < metric.length; i += 1) {
          Tangent? tangent = metric.getTangentForOffset(i);
          if (tangent != null) {
            if (selectionPath.contains(tangent.position)) {
              selectedSketches.add(sketch);
              break;
            }
          }
        }
      }
    }

    return selectedSketches;
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
          canvas.drawPath(path, paint);
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
  final ValueNotifier<Selection?> currentSelection;
  final ValueNotifier<String> pointerMode;
  final DrawingMode drawingMode;
  bool displayTransformersControls;

  ControllersPainter({
    required this.sketches,
    required this.currentSelection,
    required this.pointerMode,
    required this.drawingMode,
    this.displayTransformersControls = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentSelection.value != null && drawingMode == DrawingMode.magicPen) {
      Paint selectionPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(
        getDashedPath(currentSelection.value!.path),
        selectionPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

Path getDashedPath(Path originalPath,
    {double dashLength = 10, double dashSpace = 10}) {
  Path dashedPath = Path();
  PathMetrics metrics = originalPath.computeMetrics();

  for (var metric in metrics) {
    double distance = 0.0;
    while (distance < metric.length) {
      double length = dashLength;
      double remainingLength = metric.length - distance;
      if (length > remainingLength) {
        length = remainingLength;
      }
      dashedPath.addPath(
          metric.extractPath(distance, distance + length), Offset.zero);
      distance += length;

      if (distance < metric.length) {
        distance += dashSpace;
      }
    }
  }

  return dashedPath;
}
