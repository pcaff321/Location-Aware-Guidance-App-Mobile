import 'package:tradeshow_guidance_app/models/access_point.dart';

class BeaconInformationService {
  Future<List<AccessPoint>?> getBeacons() async {
    return beaconFromJson("""[
    {"name": "Mint Cocktail",
        "uuids": ["ebd21ab7-c471-770b-e4df-70ee82026a17"],
        "identifier": "",
        "macAddress": "C2:05:31:8F:61:7E",
        "locationX": 30,
        "locationY": 30,
        "venues": ["UCC"]
    },
    {"name": "Icy Marshmallow",
        "uuids": ["c9ad67d9-0f82-40ac-b097-46c5ce31fe84"],
        "identifier": "",
        "macAddress": "EA:39:DA:A4:12:A0",
        "locationX": 13,
        "locationY": 67,
        "venues": ["UCC"]
    }
]""");
  }

  Future<AccessPoint?> getBeaconByUuid(String uuid) async {
    List<AccessPoint>? beacons = await getBeacons();
    if (beacons != null) {
      Iterable<AccessPoint> matchingBeacons = beacons.where((element) {
        if (element.uuids == null) {
          return false;
        }
        return element.uuids!.contains(uuid);
      });
      if (matchingBeacons.isNotEmpty) {
        return matchingBeacons.first;
      }
    }
    return null;
  }
}
