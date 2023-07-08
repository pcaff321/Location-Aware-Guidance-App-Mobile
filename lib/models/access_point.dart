import 'dart:convert';

import 'package:tradeshow_guidance_app/services/globals.dart';

List<AccessPoint> beaconFromJson(String str) => List<AccessPoint>.from(
    json.decode(str).map((x) => AccessPoint.fromJson(x)));

String beaconToJson(List<AccessPoint> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AccessPoint {
  static List<AccessPoint> cache = [];

  AccessPoint({
    required this.name,
    required this.uuids,
    this.identifier,
    required this.macAddress,
    this.locationX,
    this.locationY,
    required this.venues,
  });

  String name;
  List<String>? uuids;
  String? identifier;
  String macAddress;
  int? locationX;
  int? locationY;
  List<String> venues;
  int fakeId = Globals.getFakeId();
  String? networkDeviceId;
  String? siteMapId;

  factory AccessPoint.fromJson(Map<String, dynamic> json) {
    AccessPoint theAP = cache.firstWhere(
        (element) => element.macAddress == json["macAddress"],
        orElse: () =>
            AccessPoint(name: "", uuids: [], macAddress: "", venues: []));
    String? networkDeviceIdHere = json["networkDeviceId"];
    if (networkDeviceIdHere == null &&
        json["networkDevice"] != null &&
        json["networkDevice"]["id"] != null) {
      networkDeviceIdHere = json["networkDevice"]["id"];
    }
    String? siteMapIdHere = json["siteMapId"];
    if (networkDeviceIdHere != null &&
        theAP.networkDeviceId != networkDeviceIdHere && siteMapIdHere != null && theAP.siteMapId != siteMapIdHere) {
      theAP = AccessPoint(name: "", uuids: [], macAddress: "", venues: []);
    }
    if (networkDeviceIdHere != null) {
      theAP.networkDeviceId = networkDeviceIdHere;
    }
    if (siteMapIdHere != null) {
      theAP.siteMapId = siteMapIdHere;
    }
    if (json["name"] != null) {
      theAP.name = json["name"];
    }
    if (json["uuids"] != null) {
      theAP.uuids = List<String>.from(json["uuids"].map((x) => x));
    }
    if (json["identifier"] != null) {
      theAP.identifier = json["identifier"];
    }
    if (json["locationX"] != null) {
      theAP.locationX = json["locationX"];
    }
    if (json["locationY"] != null) {
      theAP.locationY = json["locationY"];
    }
    if (json["macAddress"] != null) {
      theAP.macAddress = json["macAddress"];
    }
    if (json["venues"] != null) {
      theAP.venues = List<String>.from(json["venues"].map((x) => x));
    }
    return theAP;
  }

  Map<String, dynamic> fakeTestData() {
    Map<String, dynamic> json = {};
    json["name"] = "Fake Beacon $fakeId";
    json["uuids"] = ["00000000-0000-0000-0000-000000000000"];
    json["identifier"] = "00000000-0000-0000-0000-000000000000";
    json["macAddress"] = "00:00:00:00:00:00";
    json["locationX"] = 0;
    json["locationY"] = 0;
    json["venues"] = ["Fake Venue $fakeId"];
    return json;
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "uuids": uuids == null ? [] : List<dynamic>.from(uuids!.map((x) => x)),
        "identifier": identifier,
        "macAddress": macAddress,
        "locationX": locationX,
        "locationY": locationY,
        "venues": List<dynamic>.from(venues.map((x) => x)),
        "networkDeviceId": networkDeviceId ?? fakeId.toString(),
        "siteMapId": siteMapId ?? fakeId.toString()
      };
}
