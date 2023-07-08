import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:tradeshow_guidance_app/models/network_device.dart';

import '../models/received_beacon_data.dart';

class NetworkDeviceService {
  static final NetworkDeviceService _networkDevicePulseService =
      NetworkDeviceService();

  // 6 seconds
  int LAST_SEEN_THRESHOLD_IN_MICROSECONDS = 6 * 1000 * 1000;
  List<ReceivedBeaconData> nearbyBeacons = [];

  updateNearbyBeacons(ReceivedBeaconData newBeacon) {
    List<ReceivedBeaconData> newBeacons = [];
    for (var beacon in nearbyBeacons) {
      int timeNow = DateTime.now().microsecondsSinceEpoch;
      if ((timeNow - beacon.lastSighting!) <=
          LAST_SEEN_THRESHOLD_IN_MICROSECONDS) {
        newBeacons.add(beacon);
      }
    }
    if (!newBeacons.contains(newBeacon)) {
      newBeacons.add(newBeacon);
    } else {
      newBeacons[newBeacons.indexOf(newBeacon)].lastSighting =
          DateTime.now().microsecondsSinceEpoch;
    }
    nearbyBeacons = newBeacons;
  }

  NetworkDeviceService();

  static getService() {
    return _networkDevicePulseService;
  }

  final StreamController<String> beaconEventsController =
      StreamController<String>.broadcast();

  Future<List<ReceivedBeaconData>> huntBeacons() async {
    return this.nearbyBeacons;
  }

  bool inBackground = false;

  Future<void> initBeaconService(bool inBackground) async {
    this.inBackground = inBackground;
    if (Platform.isAndroid) {
      await BeaconsPlugin.setDisclosureDialogMessage(
          title: "Background Locations",
          message:
              "[This app] collects location data to enable [feature], [feature], & [feature] even when the app is closed or not in use");
    }

    if (Platform.isAndroid) {
      await BeaconsPlugin.setDisclosureDialogMessage(
          title: "Need Location Permission",
          message: "This app collects location data to work with beacons.");

      BeaconsPlugin.channel.setMethodCallHandler((call) async {
        print("Method: ${call.method}");
        if (call.method == 'scannerReady') {
          await BeaconsPlugin.startMonitoring();
        }
      });
    } else if (Platform.isIOS) {
      await BeaconsPlugin.startMonitoring();
    }

    BeaconsPlugin.listenToBeacons(beaconEventsController);

    await BeaconsPlugin.addRegion(
        "BeaconType1", "909c3cf9-fc5c-4841-b695-380958a51a5a");
    await BeaconsPlugin.addRegion(
        "BeaconType2", "6a84c716-0f2a-1ce9-f210-6a63bd873dd9");

    BeaconsPlugin.addBeaconLayoutForAndroid(
        "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25");
    BeaconsPlugin.addBeaconLayoutForAndroid(
        "m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24");

    BeaconsPlugin.setForegroundScanPeriodForAndroid(
        foregroundScanPeriod: 1500, foregroundBetweenScanPeriod: 20);

    beaconEventsController.stream.listen(
        (data) async {
          if (data.isNotEmpty) {
            ReceivedBeaconData newBeacon = (await updateBeaconFound(data));
            newBeacon.lastSighting = DateTime.now().microsecondsSinceEpoch;
            updateNearbyBeacons(newBeacon);
          }
        },
        onDone: () {},
        onError: (error) {
          print("Error: $error");
        });


    await BeaconsPlugin.runInBackground(inBackground);
  }

  Future<void> stopBeaconService() async {
    await BeaconsPlugin.stopMonitoring();
  }

  Future<ReceivedBeaconData> updateBeaconFound(String data) async {
    ReceivedBeaconData newBeacon =
        ReceivedBeaconData.fromJson(json.decode(data));

    //newBeacon.updatedRelatedBeacon();

    return newBeacon;
  }

  Future<List<String>> huntNetworkDevices() async {
    try {
      List<ReceivedBeaconData> beaconPoints = await huntBeacons();
      int number = 0;
      List<String> networkDevices = [];

      beaconPoints.forEach((beacon) {
        Map<String, dynamic> newDeviceJson = {
          "devicename": beacon.name,
          "devicemac": beacon.macAddress,
          "id": ((number++) * -1).toString(),
          "isbluetooth": true,
          "distance": beacon.distance,
          "uuid": beacon.uuid,
          "major": beacon.major.toString(),
          "minor": beacon.minor.toString(),
        };
        NetworkDevice newDevice = NetworkDevice.fromJson(newDeviceJson);
        networkDevices.add(NetworkDevice.networkDeviceToJson(newDevice));
      });

      // NetworkDevice wifiExample = NetworkDevice(
      //     devicename: "Example Wifi",
      //     devicemac: "00:00:00:00:00:00",
      //     id: (number++).toString());
      // wifiExample.isbluetooth = false;
      // wifiExample.distance = "-1";
      // networkDevices.add(NetworkDevice.networkDeviceToJson(wifiExample));

      return networkDevices;
    } catch (e) {
      print(e);
      return [];
    }
  }

  double doubleInRange(Random source, num start, num end) =>
      source.nextDouble() * (end - start) + start;

  double getDistance(p1, p2) {
    return sqrt(pow((p1[0] - p2[0]), 2) + pow((p1[1] - p2[1]), 2));
  }
}

double calculateDistance(int rssi, int txPower) {
  double distance;

  if (rssi == 0) {
    return -1.0;
  }

  double ratio = rssi * 1.0 / txPower;

  if (ratio < 1.0) {
    distance = pow(ratio, 10).toDouble();
  } else {
    distance = (0.89976) * pow(ratio, 7.7095) + 0.111;
  }

  return distance;
}
