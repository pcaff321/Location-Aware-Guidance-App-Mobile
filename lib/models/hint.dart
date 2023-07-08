import 'package:tradeshow_guidance_app/models/site_map.dart';
import 'package:tradeshow_guidance_app/services/globals.dart';

class Hint {
  static List<Hint> hintCache = [];

  int id;
  String? _name;
  String hintText;
  String? hintImage = '';
  String? contentType = 'image/png';
  int x;
  int y;
  SiteMap map;
  late int fakeId;

  Hint({
    required this.id,
    required this.hintText,
    required this.map,
    this.x = 0,
    this.y = 0,
  }) {
    if (id <= 0) {
      id = Globals.getFakeId() * -1;
    }
    if (!Hint.hintCache.contains(this)) {
      Hint.hintCache.add(this);
    }
    fakeId = Globals.getFakeId();
  }

  String get name {
    if (_name == null || _name == "") {
      return "Hint " + fakeId.toString();
    }
    return _name!;
  }

  set name(String value) {
    _name = value;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hintText': hintText,
      'hintImage': hintImage,
      'contentType': contentType,
      'x': x,
      'y': y,
      'map': map.toJson(),
      'mapId': map.id,
      'hintFakeId': fakeId,
      'mapFakeId': map.fakeId
    };
  }

  factory Hint.fromJson(Map<String, dynamic> jsonReceived) {
    Map<String, dynamic> json = {};
    for (var key in jsonReceived.keys) {
      json[key.toLowerCase()] = jsonReceived[key];
    }
    Hint? existingHint;
    if (hintCache.any((hint) => hint.id == json["id"])) {
      existingHint = hintCache.firstWhere((hint) => hint.id == json["id"]);
    }
    if (existingHint != null) {
      existingHint.map = SiteMap.fromJson(json["map"]);
      existingHint.name = json["name"];
      existingHint.hintImage = json["hintimage"];
      existingHint.contentType = json["contenttype"];
      existingHint.x = json["x"];
      existingHint.y = json["y"];
      return existingHint;
    } else {
      var newHint = Hint(
        id: json["id"],
        hintText: json["hinttext"],
        map: SiteMap.fromJson(json["map"]),
      );
      newHint.name = json["name"];
      newHint.hintImage = json["hintimage"];
      newHint.contentType = json["contenttype"];
      newHint.x = json["x"];
      newHint.y = json["y"];
      hintCache.add(newHint);
      return newHint;
    }
  }
}
