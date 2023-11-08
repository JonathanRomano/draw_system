import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:draw_system/models/selection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:draw_system/models/drawing_mode.dart';
import 'package:draw_system/models/sketch.dart';
import 'package:draw_system/widgets/color_palette.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class CanvasSideBar extends HookWidget {
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

  const CanvasSideBar({
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
    required this.currentSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final undoRedoStack = useState(_UndoRedoStack(
      sketchesNotifier: allSketches,
      currentSketchNotifier: currentSketch,
    ));

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
          width: 100,
          child: Column(
            children: [
              const SizedBox(height: 30),
              SpeedDial(
                  direction: SpeedDialDirection.right,
                  backgroundColor: Colors.blue,
                  overlayOpacity: 0.4,
                  children: [
                    SpeedDialChild(
                      onTap: () {
                        drawingMode.value = DrawingMode.pencil;
                        closeMagicPen();
                      },
                      child: const Icon(
                        FontAwesomeIcons.pencil,
                      ),
                    ),
                    SpeedDialChild(
                      onTap: () {
                        drawingMode.value = DrawingMode.line;
                        closeMagicPen();
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              width: 22, height: 2, color: Colors.grey[900]),
                        ],
                      ),
                    ),
                    SpeedDialChild(
                        onTap: () {
                          drawingMode.value = DrawingMode.square;
                          closeMagicPen();
                        },
                        child: const Icon(
                          FontAwesomeIcons.square,
                        )),
                    SpeedDialChild(
                        onTap: () {
                          drawingMode.value = DrawingMode.circle;
                          closeMagicPen();
                        },
                        child: const Icon(
                          FontAwesomeIcons.circle,
                        )),
                    SpeedDialChild(
                        onTap: () => drawingMode.value = DrawingMode.magicPen,
                        child: const Icon(
                          FontAwesomeIcons.wandMagicSparkles,
                        )),
                  ],
                  child: () {
                    switch (drawingMode.value) {
                      case DrawingMode.eraser:
                        return const Icon(FontAwesomeIcons.eraser);
                      case DrawingMode.pencil:
                        return const Icon(FontAwesomeIcons.pencil);
                      case DrawingMode.line:
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: 22, height: 2, color: Colors.white),
                          ],
                        );
                      case DrawingMode.square:
                        return const Icon(FontAwesomeIcons.square);
                      case DrawingMode.circle:
                        return const Icon(FontAwesomeIcons.circle);
                      case DrawingMode.magicPen:
                        return const Icon(FontAwesomeIcons.wandMagicSparkles);

                      default:
                        return const Icon(FontAwesomeIcons.pencil);
                    }
                  }()),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: "fillShape",
                onPressed: () => filled.value = !filled.value,
                backgroundColor: filled.value ? Colors.blue : Colors.blue[200],
                child: const Icon(
                  Icons.format_paint,
                ),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: "addText",
                onPressed: () => showTextDialog(context),
                backgroundColor: Colors.blue,
                child: const Icon(
                  FontAwesomeIcons.t,
                ),
              ),
              const SizedBox(height: 10),
              ColorPalette(
                selectedColor: selectedColor,
              ),
              /* //! Stroke size!
              const SizedBox(height: 20),
              Row(
                children: [
                  Slider(
                    value: strokeSize.value,
                    min: 0,
                    max: 50,
                    onChanged: (val) {
                      strokeSize.value = val;
                    },
                  ),
                ],
              ),
              */
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: "undo",
                onPressed: allSketches.value.isNotEmpty
                    ? () => undoRedoStack.value.undo()
                    : null,
                child: const Icon(Icons.undo),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<bool>(
                valueListenable: undoRedoStack.value._canRedo,
                builder: (_, canRedo, __) {
                  return FloatingActionButton(
                    heroTag: "redo",
                    onPressed:
                        canRedo ? () => undoRedoStack.value.redo() : null,
                    child: const Icon(Icons.redo),
                  );
                },
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: "clear",
                onPressed: () => undoRedoStack.value.clear(),
                child: const Icon(Icons.clear),
              ),
            ],
          )),
    );
  }

  closeMagicPen() {
    allSketches.value = [...allSketches.value, ...selectedSketches.value];
    selectedSketches.value = [];
    currentSelection.value = null;
  }

  showTextDialog(BuildContext context) {
    final TextEditingController textController = TextEditingController();

    String insertedText = "";

    List<Color> colors = [
      ...Colors.primaries,
      Colors.black,
      Colors.white,
    ];

    showDialog(
        context: context,
        builder: (BuildContext context) {
          Color backgroundTextColor = Colors.white;

          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text("Insert text!"),
              content: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        labelText: 'Enter your text',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (text) {
                        insertedText = text;
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 2,
                      runSpacing: 2,
                      children: [
                        for (Color color in colors)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  backgroundTextColor = color;
                                });
                              },
                              child: Container(
                                height: 35,
                                width: 35,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                      color: backgroundTextColor == color
                                          ? Colors.blue
                                          : Colors.grey,
                                      width: 1.5),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(5)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Done"),
                  onPressed: () {
                    if (insertedText.trim().isNotEmpty) {
                      Sketch sketch =
                          Sketch.fromText(insertedText, backgroundTextColor);

                      allSketches.value = List.from(allSketches.value)
                        ..add(sketch);
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          });
        });
  }

  Future<ui.Image> get _getImage async {
    final completer = Completer<ui.Image>();
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (file != null) {
        final filePath = file.files.single.path;
        final bytes = filePath == null
            ? file.files.first.bytes
            : File(filePath).readAsBytesSync();
        if (bytes != null) {
          completer.complete(decodeImageFromList(bytes));
        } else {
          completer.completeError('No image selected');
        }
      }
    } else {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        completer.complete(
          decodeImageFromList(bytes),
        );
      } else {
        completer.completeError('No image selected');
      }
    }

    return completer.future;
  }

  Future<void> _launchUrl(String url) async {
    if (kIsWeb) {
      html.window.open(
        url,
        url,
      );
    } else {
      if (!await launchUrl(Uri.parse(url))) {
        throw 'Could not launch $url';
      }
    }
  }

  Future<Uint8List?> getBytes() async {
    RenderRepaintBoundary boundary = canvasGlobalKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }
}

