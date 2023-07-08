import 'dart:convert';

import 'package:tradeshow_guidance_app/models/access_point.dart';

class NetworkDevice {
  static List<NetworkDevice> cache = [];

  static NetworkDevice? networkDeviceFromJson(String str) =>
      NetworkDevice.fromJson(json.decode(str));

  static List<NetworkDevice> networkDevicesFromJson(String str) =>
      List<NetworkDevice>.from(
          json.decode(str).map((x) => NetworkDevice.fromJson(x)));

  static String networkDeviceToJson(NetworkDevice? data) =>
      json.encode(data!.toJson());

  NetworkDevice(
      {required this.id, required devicename, required this.devicemac}) {
    this.devicename = devicename;
  }

  String id;
  String? _devicename;
  String devicemac;
  String? creator;
  String? uuid;
  List<String?>? deviceuuids;
  bool? ispublic;
  bool isbluetooth = false;
  String? distance;
  AccessPoint? relatedAP;
  String? major;
  String? minor;

  String get devicename {
    if (_devicename == null || _devicename == "") {
      return "Device $id";
    }
    return _devicename!;
  }

  set devicename(String? value) {
    if (value != null && value != "Unknown Device Name" && value != "") {
      _devicename = value;
    } else {
      _devicename = "Device $id";
    }
  }

  String? sectionId;

  factory NetworkDevice.fromJson(Map<String, dynamic> jsonVal) {
    Map<String, dynamic> json = {};
    jsonVal.forEach((key, value) {
      json[key.toLowerCase()] = value;
    });
    if (json["major"] == null) {
      json["major"] = "0";
    }
    String newDeviceId = json["id"].toString();
    String? sectionId = json["sectionid"];
    String? deviceName;
    if (json["devicemac"] != null &&
        cache.any((element) => element.devicemac == json["devicemac"])) {
      var deviceMacDevice =
          cache.firstWhere((element) => element.devicemac == json["devicemac"]);
      deviceName = deviceMacDevice.devicename;
    }
    if (deviceName == null &&
        json["devicename"] != null &&
        json["devicename"] != "Unknown Device Name" &&
        json["devicename"] != "" &&
        !json["devicename"].toString().startsWith("Device ")) {
      deviceName = json["devicename"];
    }
    if (json["devicemac"] != null &&
        cache.any((element) =>
            element.devicemac == json["devicemac"] &&
            (sectionId == null || element.sectionId == sectionId))) {
      var existingDevice = cache.firstWhere((element) =>
          element.devicemac == json["devicemac"] &&
          (sectionId == null || element.sectionId == sectionId));
      int newDeviceIdInt = int.tryParse(newDeviceId) ?? 0;
      if (newDeviceIdInt > 0) {
        existingDevice.id = newDeviceId;
      }
      if (deviceName != null) {
        existingDevice.devicename = deviceName;
      }
      existingDevice.sectionId = sectionId;
      existingDevice.devicemac = json["devicemac"];
      existingDevice.creator = json["creator"];
      if (json["uuid"] != null) existingDevice.uuid = json["uuid"];
      if (json["major"] != null) existingDevice.major = json["major"];
      if (json["minor"] != null) existingDevice.minor = json["minor"];
      existingDevice.deviceuuids = (json["deviceuuids"] == null ||
              json["deviceuuids"] is String ||
              json["deviceuuids"] is int)
          ? []
          : List<String?>.from(json["deviceuuids"]!.map((x) => x));
      existingDevice.ispublic = json["ispublic"];
      existingDevice.isbluetooth = json["isbluetooth"] ?? false;
      existingDevice.distance = json["distance"] ?? "-1";
      return existingDevice;
    } else {
      var newDevice = NetworkDevice(
          id: newDeviceId,
          devicename: json["devicename"] ?? "Device $newDeviceId",
          devicemac: json["devicemac"] ?? json["macaddress"] ?? "UNKNOWN");
      newDevice.sectionId = sectionId;
      newDevice.deviceuuids = (json["deviceuuids"] == null ||
              json["deviceuuids"] is String ||
              json["deviceuuids"] is int)
          ? []
          : List<String?>.from(json["deviceuuids"]!.map((x) => x));
      newDevice.ispublic = json["ispublic"] ?? false;
      newDevice.isbluetooth = json["isbluetooth"] ?? false;
      newDevice.creator = json["creator"] ?? "UNKNOWN";
      newDevice.distance = json["distance"] ?? "-1";
      newDevice.major = json["major"];
      newDevice.minor = json["minor"];
      newDevice.uuid = json["uuid"];
      newDevice.devicemac = json["devicemac"] ?? "";
      cache.add(newDevice);
      return newDevice;
    }
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "devicename": devicename,
        "devicemac": devicemac,
        "creator": creator,
        "uuid": uuid,
        "deviceuuids": deviceuuids == null
            ? []
            : List<dynamic>.from(deviceuuids!.map((x) => x)),
        "ispublic": ispublic,
        "isbluetooth": isbluetooth,
        "distance": distance,
        "deviceName": devicename,
        "deviceMAC": devicemac,
        "deviceUUIDs": deviceuuids == null ? "" : deviceuuids!.join(";"),
        "isPublic": ispublic,
        "isBluetooth": isbluetooth,
        "major": major,
        "minor": minor,
        "sectionId": sectionId,
      };

  get isOnServer {
    int? intId = int.tryParse(id);
    return intId != null && intId > 0;
  }

  getUuid() {
    if (uuid == null) {
      return "Unknown Uuid";
    }
    return uuid!;
  }

  getMajorMinor() {
    if (major == null || minor == null) {
      return "Unknown Major/Minor";
    }
    return "$major/$minor";
  }
}
