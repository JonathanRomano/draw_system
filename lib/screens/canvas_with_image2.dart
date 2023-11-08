import 'package:draw_system/models/selection.dart';
import 'package:flutter/material.dart';

import 'package:draw_system/widgets/drawing_canvas.dart';
import 'package:draw_system/models/drawing_mode.dart';
import 'package:draw_system/models/sketch.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:draw_system/widgets/canvas_side_bar_new.dart';

class CanvasWithImage2 extends HookWidget {
  final String imagePath;

  const CanvasWithImage2({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final selectedColor = useState(Colors.black);
    final strokeSize = useState<double>(10);
    final eraserSize = useState<double>(30);
    final drawingMode = useState(DrawingMode.pencil);
    final filled = useState<bool>(false);

    final canvasGlobalKey = GlobalKey();

    ValueNotifier<Sketch?> currentSketch = useState(null);
    ValueNotifier<List<Sketch>> allSketches = useState([]);
    ValueNotifier<List<Sketch>> selectedSketches = useState([]);
    ValueNotifier<Selection?> currentSelection = useState(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit your source Image"),
      ),
      body: Stack(
        children: [
          Container(
            color: const Color.fromARGB(0, 101, 195, 216),
            width: double.maxFinite,
            height: double.maxFinite,
            child: Center(
              child: DrawingCanvas(
                drawingMode: drawingMode,
                selectedColor: selectedColor,
                strokeSize: strokeSize,
                eraserSize: eraserSize,
                currentSketch: currentSketch,
                allSketches: allSketches,
                canvasGlobalKey: canvasGlobalKey,
                filled: filled,
                imagePath: imagePath,
              ),
            ),
          ),
          Positioned(
            child: CanvasSideBar(
              drawingMode: drawingMode,
              selectedColor: selectedColor,
              strokeSize: strokeSize,
              eraserSize: eraserSize,
              currentSketch: currentSketch,
              allSketches: allSketches,
              canvasGlobalKey: canvasGlobalKey,
              filled: filled,
              selectedSketches: selectedSketches,
              currentSelection: currentSelection,
            ),
          ),
        ],
      ),
    );
  }
}
