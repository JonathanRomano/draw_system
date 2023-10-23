import 'package:draw_system/screens/canvas_with_image_and_project.dart';
import 'package:draw_system/services/remove_service.dart';
import 'package:flutter/material.dart';
import 'package:draw_system/models/projects.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ProjectView extends StatefulWidget {
  final int projectId;
  const ProjectView({required this.projectId, super.key});

  @override
  State<ProjectView> createState() => _ProjectViewState();
}

class _ProjectViewState extends State<ProjectView> {
  Project? project;
  List<Instruction>? instructions;
  var isLoaded = false;

  @override
  void initState() {
    super.initState();

    fetchData();
  }

  fetchData() async {
    project = await RemoteService().fetchProjectById(widget.projectId);
    instructions =
        await RemoteService().fetchProjectInstructionsById(widget.projectId);

    if (project != null) {
      setState(() {
        isLoaded = true;
      });
    }
  }

  Future<void> _downloadFile(String url) async {
    var response = await http.get(Uri.parse(url));

    print(url);

    if (response.statusCode == 200) {
      var directory = await getTemporaryDirectory();
      File file = File('${directory.path}/image.jpg');
      await file.writeAsBytes(response.bodyBytes);

      await ImageGallerySaver.saveFile(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved'),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download image'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Info'),
      ),
      body: Visibility(
        visible: isLoaded,
        replacement: const Center(child: CircularProgressIndicator()),
        child: ProjectCard(
          project: project,
          fetchData: fetchData,
          instructions: instructions,
          downloadFile: _downloadFile,
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project? project;
  final dynamic fetchData;
  final List<Instruction>? instructions;
  final dynamic downloadFile;

  const ProjectCard({
    required this.project,
    required this.fetchData,
    this.instructions,
    this.downloadFile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: ListView(
        children: [
          Text(
            "Name: ${project!.name}",
            textScaleFactor: 2,
          ),
          Visibility(
            visible: project!.reference != "",
            child: Text(
              "Reference: ${project!.reference}",
              textScaleFactor: 2,
            ),
          ),
          Text(
            "id: ${project!.id}",
            textScaleFactor: 2,
          ),
          Center(
              child: instructions != null
                  ? DataTable(
                      columns: const <DataColumn>[
                          DataColumn(
                            label: Text(
                              'Source image',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Instructions',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      rows: instructions!.map((instruction) {
                        return DataRow(cells: <DataCell>[
                          DataCell(
                            GestureDetector(
                              onTap: () => downloadFile(
                                  '${dotenv.env["API_URL"]}/downloadSource?type=source&projectId=${project!.id}&filename=${instruction.sourceImageFileName}'),
                              child: Text(instruction.sourceImageFileName),
                            ),
                          ),
                          DataCell(
                            GestureDetector(
                              onTap: () => downloadFile(
                                '${dotenv.env["API_URL"]}/downloadSource?type=instructions&projectId=${project!.id}&filename=${instruction.instructionsImageFileName}',
                              ),
                              child:
                                  Text(instruction.instructionsImageFileName),
                            ),
                          ),
                        ]);
                      }).toList())
                  : const Text("--")),
          ElevatedButton(
            onPressed: () => _pickImage(ImageSource.gallery, context),
            child: const Text("Add source from gallery"),
          ),
          ElevatedButton(
            onPressed: () => _pickImage(ImageSource.camera, context),
            child: const Text("Add source from camera"),
          ),
        ],
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
          builder: (context) => CanvasWithImageAndProject(
            imagePath: returnedImage.path,
            projectId: project!.id,
          ),
        ),
      ).then((_) {
        fetchData();
      });
    }
  }
}
