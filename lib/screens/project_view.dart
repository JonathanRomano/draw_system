import 'package:draw_system/services/remove_service.dart';
import 'package:flutter/material.dart';
import 'package:draw_system/models/projects.dart';

class ProjectView extends StatefulWidget {
  final int projectId;
  const ProjectView({required this.projectId, super.key});

  @override
  State<ProjectView> createState() => _ProjectViewState();
}

class _ProjectViewState extends State<ProjectView> {
  Project? project;
  var isLoaded = false;

  @override
  void initState() {
    super.initState();

    fetchData();
  }

  fetchData() async {
    project = await RemoteService().fetchProjectById(widget.projectId);
    if (project != null) {
      setState(() {
        isLoaded = true;
      });
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
        child: ProjectCard(project: project),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project? project;

  const ProjectCard({required this.project, super.key});

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
          ElevatedButton(onPressed: onPressed, child: Text("Add source"))
        ],
      ),
    );
  }
}
