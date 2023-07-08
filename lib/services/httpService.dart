import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tradeshow_guidance_app/models/access_point.dart';
import 'package:tradeshow_guidance_app/models/edge.dart';
import 'package:tradeshow_guidance_app/models/hint.dart';
import 'package:tradeshow_guidance_app/models/network_device.dart';
import 'package:tradeshow_guidance_app/models/project.dart';
import 'package:tradeshow_guidance_app/models/project_to_section.dart';
import 'package:tradeshow_guidance_app/models/section.dart';
import 'package:tradeshow_guidance_app/models/site.dart';
import 'package:tradeshow_guidance_app/models/site_map.dart';
import 'package:tradeshow_guidance_app/models/vertex.dart';
import 'package:tradeshow_guidance_app/services/activeService.dart';
import 'package:tradeshow_guidance_app/services/storageService.dart';

class HttpService {
  static final HttpService instance = HttpService._();
  static const String BASE_URL =
      "https://fypwebapi20230207105914.azurewebsites.net/";

  HttpService._();

  static getService() {
    return instance;
  }

  List<Site> sites = [];
  bool loadingSites = false;

  updateUsage(String pseudoMac, List<Map<String, dynamic>> features) async {
    String todaysDate = DateTime.now().toIso8601String().substring(0, 10);
    Map<String, dynamic> form = {
      "macAddress": todaysDate + " " + pseudoMac,
      "features": features,
    };
    if (!kDebugMode) {
      http.Response response =
          await submitForm(form, BASE_URL + 'featureusage/');
      return response;
    }
    return null;
  }

  Future<List<Site>> getSites() {
    String url = "sites/prod";
    if (kDebugMode) {
      url = "sites/";
    }
    if (sites.isNotEmpty) {
      return Future.value(sites);
    }
    return http.get(Uri.parse(BASE_URL + url)).then((response) {
      List<Site> sites = [];
      for (var site in jsonDecode(response.body)) {
        sites.add(Site.fromJson(site));
      }
      this.sites = sites;
      return sites;
    });
  }

  submitForm(dynamic form, String endpoint) async {
    String? adminPassword = StorageService.getString("adminpassword");
    if (adminPassword != null) {
      form["adminPassword"] = adminPassword;
    }
    http.Response response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(form),
    );

