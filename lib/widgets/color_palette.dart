import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ColorPalette extends HookWidget {
  final ValueNotifier<Color> selectedColor;

  const ColorPalette({
    Key? key,
    required this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showColorWheel(context, selectedColor);
      },
      backgroundColor: selectedColor.value,
    );
  }

  showColorWheel(BuildContext context, ValueNotifier<Color> color) {
    List<Color> colors = [
      ...Colors.primaries,
      Colors.black,
      Colors.white,
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: Column(children: [
              ColorPicker(
                pickerColor: color.value,
                onColorChanged: (value) {
                  color.value = value;
                },
              ),
              const SizedBox(
                height: 20,
              ),
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
                          selectedColor.value = color;
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 35,
                          width: 35,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                                color: selectedColor.value == color
                                    ? Colors.blue
                                    : Colors.grey,
                                width: 1.5),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
