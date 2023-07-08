import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/project.dart';

class StorageService {
  static late final SharedPreferences instance;
  static final String interested_projects = "interested_projects";
  static final String interested_projects_ids = "interested_projects_ids";

  static Future<SharedPreferences> init() async {
    instance = await SharedPreferences.getInstance();
    return instance;
  }

  static saveMap(String key, Map<String, dynamic> map) {
    instance.setString(key, json.encode(map));
  }

  static getMap(String key) {
    String? mapString = instance.getString(key);
    if (mapString == null) {
      return null;
    }
    return json.decode(mapString);
  }

  static getPseudoMac() {
    String pseudoMac = instance.getString("pseudoMac") ?? "";
    if (pseudoMac == "") {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      String currentTimeString = currentTime.toString();
      int last3Digits =
          int.parse(currentTimeString.substring(currentTimeString.length - 3));
      int last6Digits =
          int.parse(currentTimeString.substring(currentTimeString.length - 6));
      var randomInt = Random().nextInt(999999);
      var hash = ((currentTime % last3Digits + randomInt * randomInt) *
              last6Digits *
              randomInt)
          .toString();
      var hash2 =
          ((currentTime % last6Digits + randomInt) * last6Digits).toString();
      var newHash = hash + hash2;
      newHash = newHash.trim();
      var shuffledHash = newHash.split('').toList()..shuffle();
      shuffledHash = shuffledHash
          .map((e) =>
              ((int.tryParse(e, radix: 12) ?? 4) * randomInt % last6Digits)
                  .toString())
          .toList();
      List<String> shuffledChars = [];
      shuffledHash.forEach((element) {
        int number = int.tryParse(element) ?? 0;
        if ((number % 17) > 10) {
          String letter = String.fromCharCode((int.parse(element) % 26) + 97);
          if (number % 2 == 0) {
            letter = letter.toUpperCase();
          }
          shuffledChars.add(letter);
        } else {
          shuffledChars.add(element);
        }
      });
      shuffledChars = shuffledChars.toList()..shuffle();
      String newPseudoMac = shuffledChars.join("");
      int cutoff = newPseudoMac.length > 12 ? 12 : newPseudoMac.length;
      List<String> newPseudoMacList = newPseudoMac.split('');
      newPseudoMacList.shuffle();
      newPseudoMac = newPseudoMacList.join("");
      newPseudoMac = newPseudoMac.substring(0, cutoff);
      pseudoMac = newPseudoMac;
      instance.setString("pseudoMac", pseudoMac);
    }
    return pseudoMac;
  }

  static saveInterestedProjectsIds(List<int> ids) {
    setString(interested_projects_ids, ids.join(","));
  }

  static List<int> getInterestedProjectsIds() {
    String? interestedProjectsIdsEncoded = getString(interested_projects_ids);
    if (interestedProjectsIdsEncoded == null || interestedProjectsIdsEncoded == "") {
      return [];
    }
    return interestedProjectsIdsEncoded
        .split(",")
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
  }

  static List<Project> getInterestedProjectsByIds() {
    List<int> projectIds = getInterestedProjectsIds();
    List<Project> projectsToReturn = [];
    for (var projectId in projectIds) {
      if (Project.projectCache.any((element) => element.id == projectId)) {
        Project project = Project.projectCache
            .firstWhere((element) => element.id == projectId);
        project.interested = true;
        projectsToReturn.add(project);
      }
    }
    return projectsToReturn;
  }

  static removeFromInterestedProjectsById(int id) {
    List<int> ids = getInterestedProjectsIds();
    ids.removeWhere((element) => element == id);
    saveInterestedProjectsIds(ids);
  }

  static interestsContainsId(int id) {
    List<int> projectIds = getInterestedProjectsIds();
    return projectIds.contains(id);
  }

  static List<Project> getInterestedProjects() {
    return getInterestedProjectsByIds();
  }

