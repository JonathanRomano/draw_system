import 'package:draw_system/screens/canvas_with_image2.dart';
import 'package:draw_system/screens/projects_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:draw_system/screens/canvas_test.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home page"),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery, context),
                child: const Text("From Gallery"),
              ),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera, context),
                child: const Text("From Camera"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DrawingPage(),
                    ),
                  );
                },
                child: const Text('GO TO CANVAS TEST!'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProjectsView(),
                    ),
                  );
                },
                child: const Text('GO TO PROJECT LIST API TEST!'),
              ),
            ]),
      ),
    );
  }

  Future _pickImage(ImageSource imageSource, BuildContext context) async {
    final returnedImage = await ImagePicker().pickImage(source: imageSource);

    if (returnedImage == null) return;

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                CanvasWithImage2(imagePath: returnedImage.path)),
      );
    }
  }
}
