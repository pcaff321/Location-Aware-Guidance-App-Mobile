import 'package:tradeshow_guidance_app/models/vertex.dart';
import 'package:tradeshow_guidance_app/services/globals.dart';

class Edge {
  static List<Edge> cache = [];

  static Edge parseObject(Map<String, dynamic> jsonReceived) {
    Map<String, dynamic> json = {};
    for (var key in jsonReceived.keys) {
      json[key.toLowerCase()] = jsonReceived[key];
    }
    Edge? existingEdge;
    if (cache.any((edge) => edge.id == json["id"])) {
      existingEdge = cache.firstWhere((edge) => edge.id == json["id"]);
    }
    if (existingEdge != null) {
      existingEdge.vertexA = Vertex.parseObject(json["vertexa"]);
      existingEdge.vertexB = Vertex.parseObject(json["vertexb"]);
      return existingEdge;
    } else {
      var newEdge = Edge(
        id: json["id"],
        vertexA: Vertex.parseObject(json["vertexa"]),
        vertexB: Vertex.parseObject(json["vertexb"]),
      );
      cache.add(newEdge);
      return newEdge;
    }
  }

  late int id;
  Vertex vertexA;
  Vertex vertexB;
  late int fakeId;
  double distance = 100001;

  Edge({
    required this.vertexA,
    required this.vertexB,
    int? id,
  }) {
    fakeId = Globals.getFakeId();
    if (id != null) {
      this.id = id;
    } else {
      this.id = Globals.getFakeId() * -1;
    }
    if (vertexA == vertexB) {
      throw Exception("Vertex A and Vertex B are the same");
    }
    if (id == 0) {
      id = Globals.getFakeId() * -1;
    }
    if (cache.any((edge) => edge.id == this.id)) {
      Edge existingEdge = cache.firstWhere((edge) => edge.id == this.id);
      existingEdge.vertexA = vertexA;
      existingEdge.vertexB = vertexB;
    } else {
      cache.add(this);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "vertexAid": vertexA.id,
      "vertexBid": vertexB.id,
      "vertexA": vertexA.toJson(),
      "vertexB": vertexB.toJson(),
      "vertexAfakeId": vertexA.fakeId,
      "vertexBfakeId": vertexB.fakeId,
      "fakeId": fakeId,
    };
  }
}