  static void saveInterestedProjects(List<Project> projects) {
    projects.removeWhere((element) => element.id == null);
    List<int> ids = [];
    for (var project in projects) {
      project.interested = true;
      ids.add(project.id!);
    }
    saveInterestedProjectsIds(ids);
  }

  static addInterestedProjectById(int id) {
    List<int> currentlySaved = getInterestedProjectsIds();
    if (!currentlySaved.any((element) => element == id)) {
      currentlySaved.add(id);
      saveInterestedProjectsIds(currentlySaved);
    }
  }

  static void addInterestedProject(Project project) {
    if (project.id == null) {
      return;
    }
    project.interested = true;
    addInterestedProjectById(project.id!);
  }

  static bool interestsContainId(int id) {
    return getInterestedProjectsIds().contains(id);
  }

  static bool interestsContainProject(Project project) {
    if (project.interested == null) {
      if (project.id == null) {
        return false;
      }
      return interestsContainId(project.id!);
    }
    return project.interested == true;
  }

  static void removeProjectFromInterested(Project project) {
    List<Project> currentlySaved = getInterestedProjects();
    currentlySaved.removeWhere((element) => element.id == project.id);
    project.interested = false;
    saveInterestedProjects(currentlySaved);
  }

  static void setString(String key, String value) {
    instance.setString(key, value);
  }

  static String? getString(String key) {
    return instance.getString(key);
  }

  static List<Project> getVisitedProjects() {
    return getVisitedProjectsByIds();
  }

  static saveVisitedProjectsIds(List<int> ids) {
    setString("visited_projects_ids", ids.join(","));
  }

  static List<int> getVisitedProjectsIds() {
    String? visitedProjectsIdsEncoded = getString("visited_projects_ids");
    if (visitedProjectsIdsEncoded == null || visitedProjectsIdsEncoded == "") {
      return [];
    }
    return visitedProjectsIdsEncoded
        .split(",")
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
  }

  static List<Project> getVisitedProjectsByIds() {
    List<int> projectIds = getVisitedProjectsIds();
    List<Project> projectsToReturn = [];
    for (var projectId in projectIds) {
      if (Project.projectCache.any((element) => element.id == projectId)) {
        Project project = Project.projectCache
            .firstWhere((element) => element.id == projectId);
        project.visited = true;
        projectsToReturn.add(project);
      }
    }
    return projectsToReturn;
  }

  static removeFromVisitedProjectsById(int id) {
    List<int> ids = getVisitedProjectsIds();
    ids.removeWhere((element) => element == id);
    saveVisitedProjectsIds(ids);
  }

  static visitsContainsId(int id) {
    List<int> projectIds = getVisitedProjectsIds();
    return projectIds.contains(id);
  }

  static saveVisitedProjects(List<Project> projects) {
    projects.removeWhere((element) => element.id == null);
    List<int> ids = [];
    for (var project in projects) {
      project.visited = true;
      ids.add(project.id!);
    }
    saveVisitedProjectsIds(ids);
  }

  static removeFromVisitedProjects(Project project) {
    List<Project> currentlySaved = getVisitedProjects();
    currentlySaved.removeWhere((element) => element.id == project.id);
    project.visited = false;
    saveVisitedProjects(currentlySaved);
  }

  static addVisitedProjectById(int id) {
    List<int> currentlySaved = getVisitedProjectsIds();
    if (!currentlySaved.any((element) => element == id)) {
      currentlySaved.add(id);
      saveVisitedProjectsIds(currentlySaved);
    }
  }

  static addVisitedProject(Project project) {
    if (project.id == null) {
      return;
    }
    project.visited = true;
    addVisitedProjectById(project.id!);
  }

  static bool projectWasVisited(Project project) {
    if (project.visited == null) {
      if (project.id == null) {
        return false;
      }
      return visitsContainsId(project.id!);
    }
    return project.visited == true;
  }
}
