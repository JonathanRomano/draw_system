import 'package:flutter/material.dart';

import 'package:draw_system/widgets/drawing_canvas.dart';
import 'package:draw_system/models/drawing_mode.dart';
import 'package:draw_system/models/sketch.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:draw_system/widgets/canvas_side_bar.dart';

import 'dart:io';

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

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      initialValue: 1,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit your source Image"),
        actions: [
          IconButton(
            onPressed: () {
              if (animationController.value == 0) {
                animationController.forward();
              } else {
                animationController.reverse();
              }
            },
            icon: const Icon(Icons.menu),
          ),
        ],
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
                sideBarController: animationController,
                currentSketch: currentSketch,
                allSketches: allSketches,
                canvasGlobalKey: canvasGlobalKey,
                filled: filled,
                imagePath: imagePath,
              ),
            ),
          ),
          Positioned(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(animationController),
              child: CanvasSideBar(
                drawingMode: drawingMode,
                selectedColor: selectedColor,
                strokeSize: strokeSize,
                eraserSize: eraserSize,
                currentSketch: currentSketch,
                allSketches: allSketches,
                canvasGlobalKey: canvasGlobalKey,
                filled: filled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
