import 'package:flutter/material.dart';

class Selection {
  final List<Offset> points;
  final Path path;

  const Selection({
    required this.points,
    required this.path,
  });

  factory Selection.fromPoints(List<Offset> points) {
    return Selection(path: calculatePath(points), points: points);
  }

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

  Offset calculateMove(Offset offset, Offset referencePoint) {
    Rect pathRect = path.getBounds();

    double centerX = pathRect.center.dx;
    double centerY = pathRect.center.dy;

    return Offset((offset.dx - centerX), (offset.dy - centerY)) -
        referencePoint;
  }
}
