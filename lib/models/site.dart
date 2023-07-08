import 'section.dart';

class Site {
  static List<Site> cache = [];

  Site({
    required this.id,
    required this.sitename,
  });

  String id;
  String sitename;
  String? sitewebsite;
  String? sitedescription;
  String? creator;
  Section? startsection;

  factory Site.fromJson(Map<String, dynamic> jsonReceived) {
    Map<String, dynamic> json = {};
    for (var key in jsonReceived.keys) {
      json[key.toLowerCase()] = jsonReceived[key];
    }
    String siteId = json["id"].toString();
    if (json["id"] != null && cache.any((element) => element.id == siteId)) {
      var existingSite = cache.firstWhere((element) => element.id == siteId);
      existingSite.sitename = json["sitename"] ?? "Site $siteId";
      existingSite.sitewebsite = json["sitewebsite"] ?? "";
      existingSite.sitedescription = json["sitedescription"] ?? "";
      existingSite.creator = json["creator"] ?? "";
      existingSite.startsection = json["startsection"] == null
          ? null
          : Section.fromJson(json["startsection"]);
      return existingSite;
    } else {
      var newSite = Site(
        id: siteId,
        sitename: json["sitename"] ?? "Site $siteId",
      );
      newSite.sitewebsite = json["sitewebsite"] ?? "";
      newSite.sitedescription = json["sitedescription"] ?? "";
      newSite.creator = json["creator"] ?? "";
      newSite.startsection = json["startsection"] == null
          ? null
          : Section.fromJson(json["startsection"]);
      cache.add(newSite);
      return newSite;
    }
  }

  get description {
    if (sitedescription != null && sitedescription!.isNotEmpty) {
      return sitedescription;
    } else {
      return "No description available";
    }
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "sitename": sitename,
        "sitewebsite": sitewebsite,
        "sitedescription": sitedescription,
        "creator": creator,
        "startsection": startsection == null ? null : startsection!.toJson(),
      };
}
