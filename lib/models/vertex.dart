import '../services/globals.dart';
import 'edge.dart';

class Vertex {
  static List<Vertex> vertexCache = [];

  static Vertex parseObject(Map<String, dynamic> resultJson) {
    Map<String, dynamic> result = {};
    resultJson.forEach((key, value) {
      result[key.toLowerCase()] = value;
    });
    if (result['id'] == null ||
        result['id'] == '' ||
        int.parse(result['id'].toString()) < 1) {
      result['id'] = (Globals.getFakeId() * -1).toString();
    }
    String vertexId = result['id'].toString();
    int x = result['x'];
    int y = result['y'];
    String sectionId = ((result['section'] ?? {'id': 0})['id'] ?? 0).toString();
    Vertex? newVertex = vertexCache.any((vertex) =>
            (vertex.id == vertexId || vertex.sectionId == sectionId) && vertex.x == x && vertex.y == y)
        ? vertexCache.where((vertex) =>
            (vertex.id == vertexId || vertex.sectionId == sectionId) && vertex.x == x && vertex.y == y).first
        : null;
    if (newVertex == null) {
      newVertex = Vertex(vertexId, result['vertexName'] ?? "Vertex $vertexId",
          result['x'] ?? 0, result['y'] ?? 0);
      if (newVertex.id == '' || int.parse(newVertex.id) < 1) {
        newVertex.id = (newVertex.fakeId * -1).toString();
      }
      newVertex.sectionId = sectionId;
      newVertex.vertexName = result['vertexname'];
      vertexCache.add(newVertex);
    } else {
      newVertex.x = result['x'];
      newVertex.y = result['y'];
      newVertex.sectionId = sectionId;
      newVertex.vertexName = result['vertexname'];
    }
    return newVertex;
  }

  late String id;
  int x;
  int y;
  String? _vertexName;
  late int fakeId;
  List<Vertex> edges = [];
  int doorType = 0;
  String? sectionId;

  String get vertexName {
    if (_vertexName == null) {
      return "Vertex $id";
    }
    return _vertexName!;
  }

  set vertexName(String value) {
    _vertexName = value;
  }

  Edge? addEdge(Vertex vertex) {
    if (!vertexCache
        .any((vertex) => vertex.id == id || vertex.fakeId == fakeId)) {
      vertexCache.add(this);
    }
    if (!edges.contains(vertex)) {
      edges.add(vertex);
    }
    Edge newEdge = Edge(vertexA: this, vertexB: vertex);
    return newEdge;
  }

  Vertex(this.id, String vertexName, this.x, this.y) {
    this.fakeId = Globals.getFakeId();
    if (id == '' || int.parse(id) < 1) {
      id = (this.fakeId * -1).toString();
    }
    this.vertexName = vertexName;
    if (!vertexCache
        .any((vertex) => vertex.id == id || vertex.fakeId == fakeId)) {
      vertexCache.add(this);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vertexName': vertexName,
      'x': x,
      'y': y,
      'fakeId': fakeId,
      'section': {'id': sectionId}
    };
  }

  get isEntrance => !isExit;

  get isExit => doorType == 2;
}
