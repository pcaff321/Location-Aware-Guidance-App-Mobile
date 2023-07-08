import 'dart:convert';

import 'package:tradeshow_guidance_app/services/beaconInformationService.dart';

import 'access_point.dart';

class ReceivedBeaconData {
  static List<ReceivedBeaconData> cache = [];

  static List<ReceivedBeaconData> receivedBeaconDatasFromJson(String str) =>
      List<ReceivedBeaconData>.from(
          json.decode(str).map((x) => ReceivedBeaconData.fromJson(x)));

  static String receivedBeaconDataToJson(List<ReceivedBeaconData> data) =>
      json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

  ReceivedBeaconData({
    required this.name,
    required this.uuid,
    required this.macAddress,
    required this.major,
    required this.minor,
    required this.distance,
    required this.proximity,
    required this.scanTime,
    required this.rssi,
    required this.txPower,
  });

  updatedRelatedBeacon() async {
    relatedBeacon = await BeaconInformationService().getBeaconByUuid(uuid);
    name = relatedBeacon?.name ?? "Unknown Device Name";
  }

  String name;
  String uuid;
  String macAddress;
  String major;
  String minor;
  String distance;
  String proximity;
  String scanTime;
  String rssi;
  String txPower;

  AccessPoint? relatedAP;

  int? lastSighting = 0;
  AccessPoint? relatedBeacon;

  String? get identifier {
    return relatedBeacon!.identifier;
  }

  int? get locationX {
    return relatedBeacon!.locationX;
  }

  int? get locationY {
    return relatedBeacon!.locationY;
  }

  List<String> get venues {
    return relatedBeacon?.venues ?? ["Unknown"];
  }

  factory ReceivedBeaconData.fromJson(Map<String, dynamic> json) {
    try {
      if (json["macAddress"] != null &&
          cache.any((element) => element.macAddress == json["macAddress"])) {
        var cached = cache
            .firstWhere((element) => element.macAddress == json["macAddress"]);
        cached.lastSighting = DateTime.now().millisecondsSinceEpoch;
        cached.proximity = json["proximity"];
        cached.distance = json["distance"];
        cached.rssi = json["rssi"];
        cached.txPower = json["txPower"];
        cached.scanTime = json["scanTime"];
        cached.name = json["devicename"] ?? "Unknown Device Name";
        return cached;
      } else {
        String name = json["devicename"] ?? "Unknown Device Name";
        String uuid = json["uuid"] ?? "Unknown";
        String macAddress =
            json["devicemac"] ?? json["macAddress"] ?? "Unknown";
        String major = json["major"] ?? "Unknown";
        String minor = json["minor"] ?? "Unknown";
        String distance = json["distance"] ?? "Unknown";
        String proximity = json["proximity"] ?? "Unknown";
        String scanTime = json["scanTime"] ?? "Unknown";
        String rssi = json["rssi"] ?? "Unknown";
        String txPower = json["txPower"] ?? "Unknown";
        var receivedBeaconData = ReceivedBeaconData(
          name: name,
          uuid: uuid,
          macAddress: macAddress,
          major: major,
          minor: minor,
          distance: distance,
          proximity: proximity,
          scanTime: scanTime,
          rssi: rssi,
          txPower: txPower,
        );
        cache.add(receivedBeaconData);
        return receivedBeaconData;
      }
    } catch (e) {
      throw Exception("Error parsing beacon data: $e");
    }
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "devicename": name,
        "uuid": uuid,
        "devicemac": macAddress,
        "macAddress": macAddress,
        "major": major,
        "minor": minor,
        "distance": distance,
        "proximity": proximity,
        "scanTime": scanTime,
        "rssi": rssi,
        "txPower": txPower,
      };
}
