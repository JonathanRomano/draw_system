import 'package:draw_system/models/projects.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RemoteService {
  var client = http.Client();

  Future<List<Project>> fetchProjects() async {
    final response = await client.get(
      Uri.parse('${dotenv.env["API_URL"]}/getAllActiveProjects'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonMap = json.decode(response.body);
      List<dynamic> projectsJson = jsonMap['projects'];
      List<Project> projects =
          projectsJson.map((json) => Project.fromJson(json)).toList();
      return projects;
    } else {
      throw Exception('Failed to fetch projects');
    }
  }

  Future<Project> fetchProjectById(int id) async {
    final response = await client.get(
      Uri.parse('${dotenv.env["API_URL"]}/fetchProjectDataById/$id'),
    );

    if (response.statusCode == 200) {
      Project project = Project.fromJson(json.decode(response.body));

      return project;
    } else {
      throw Exception('Failed to fetch project data');
    }
  }

  Future<List<Instruction>> fetchProjectInstructionsById(int id) async {
    final response = await client.get(
      Uri.parse('${dotenv.env["API_URL"]}/getSources/$id'),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      List<Instruction> instructions =
          jsonList.map((json) => Instruction.fromJson(json)).toList();

      return instructions;
    } else {
      throw Exception('Failed to fetch project data');
    }
  }
}