class _IconBox extends StatelessWidget {
  final IconData? iconData;
  final Widget? child;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconBox({
    Key? key,
    this.iconData,
    this.child,
    this.tooltip,
    required this.selected,
    required this.onTap,
  })  : assert(child != null || iconData != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.grey[900]! : Colors.grey,
              width: 1.5,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Tooltip(
            message: tooltip,
            preferBelow: false,
            child: child ??
                Icon(
                  iconData,
                  color: selected ? Colors.grey[900] : Colors.grey,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}

///A data structure for undoing and redoing sketches.
class _UndoRedoStack {
  _UndoRedoStack({
    required this.sketchesNotifier,
    required this.currentSketchNotifier,
  }) {
    _sketchCount = sketchesNotifier.value.length;
    sketchesNotifier.addListener(_sketchesCountListener);
  }

  final ValueNotifier<List<Sketch>> sketchesNotifier;
  final ValueNotifier<Sketch?> currentSketchNotifier;

  ///Collection of sketches that can be redone.
  late final List<Sketch> _redoStack = [];

  ///Whether redo operation is possible.
  ValueNotifier<bool> get canRedo => _canRedo;
  late final ValueNotifier<bool> _canRedo = ValueNotifier(false);

  late int _sketchCount;

  void _sketchesCountListener() {
    if (sketchesNotifier.value.length > _sketchCount) {
      //if a new sketch is drawn,
      //history is invalidated so clear redo stack
      _redoStack.clear();
      _canRedo.value = false;
      _sketchCount = sketchesNotifier.value.length;
    }
  }

  void clear() {
    _sketchCount = 0;
    sketchesNotifier.value = [];
    _canRedo.value = false;
    currentSketchNotifier.value = null;
  }

  void undo() {
    final sketches = List<Sketch>.from(sketchesNotifier.value);
    if (sketches.isNotEmpty) {
      _sketchCount--;
      _redoStack.add(sketches.removeLast());
      sketchesNotifier.value = sketches;
      _canRedo.value = true;
      currentSketchNotifier.value = null;
    }
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final sketch = _redoStack.removeLast();
    _canRedo.value = _redoStack.isNotEmpty;
    _sketchCount++;
    sketchesNotifier.value = [...sketchesNotifier.value, sketch];
  }

  void dispose() {
    sketchesNotifier.removeListener(_sketchesCountListener);
  }
}
