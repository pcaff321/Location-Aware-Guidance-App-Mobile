import 'package:tradeshow_guidance_app/models/project.dart';
import 'package:tradeshow_guidance_app/models/site_map.dart';

class Section {
  static List<Section> cache = [];

  static processSections(List<Section> sectionsWithDuplicates) async {
    List<Section> sections = [];
    for (Section section in sectionsWithDuplicates) {
      if (!sections.contains(section)) {
        sections.add(section);
      }
    }
    List<Section> processedSections = [];
    for (Section section in sections) {
      processedSections.add(section);
      section.subsections = await getSubsections(section, sections);
    }
    return processedSections;
  }

  static getSubsections(Section section, List<Section> sections) async {
    List<Section> subsections = [];
    for (Section subsection in sections) {
      if (subsection.outerMap != null &&
          subsection.outerMap!.id == section.innerMap.id) {
        subsections.add(subsection);
      }
    }
    return subsections;
  }

  int id;
  String _sectionName = "";
  SiteMap? outerMap;
  SiteMap innerMap;
  int _topLeftX = 0;
  int _topLeftY = 0;
  int _bottomRightX = 0;
  int _bottomRightY = 0;
  List<Section> subsections = [];
  List<Project>? projects;

  set sectionName(String value) {
    if (value == "") {
      _sectionName = "Section $id [${innerMap.mapname}]";
    } else {
      _sectionName = value;
    }
  }

  String get sectionName {
    if (_sectionName == "") {
      return "${innerMap.mapname}";
    } else {
      return _sectionName;
    }
  }

  Section(
      {required this.id,
      required this.innerMap,
      required List<int> topLeft,
      required List<int> bottomRight}) {
    this.bottomRight = bottomRight;
    this.topLeft = topLeft;
  }

  toJson() => {
        "id": id,
        "sectionName": sectionName,
        "outerMap": outerMap == null ? null : outerMap!.toJson(),
        "innerMap": innerMap.toJson(),
        "topLeftX": topLeftX,
        "topLeftY": topLeftY,
        "bottomRightX": bottomRightX,
        "bottomRightY": bottomRightY,
        "subsections": List<dynamic>.from(subsections.map((x) => x.toJson())),
      };

  factory Section.fromJson(Map<String, dynamic> json) {
    Section theSection = cache.firstWhere((section) => section.id == json['id'],
        orElse: () => Section(
            id: json["id"],
            innerMap: SiteMap.fromJson(json["innerMap"]),
            topLeft: [json["topLeftX"], json["topLeftY"]],
            bottomRight: [json["bottomRightX"], json["bottomRightY"]]));
    theSection.topLeft = [json['topLeftX'], json['topLeftY']];
    theSection.bottomRight = [json['bottomRightX'], json['bottomRightY']];
    if (json['innerMap'] != null) {
      theSection.innerMap = SiteMap.fromJson(json['innerMap']);
    }
    if (json['outerMap'] != null) {
      theSection.outerMap = SiteMap.fromJson(json['outerMap']);
    }
    if (json['subsections'] != null) {
      for (var subsection in json['subsections']) {
        theSection.subsections.add(Section.fromJson(subsection));
      }
    }
     if (json['sectionName'] != null) {
            theSection.sectionName = json['sectionName'];
        }
    if (!cache.contains(theSection)) {
      cache.add(theSection);
    }

    return theSection;
  }

  int get topLeftX => _topLeftX;

  set topLeftX(int value) {
    int newValue = value.round();
    if (newValue > bottomRightX) {
      return;
    }
    _topLeftX = value.round();
  }

  int get topLeftY => _topLeftY;

  set topLeftY(int value) {
    int newValue = value.round();
    if (newValue > bottomRightY) {
      return;
    }
    _topLeftY = value.round();
  }

  int get bottomRightX => _bottomRightX;

  set bottomRightX(int value) {
    int newValue = value.round();
    if (newValue < topLeftX) {
      return;
    }
    _bottomRightX = value.round();
  }

  int get bottomRightY => _bottomRightY;

  set bottomRightY(int value) {
    int newValue = value.round();
    if (newValue < topLeftY) {
      return;
    }
    _bottomRightY = value.round();
  }

  set bottomRight(List<int> value) {
    bottomRightX = value[0];
    bottomRightY = value[1];
  }

  set topLeft(List<int> value) {
    topLeftX = value[0];
    topLeftY = value[1];
  }

  List<Project> getAllProjectsWithinSection() {
    List<Project> allProjects = [];
    for (var subsection in subsections) {
      allProjects.addAll(subsection.getAllProjectsWithinSection());
    }
    allProjects.addAll(this.projects?.toList() ?? []);
    allProjects = allProjects.toSet().toList();
    return allProjects;
  }

  bool containsPoint(int x, int y) {
    if (x >= topLeftX &&
        x <= bottomRightX &&
        y >= topLeftY &&
        y <= bottomRightY) {
      return true;
    }
    return false;
  }

  List<Section> getAllSubsections() {
    List<Section> allSubsections = [];
    for (var subsection in subsections) {
      allSubsections.add(subsection);
      allSubsections.addAll(subsection.getAllSubsections());
    }
    return allSubsections;
  }

  containsProject(Project project) {
    if (projects?.contains(project) ?? false) {
      return true;
    }
    for (var subsection in subsections) {
      if (subsection.containsProject(project)) {
        return true;
      }
    }
    return false;
  }

  static findParentSection(Section? currentSection) {
    if (currentSection == null) {
      return null;
    }
    if (currentSection.outerMap == null) {
      return currentSection;
    }
    for (var section in cache) {
      if (section.innerMap.id == currentSection.outerMap!.id) {
        return section;
      }
    }
    return null;
  }

  bool containsSection(Section section) {
    if (section.id == this.id) {
      return true;
    }
    for (var subsection in subsections) {
      if (subsection.containsSection(section)) {
        return true;
      }
    }
    return false;
  }
}
