import 'package:tradeshow_guidance_app/models/site_map.dart';

import 'access_point.dart';
import 'network_device.dart';

class MapPoint {
  static List<MapPoint> mapPointCache = [];

  static MapPoint parseObject(Map<String, dynamic> resultJson) {
    Map<String, dynamic> result = {};
    resultJson.forEach((key, value) {
      result[key.toLowerCase()] = value;
    });
    MapPoint? newMapPoint =
        mapPointCache.firstWhere((mapPoint) => mapPoint.id == result['id'],
            orElse: () => MapPoint(
                  result['id'],
                  NetworkDevice.fromJson(result['networkdevice']),
                  SiteMap.fromJson(result['map']),
                ));
    newMapPoint.networkDevice = NetworkDevice.fromJson(result['networkdevice']);
    newMapPoint.range = result['range'];
    newMapPoint.x = result['x'];
    newMapPoint.y = result['y'];
    mapPointCache.add(newMapPoint);
    return newMapPoint;
  }

  int? id;
  NetworkDevice? networkDevice;
  SiteMap? map;
  int? range;
  int? x;
  int? y;
  String? _name;

  set name(String? name) {
    _name = name;
  }

  String? get name {
    if (_name == null || _name == '') {
      String beaconType = networkDevice == null || networkDevice!.isbluetooth
          ? 'Bluetooth'
          : 'WiFi';
      return '${beaconType} ${this.id}';
    }
    return _name;
  }

  MapPoint(
    this.id,
    this.networkDevice,
    this.map,
  );

  AccessPoint get accessPoint {
    Map<String, dynamic> accessPointDataToParse = {
      'name': name,
      'macAddress': networkDevice?.devicemac,
      'locationX': x,
      'locationY': y,
      'range': range,
      'networkDeviceId': networkDevice?.id
    };
    return AccessPoint.fromJson(accessPointDataToParse);
  }
}
