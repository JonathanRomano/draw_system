import 'package:draw_system/models/projects.dart';
import 'package:draw_system/screens/project_view.dart';
import 'package:draw_system/services/remove_service.dart';
import 'package:flutter/material.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({super.key});

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  List<Project>? projects;
  var isLoaded = false;

  @override
  void initState() {
    super.initState();

    fetchData();
  }

  fetchData() async {
    projects = await RemoteService().fetchProjects();
    if (projects != null) {
      setState(() {
        isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lista de projetos")),
      body: Visibility(
        visible: isLoaded,
        replacement: const Center(child: CircularProgressIndicator()),
        child: ListView.builder(
          itemCount: projects?.length,
          itemBuilder: (context, index) {
            return ProjectCard(
              project: projects![index],
            );
          },
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({required this.project, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProjectView(
                    projectId: project.id,
                  ))),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Name: ${project.name}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Reference: ${project.reference}'),
              const SizedBox(height: 8),
              Text('Status: ${project.status}'),
              const SizedBox(height: 8),
              Text('ID: ${project.id.toString()}'),
            ],
          ),
        ),
      ),
    );
  }
}
