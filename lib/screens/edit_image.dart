import "package:flutter/material.dart";
import 'dart:io';

class EditImage extends StatelessWidget {
  final String imagePath;

  const EditImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Edit Image")),
        body: Center(
          child: Image.file(File(imagePath)),
        ));
  }
}
