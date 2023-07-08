import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tradeshow_guidance_app/models/section.dart';
import 'package:tradeshow_guidance_app/services/globals.dart';

class Project {
  static List<Project> projectCache = [];

  List<Section> roomLocations = [];

  Image? _imageLoaded;

  get imageLoaded {
    if (_imageLoaded == null) {
      _imageLoaded = Image.memory(Globals.getMapImage(this.projectImage).bytes);
    }
    return _imageLoaded;
  }

  get backgroundImage {
    ImageProvider backgroundImg;
    if (this.projectImage.isNotEmpty) {
      backgroundImg = this.imageLoaded.image;
    } else {
      backgroundImg = Globals.noProjectImageProvider;
    }
    return backgroundImg;
  }

  bool get hasKnownLocation {
    return this.roomLocation != Project.UNKNOW_LOCATION;
  }

  static List<Project> projectsFromJson(String json) {
    var results = jsonDecode(json);
    List<Project> projects = [];
    for (var result in results) {
      projects.add(Project.parseObject(result));
    }
    return projects;
  }

  static String projectsToJson(List<Project> projects) {
    List<Map<String, dynamic>> results = [];
    for (var project in projects) {
      results.add(project.toJson());
    }
    return jsonEncode(results);
  }

  static Project parseObject(result) {
    Project newProject = projectCache.firstWhere(
        (project) => project.id == result['id'],
        orElse: () => Project(result['id']));
    if (result['projectName'] != null) {
      newProject.projectName = result['projectName'];
    }
    if (result['projectId'] != null) {
      newProject.projectId = result['projectId'].toString();
    }
    if (result['projectDescription'] != null) {
      newProject.projectDescription = result['projectDescription'];
    }
    if (result['projectImage'] != null) {
      newProject.projectImage = result['projectImage'];
    }
    if (result['projectOwner'] != null) {
      newProject.projectOwner = result['projectOwner'];
    }
    if (result['contactEmail'] != null) {
      newProject.contactEmail = result['contactEmail'];
    }
    if (result['supervisor'] != null) {
      newProject.supervisor = result['supervisor'];
    }
    if (result['tags'] != null) {
      if (result['tags'] is String) {
        newProject.tags = result['tags'];
      } else {
        newProject.tags = result['tags'].join(';');
      }
    }
    if (result['projectWebsite'] != null) {
      newProject.projectWebsite = result['projectWebsite'];
    }
    if (projectCache
            .firstWhere((project) => project.id == newProject.id,
                orElse: () => Project(0))
            .id ==
        0) {
      projectCache.add(newProject);
    }
    newProject.visited = result['visited'];
    newProject.interested = result['interested'];
    return newProject;
  }

  static String UNKNOW_LOCATION = "Unknown Location";

  int? id;
  String? projectId = "";
  String projectName = "";
  String _projectDescription = "";
  String projectImage = "";
  String projectOwner = "";
  String contentType = "image/png";
  String _contactEmail = "";
  String supervisor = "";
  String tags = "";
  String projectWebsite = "";
  int fakeId = Globals.getFakeId();
  String roomLocation = UNKNOW_LOCATION;
  bool? visited;
  bool? interested;

  Project(this.id);

  set projectDescription(String description) {
    _projectDescription = description;
  }

  String get projectDescription {
    if (_projectDescription == "") {
      return "No Description Provided";
    }
    String editedDescription = _projectDescription;
    return editedDescription;
  }

  set contactEmail(String email) {
    _contactEmail = email;
  }

  String get contactEmail {
    if (_contactEmail == "") {
      return "No Email Provided";
    }
    return _contactEmail;
  }

  String get src {
    return "data:" + contentType + ";base64," + projectImage;
  }

  get keywordsFromDescription {
    RegExp regExp = RegExp(r"^\*\*Keywords:\*\*.*", multiLine: true);
    String? keywords = regExp.firstMatch(_projectDescription)?.group(0);
    if (keywords == null) {
      return [];
    }
    keywords = keywords.replaceAll("**Keywords:**", "");
    keywords = keywords.replaceAll(";", "");
    keywords = keywords.replaceAll(",", "");
    keywords = keywords.replaceAll(" ", "");
    return keywords.split(";");
  }

  get technologiesFromDescription {
    RegExp regExp = RegExp(r"^\*\*Technologies:\*\*.*", multiLine: true);
    String? technologies = regExp.firstMatch(_projectDescription)?.group(0);
    if (technologies == null) {
      return [];
    }
    technologies = technologies.replaceAll("**Technologies:**", "");
    return technologies.split(",");

  }

  List<String>? _tagsAsList;

  get tagsAsList {
    if (_tagsAsList != null) {
      return _tagsAsList;
    }
    _tagsAsList = keywordsFromDescription;
    return _tagsAsList;
  }

  toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'projectName': projectName,
      'projectDescription': projectDescription,
      'projectImage': projectImage,
      'projectOwner': projectOwner,
      'contactEmail': contactEmail,
      'supervisor': supervisor,
      'tags': tags,
      'projectWebsite': projectWebsite,
    };
  }
}
