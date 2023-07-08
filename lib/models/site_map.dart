import 'dart:convert';
import 'dart:math';

import 'package:tradeshow_guidance_app/models/access_point.dart';
import 'package:tradeshow_guidance_app/models/edge.dart';
import 'package:tradeshow_guidance_app/models/vertex.dart';
import 'package:tradeshow_guidance_app/services/globals.dart';

class SiteMap {
  static List<SiteMap> cache = [];

  static SiteMap? siteMapFromJson(String str) =>
      SiteMap.fromJson(json.decode(str));

  static List<SiteMap> siteMapsFromJson(String str) =>
      List<SiteMap>.from(json.decode(str).map((x) => SiteMap.fromJson(x)));

  static String siteMapToJson(SiteMap? data) => json.encode(data!);

  SiteMap({
    required this.id,
    required this.mapname,
  });

  String id;
  String mapname;
  String? _mapimage;
  String? contenttype;
  int sizinglocation1x = 0;
  int sizinglocation1y = 0;
  int sizinglocation2x = 50;
  int sizinglocation2y = 50;
  double metresbetweenpoints = 0;
  List<AccessPoint> _accessPoints = [];
  int fakeId = Globals.getFakeId();
  List<Vertex> _vertices = [];
  List<Edge>? _edges;

  set accessPoints(List<AccessPoint> accessPoints) {
    if (this._accessPoints.isNotEmpty || accessPoints.isEmpty) {
      return;
    }
    this._accessPoints = accessPoints;
  }

  List<AccessPoint> get accessPoints {
    List<AccessPoint> accessPointsCopy = [];
    for (var accessPoint in this._accessPoints) {
      accessPointsCopy.add(accessPoint);
    }
    return accessPointsCopy;
  }

  set edges(List<Edge> edges) {
    if (this._edges != null || edges.isEmpty) {
      return;
    }
    this._edges = edges;
  }

  List<Edge> get edges {
    List<Edge> edgesCopy = [];
    for (var edge in this._edges ?? []) {
      edgesCopy.add(edge);
    }
    return edgesCopy;
  }

  set vertices(List<Vertex> vertices) {
    if (this._vertices.isNotEmpty) {
      return;
    }
    this._vertices = vertices;
  }

  List<Vertex> get vertices {
    return this._vertices;
  }

  get width => sizinglocation2x - sizinglocation1x;
  get height => sizinglocation2y - sizinglocation1y;

  factory SiteMap.fromJson(Map<String, dynamic> jsonReceived) {
    Map<String, dynamic> json = {};
    for (var key in jsonReceived.keys) {
      json[key.toLowerCase()] = jsonReceived[key];
    }
    String jsonid = json["id"] == null ? "0" : json["id"].toString();
    String mBetweenPointsString = (json["metresbetweenpoints"] ?? 1.0).toString();
    double mBetweenPoints = double.tryParse(mBetweenPointsString) ?? 1.0;
    if (cache.any((element) => element.id == jsonid)) {
      var existingMap = cache.firstWhere((element) => element.id == jsonid);
      existingMap.mapname = json["mapname"];
      existingMap.mapimage = json["mapimage"];
      existingMap.contenttype = json["contenttype"];
      existingMap.sizinglocation1x = json["sizinglocation1x"];
      existingMap.sizinglocation1y = json["sizinglocation1y"];
      existingMap.sizinglocation2x = json["sizinglocation2x"];
      existingMap.sizinglocation2y = json["sizinglocation2y"];
      existingMap.metresbetweenpoints = mBetweenPoints;
      existingMap.accessPoints = (json["accesspoints"] == null
          ? []
          : List<AccessPoint>.from(
                  json["accesspoints"].map((x) => AccessPoint.fromJson(x)))
              .toList());
      existingMap.vertices = (json["vertices"] == null
          ? []
          : List<Vertex>.from(
              json["vertices"].map((x) => Vertex.parseObject(x))).toList());
      existingMap.edges = (json["edges"] == null
          ? []
          : List<Edge>.from(json["edges"].map((x) => Edge.parseObject(x)))
              .toList());
      return existingMap;
    } else {
      var newMap = SiteMap(
        id: jsonid,
        mapname: json["mapname"],
      );
      newMap.mapimage = json["mapimage"];
      newMap.contenttype = json["contenttype"];
      newMap.sizinglocation1x = json["sizinglocation1x"];
      newMap.sizinglocation1y = json["sizinglocation1y"];
      newMap.sizinglocation2x = json["sizinglocation2x"];
      newMap.sizinglocation2y = json["sizinglocation2y"];
      newMap.metresbetweenpoints = mBetweenPoints;
      newMap.vertices = (json["vertices"] == null
          ? []
          : List<Vertex>.from(
              json["vertices"].map((x) => Vertex.parseObject(x))).toList());
      newMap.edges = (json["edges"] == null
          ? []
          : List<Edge>.from(json["edges"].map((x) => Edge.parseObject(x)))
              .toList());
      newMap.accessPoints = (json["accesspoints"] == null
          ? []
          : List<AccessPoint>.from(
                  json["accesspoints"].map((x) => AccessPoint.fromJson(x)))
              .toList());

      cache.add(newMap);
      return newMap;
    }
  }

  get src {
    return "data:${contenttype!};base64,${mapimage!}";
  }

  get lengthBetweenPoints {
    var xDiff = sizinglocation1x - sizinglocation2x;
    var yDiff = sizinglocation1y - sizinglocation2y;
    return sqrt(xDiff * xDiff + yDiff * yDiff);
  }

  double get metresPerPixel {
    if (metresbetweenpoints == 0 || lengthBetweenPoints == 0) {
      return 0.05;
    }
    return (metresbetweenpoints / lengthBetweenPoints) / 2.625;
  }

  String? get mapimage {
    if (_mapimage == null) {
      mapimage = "";
    }
    if (_mapimage!.length % 4 > 0) {
      _mapimage = _mapimage! + '_' * (4 - _mapimage!.length % 4);
    }
    return _mapimage;
  }

  set mapimage(String? value) {
    _mapimage = value;
  }

  toJson() {
    return {
      "id": id,
      "mapname": mapname,
      "mapimage": mapimage,
      "contenttype": contenttype,
      "sizinglocation1x": sizinglocation1x,
      "sizinglocation1y": sizinglocation1y,
      "sizinglocation2x": sizinglocation2x,
      "sizinglocation2y": sizinglocation2y,
      "metresbetweenpoints": metresbetweenpoints,
      "accesspoints": accessPoints.map((e) => e.toJson()).toList(),
      "vertices": vertices.map((e) => e.toJson()).toList(),
      "edges": (edges).map((e) => e.toJson()).toList(),
    };
  }
}
