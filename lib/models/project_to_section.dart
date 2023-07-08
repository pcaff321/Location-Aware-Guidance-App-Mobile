import 'package:tradeshow_guidance_app/models/section.dart';
import 'package:tradeshow_guidance_app/models/project.dart';
import 'package:tradeshow_guidance_app/services/globals.dart';

class ProjectToSection {
  static List<ProjectToSection> cache = [];

  String id;
  Project project;
  Section section;
  int? x;
  int? y;
  int fakeId = Globals.getFakeId();

  ProjectToSection(this.id, this.project, this.section, this.x, this.y) {
    if (this.id == '' || int.parse(this.id) < 1) {
      this.id = (this.fakeId * -1).toString();
    }
    if (ProjectToSection.cache
            .where((projectToSection) =>
                projectToSection.id == this.id ||
                projectToSection.fakeId == this.fakeId)
            .length ==
        0) {
      ProjectToSection.cache.add(this);
    }
  }

  static ProjectToSection parseObject(resultJson) {
    Map<String, dynamic> result = {};
    resultJson.forEach((key, value) {
      result[key.toLowerCase()] = value;
    });
    var project = Project.parseObject(result['project']);
    var section = Section.fromJson(result['section']);
    if (result['id'] == null ||
        result['id'] == '' ||
        int.parse(result['id'].toString()) < 1) {
      result['id'] = (Globals.getFakeId() * -1).toString();
    }
    ProjectToSection? newProjectToSection;
    if (ProjectToSection.cache.any((element) => element.id == result['id'])) {
      newProjectToSection = ProjectToSection.cache.firstWhere(
          (projectToSection) => projectToSection.id == result['id']);
    }
    else if (ProjectToSection.cache.any((element) =>
        element.section.id == section.id && element.project.id == project.id)) {
      newProjectToSection = ProjectToSection.cache
          .firstWhere((projectToSection) =>
              projectToSection.section.id == section.id &&
              projectToSection.project.id == project.id);
    }
    if (newProjectToSection == null) {
      newProjectToSection = new ProjectToSection(
          result['id'].toString(), project, section, result['x'] ?? 0, result['y'] ?? 0);
      if (newProjectToSection.id == '' ||
          int.parse(newProjectToSection.id) < 1) {
        newProjectToSection.id = (newProjectToSection.fakeId * -1).toString();
      }
      ProjectToSection.cache.add(newProjectToSection);
    } else {
      newProjectToSection.project = project;
      newProjectToSection.section = section;
      if (result['x'] != null &&
          result['x'] != 0 &&
          newProjectToSection.x != result['x']) {
        newProjectToSection.x = result['x'];
      }
      if (result['y'] != null &&
          result['y'] != 0 &&
          newProjectToSection.y != result['y']) {
        newProjectToSection.y = result['y'];
      }
    }
    return newProjectToSection;
  }
}