    return response;
  }



  getById(String id, String endpoint) async {
    http.Response response = await http.get(
      Uri.parse(endpoint + id),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    return response;
  }

  getSiteBySite(String siteId) async {
    http.Response response = await getById(siteId, BASE_URL + 'sites/');
    return Site.fromJson(jsonDecode(response.body));
  }

  Future<List<Project>> getProjects() async {
    List<Project> projects = [];
    http.Response response = await http.get(
      Uri.parse(BASE_URL + 'projects/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    var bodyAsJson = json.decode(response.body);
    for (var project in bodyAsJson) {
      projects.add(Project.parseObject(project));
    }
    return projects;
  }

  List<NetworkDevice> allNetworkDevices = [];

  Future<List<NetworkDevice>> getNetworkDevices() async {
    List<NetworkDevice> networkDevices = [];
    http.Response response = await http.get(
      Uri.parse(BASE_URL + 'networkdevices/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    var bodyAsJson = json.decode(response.body);
    for (var networkDevice in bodyAsJson) {
      networkDevices.add(NetworkDevice.fromJson(networkDevice));
    }
    allNetworkDevices = networkDevices;
    return networkDevices;
  }

  Future<List<Project>> getProjectsOfSite(String siteId) async {
    List<Project> projects = [];
    http.Response response = await http.get(
      Uri.parse(BASE_URL + 'projects/getBySiteId/' + siteId),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    var bodyAsJson = json.decode(response.body);
    for (var project in bodyAsJson) {
      projects.add(Project.parseObject(project));
    }
    return projects;
  }

  Future<List<Project>> getProjectsOfSection(Section section) async {
    if (section.projects != null) {
      return section.projects!;
    }
    if (section.id <= 0) {
      return [];
    }
    String sectionId = section.id.toString();
    List<Project> projects = [];
    http.Response response = await http.get(
      Uri.parse(BASE_URL + 'projects/getBySectionId/' + sectionId),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    var bodyAsJson = json.decode(response.body);
    for (var project in bodyAsJson) {
      projects.add(Project.parseObject(project));
    }
    return projects;
  }

  Future<List<Edge>> getEdgesOfSection(String sectionId) async {
    List<Edge> edges = [];
    http.Response response = await http.get(
      Uri.parse(BASE_URL + 'edges/getBySectionId/' + sectionId),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    var bodyAsJson = json.decode(response.body);
    for (var networkDevice in bodyAsJson) {
      edges.add(Edge.parseObject(networkDevice));
    }
    return edges;
  }

  Future<List<Vertex>> getVerticesOfSection(String sectionId) async {
    List<Vertex> vertices = [];
    http.Response response = await http.get(
      Uri.parse(BASE_URL + 'vertices/getBySectionId/' + sectionId),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    var bodyAsJson = json.decode(response.body);
    for (var vertex in bodyAsJson) {
      vertices.add(Vertex.parseObject(vertex));
    }
    return vertices;
  }

  Future<List<Section>> getSectionsOfSite(String siteId) async {
    List<Section> sections = [];
    http.Response response = await http.get(
      Uri.parse(BASE_URL + 'sections/getSectionsBySiteId/' + siteId),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    var bodyAsJson = json.decode(response.body);
    for (var section in bodyAsJson) {
      sections.add(Section.fromJson(section));
    }
    return sections;
  }

  Map<String, List<Hint>> hintsBySiteMapId = {};

  updateProjectLocations(List<Section> sections) {
    List<String> sectionIds = [];
    sections.forEach((section) {
      if (section.id == 0) {
        print("No section id for: " + section.sectionName);
      } else {
        sectionIds.add(section.id.toString());
      }
    });
    if (sectionIds.length == 0) {
      return;
    }
    Map<String, dynamic> data = {
      'sectionIds': sectionIds,
    };
    http
        .post(Uri.parse(BASE_URL + 'projectLocations/getAll'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(data))
        .then((response) {
      List<ProjectToSection> projectToSections = [];
      Map<String, List<ProjectToSection>> p2sDictionary = {};
      sections.forEach((section) {
        p2sDictionary[section.id.toString()] = [];
      });
      var bodyAsJson = json.decode(response.body);
      for (var p2s in bodyAsJson) {
        p2s["section"] =
            sections.firstWhere((s) => s.id == p2s["section"]["id"]).toJson();
        if (p2s["section"] == null) {
          return;
        }
        ProjectToSection projectToSectionObject =
            ProjectToSection.parseObject(p2s);
        projectToSections.add(projectToSectionObject);
        p2sDictionary[projectToSectionObject.section.id.toString()]!
            .add(projectToSectionObject);
      }
    });
  }

  updateHints() {
    // if (hintsBySiteMapId.isNotEmpty) {
    //   return;
    // }
    loadingHints = true;
    http.get(Uri.parse(BASE_URL + 'hints/')).then((response) {
      var bodyAsJson = json.decode(response.body);
      for (var hint in bodyAsJson) {
        if (hintsBySiteMapId.containsKey(hint['map']['id'].toString())) {
          hintsBySiteMapId[hint['map']['id'].toString()]!
              .add(Hint.fromJson(hint));
        } else {
          hintsBySiteMapId[hint['map']['id'].toString()] = [
            Hint.fromJson(hint)
          ];
        }
      }
      loadingHints = false;
      loadedHints = true;
    });
  }

  Map<String, List<String>> doorsBySectionId = {};
  Map<String, List<String>> exitsBySectionId = {};

  updateDoors() {
    if (doorsBySectionId.isNotEmpty) {
      return;
    }
    loadingDoors = true;
    http.get(Uri.parse(BASE_URL + 'doors/')).then((response) {
      var bodyAsJson = json.decode(response.body);
      for (var door in bodyAsJson) {
        Vertex vertex = Vertex.parseObject(door['vertex']);
        vertex.doorType = door['doorType'] ?? 3;
        if (!vertex.isExit) {
          if (doorsBySectionId.containsKey(door['section']['id'].toString())) {
            doorsBySectionId[door['section']['id'].toString()]!.add(vertex.id);
          } else {
            doorsBySectionId[door['section']['id'].toString()] = [vertex.id];
          }
        } else {
          if (exitsBySectionId.containsKey(door['section']['id'].toString())) {
            exitsBySectionId[door['section']['id'].toString()]!.add(vertex.id);
          } else {
            exitsBySectionId[door['section']['id'].toString()] = [vertex.id];
          }
        }
      }
      loadingDoors = false;
      loadedDoors = true;
    });
  }

  Map<String, List<NetworkDevice>> networkDevicesByMap = {};
  Map<String, List<SiteMap>> siteMapsByNetworkDevices = {};

  updateMapPoints(String sectionId) {
    //loadingMapPoints = true;
    http
        .get(Uri.parse(BASE_URL + 'mappoints/getBySectionId/' + sectionId))
        .then((response) {
      var bodyAsJson = json.decode(response.body);
      List<NetworkDevice> networkDevicesFromMPs = [];
      List<SiteMap> siteMapsFromMap = [];
      for (var mapPoint in bodyAsJson) {
        if ((mapPoint['networkDevice'] == null) || (mapPoint['map'] == null)) {
          continue;
        }
        mapPoint['networkDevice']['sectionId'] = sectionId;
        NetworkDevice networkDevice =
            NetworkDevice.fromJson(mapPoint['networkDevice']);
        SiteMap siteMap = SiteMap.fromJson(mapPoint['map']);
        int x = mapPoint['x'];
        int y = mapPoint['y'];
        Map<String, dynamic> jsonForAccessPoint = {};
        jsonForAccessPoint["name"] = networkDevice.devicename;
        jsonForAccessPoint["uuids"] = [];
        jsonForAccessPoint["identifier"] = networkDevice.devicemac;
        jsonForAccessPoint["macAddress"] = networkDevice.devicemac;
        jsonForAccessPoint["locationX"] = x;
        jsonForAccessPoint["locationY"] = y;
        jsonForAccessPoint["venues"] = [];
        jsonForAccessPoint["networkDeviceId"] = networkDevice.id;
        jsonForAccessPoint["siteMapId"] = sectionId;
        AccessPoint accessPoint = AccessPoint.fromJson(jsonForAccessPoint);
        networkDevice.relatedAP = accessPoint;
        networkDevicesFromMPs.add(networkDevice);
        siteMapsFromMap.add(siteMap);
        if (!networkDevicesByMap.containsKey(siteMap.id)) {
          networkDevicesByMap[siteMap.id] = [networkDevice];
        } else if (!networkDevicesByMap[siteMap.id]!.contains(networkDevice)) {
          networkDevicesByMap[siteMap.id]!.add(networkDevice);
        }
        if (!siteMapsByNetworkDevices.containsKey(networkDevice.id)) {
          siteMapsByNetworkDevices[networkDevice.id] = [siteMap];
        } else if (!siteMapsByNetworkDevices[networkDevice.id]!
            .contains(siteMap)) {
          siteMapsByNetworkDevices[networkDevice.id]!.add(siteMap);
        }
        //loadingMapPoints = false;
        //loadedMapPoints = true;
      }
    });
  }

  Site? lastLoadedSite;

  bool loadedNetworkDevices = false;
  bool loadedMapPoints = false;
  bool loadedDoors = false;
  bool loadedHints = false;

  bool loadingNetworkDevices = false;
  bool loadingMapPoints = false;
  bool loadingDoors = false;
  bool loadingHints = false;

  void setSite(Site site) async {
    if (lastLoadedSite != null && lastLoadedSite!.id == site.id) {
      return;
    }
    ActiveService activeService = ActiveService.getService();
    if (activeService.loadingSite) {
      return;
    }

    // getNetworkDevices();
    // updateMapPoints();
    // updateDoors();
    updateHints();

    activeService.setLoadingSite(true);

    // if (!loadedMapPoints && !loadingMapPoints) {
    //   updateMapPoints();
    // }

    if (!loadedDoors && !loadingDoors) {
      updateDoors();
    }

    // if (!loadedHints && !loadingHints) {
    //   updateHints();
    // }

    StorageService.instance.remove("showAccessPoints");
    StorageService.instance.remove("showVertices");
    StorageService.instance.remove("showUserLocation");
    StorageService.instance.remove("showSubSections");
    StorageService.instance.remove("showHints");
    StorageService.instance.remove("showRoutes");
    StorageService.instance.remove("targetProjectId");
    StorageService.instance.remove("targetSectionId");
    StorageService.instance.remove("destinationSetting");

    site = await getSiteBySite(site.id);

    activeService.updateActiveSite(site);
    //List<NetworkDevice> networkDevices = await getNetworkDevices();
    List<Section> sections = await getSectionsOfSite(site.id);
    List<Project> projects = await getProjectsOfSite(site.id);

    activeService.updateAvailableSections(sections);
    activeService.currentSection = site.startsection ?? sections[0];
    for (var section in sections) {
      List<Edge> edges = await getEdgesOfSection(section.id.toString());
      //List<Vertex> vertices = await getVerticesOfSection(section.id.toString());
      List<Vertex> vertices = [];
      for (var edge in edges) {
        if (!vertices.any((element) => element.id == edge.vertexA.id)) {
          vertices.add(edge.vertexA);
        }
        if (!vertices.any((element) => element.id == edge.vertexB.id)) {
          vertices.add(edge.vertexB);
        }
      }
      List<Project> sectionProjects = await getProjectsOfSection(section);
      updateMapPoints(section.id.toString());
      section.projects = sectionProjects;
      for (var project in sectionProjects) {
        if (!project.roomLocations.contains(section) ||
            (site.startsection != null &&
                !project.roomLocations.contains(site.startsection))) {
          project.roomLocations.add(section);
        }
        project.roomLocation = section.sectionName;
      }
      section.innerMap.vertices = vertices;
      section.innerMap.edges = edges;
      section.innerMap.accessPoints =
          (networkDevicesByMap[section.innerMap.id] ?? [])
              .map((e) => e.relatedAP!)
              .toList();
    }

    updateProjectLocations(sections);

    activeService.updateProjectList(projects);

    Section.processSections(sections);

    lastLoadedSite = site;
    activeService.setLoadingSite(false);
  }
}
