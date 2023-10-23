import 'package:flutter/material.dart';

import 'package:draw_system/widgets/drawing_canvas_with_project.dart';
import 'package:draw_system/models/drawing_mode.dart';
import 'package:draw_system/models/sketch.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:draw_system/widgets/canvas_side_bar_new.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CanvasWithImageAndProject extends HookWidget {
  final String imagePath;
  final int projectId;
  final imageKey = GlobalKey();

  CanvasWithImageAndProject(
      {super.key, required this.imagePath, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final selectedColor = useState(Colors.black);
    final strokeSize = useState<double>(3);
    final eraserSize = useState<double>(30);
    final drawingMode = useState(DrawingMode.pencil);
    final filled = useState<bool>(false);

    final canvasGlobalKey = GlobalKey();

    ValueNotifier<Sketch?> currentSketch = useState(null);
    ValueNotifier<List<Sketch>> allSketches = useState([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit your source Image"),
        actions: [
          ElevatedButton(
              onPressed: () => saveImage(context), child: Icon(Icons.upload)),
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
                currentSketch: currentSketch,
                allSketches: allSketches,
                canvasGlobalKey: canvasGlobalKey,
                filled: filled,
                imagePath: imagePath,
                projectId: projectId,
                imageKey: imageKey,
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
            ),
          ),
        ],
      ),
    );
  }

  Future saveImage(BuildContext context) async {
    final RenderRepaintBoundary boundary =
        imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary;

    final ui.Image image = await boundary.toImage();

    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    var uri = Uri.parse('${dotenv.env["API_URL"]}/saveSourceFile');

    var request = http.MultipartRequest('POST', uri)
      ..fields["projectId"] = projectId.toString()
      ..files.add(http.MultipartFile.fromBytes('image', pngBytes,
          filename: 'image.png'))
      ..files.add(await http.MultipartFile.fromPath("sourceImage", imagePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    } else {
      print('Failed to send image, status code: ${response.statusCode}');
    }
    return pngBytes;
  }
}
