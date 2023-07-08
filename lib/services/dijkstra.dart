import 'dart:math';

import 'package:tradeshow_guidance_app/models/edge.dart';
import 'package:tradeshow_guidance_app/models/vertex.dart';
import 'package:tradeshow_guidance_app/services/globals.dart';

class Dijkstra {
  List<Vertex> vertices;
  List<Edge> edges;
  double metresPerPixel;

  Map<Vertex, List<Edge>> getAdjacentVertices() {
    Map<Vertex, List<Edge>> adjacentVertices = {};
    for (var vertex in vertices) {
      List<Edge> edgesOfVertex = verticesToEdges[vertex.id] ?? [];
      List<Edge> adjacentEdges = [];
      for (var edge in edgesOfVertex) {
        if (edge.vertexA == vertex) {
          adjacentEdges.add(edge);
        }
      }
      adjacentVertices[vertex] = adjacentEdges;
    }
    return adjacentVertices;
  }

  void setDistancesOfEdges(List<Edge> edgesToCalculate) {
    for (var edge in edgesToCalculate) {
      Vertex vertexA = edge.vertexA;
      Vertex vertexB = edge.vertexB;
      if (verticesToEdges.containsKey(vertexA.id)) {
        if (!verticesToEdges[vertexA.id]!.contains(edge)) {
          verticesToEdges[vertexA.id]!.add(edge);
        }
      } else {
        verticesToEdges[vertexA.id] = [edge];
      }
      if (verticesToEdges.containsKey(vertexB.id)) {
        if (!verticesToEdges[vertexB.id]!.contains(edge)) {
          verticesToEdges[vertexB.id]!.add(edge);
        }
      } else {
        verticesToEdges[vertexB.id] = [edge];
      }
      if (edge.distance < 100000) {
        continue;
      }
      int vertexAX = vertexA.x;
      int vertexAY = vertexA.y;
      int vertexBX = vertexB.x;
      int vertexBY = vertexB.y;
      double distance =
          (vertexAX.toDouble() - vertexBX) * (vertexAX - vertexBX) +
              (vertexAY - vertexBY) * (vertexAY - vertexBY);
      distance = sqrt(distance);
      edge.distance = distance;
    }
  }

  List<Vertex> calculateShortestPath(Vertex source, Vertex destination) {
    if (source == destination) {
      return [];
    }
    if (vertices.isEmpty) {
      return [];
    }
    if (edges.isEmpty) {
      return [];
    }
    int removeAtEnd = 0;
    List<Edge> newEdges = [];
    if (!vertices.contains(source)) {
      vertices.add(source);
      for (var newE in (verticesToEdges[source.id] ?? []).toList()) {
        if (edges.contains(newE)) {
          continue;
        }
        newEdges.add(newE);
      }
      removeAtEnd += 1;
    }
    List<Edge> destinationEdges = verticesToEdges[destination.id] ?? [];
    List<Edge> edgesToReadd = [];
    if (!vertices.contains(destination)) {
      vertices.add(destination);
      removeAtEnd += 1;
      Vertex? vertexA;
      Vertex? vertexB;
      List<Vertex> verticesOfNewEdge = [];
      for (var edge in destinationEdges) {
        if (edge.vertexA == destination) {
          verticesOfNewEdge.add(edge.vertexB);
        } else if (edge.vertexB == destination) {
          verticesOfNewEdge.add(edge.vertexA);
        }
      }
      if (verticesOfNewEdge.length > 1) {
        vertexA = verticesOfNewEdge[0];
        vertexB = verticesOfNewEdge[1];
      }
      if (vertexA != null && vertexB != null) {
        for (var edgeToReadd in edges) {
          if (edgeToReadd.vertexA.id == vertexA.id &&
              edgeToReadd.vertexB.id == vertexB.id) {
            edgesToReadd.add(edgeToReadd);
            continue;
          }
          if (edgeToReadd.vertexA.id == vertexB.id &&
              edgeToReadd.vertexB.id == vertexA.id) {
            edgesToReadd.add(edgeToReadd);
          }
        }
        for (var edgeToReadd in edgesToReadd) {
          edges.remove(edgeToReadd);
        }
      }

      setDistancesOfEdges(destinationEdges);
    }
    for (var newE in destinationEdges) {
      if (edges.contains(newE)) {
        continue;
      }
      newEdges.add(newE);
    }
    edges.addAll(newEdges);
    List<Vertex> settledVertices = [];
    List<Vertex> unsettledVertices = [];
    Map<Vertex, Vertex> predecessors = {};
    Map<String, double> distance = {};
    distance[source.id] = 0;
    for (var vertex in vertices) {
      distance[vertex.id] = double.maxFinite;
    }
    unsettledVertices.add(source);
    distance[source.id] = 0;
    while (unsettledVertices.isNotEmpty) {
      Vertex currentVertex = getLowestDistanceVertex(unsettledVertices, distance);
      unsettledVertices.remove(currentVertex);
      List<Edge> edgesOfCurrentVertex = verticesToEdges[currentVertex.id] ?? [];
      for (var edge in edgesOfCurrentVertex) {
        if (edge.vertexA == currentVertex) {
          Vertex adjacentVertex = edge.vertexB;
          if (!settledVertices.contains(adjacentVertex)) {
            calculateMinimumDistance(
                adjacentVertex, edge, distance, predecessors);
            if (!unsettledVertices.contains(adjacentVertex)) {
              unsettledVertices.add(adjacentVertex);
            }
          }
        }
      }
      if (currentVertex == destination) {
        break;
      }
      settledVertices.add(currentVertex);
    }
    List<Vertex> path = getPath(destination, predecessors);
    while (removeAtEnd > 0) {
      vertices.removeLast();
      removeAtEnd -= 1;
    }
    for (var edge in edgesToReadd) {
      edges.add(edge);
    }
    return path;
  }

  List<Vertex> getPath(Vertex destination, Map<Vertex, Vertex> predecessors) {
    List<Vertex> path = [];
    Vertex? step = destination;
    if (predecessors[step] == null) {
      return [];
    }
    path.add(step);
    while (predecessors[step] != null) {
      step = predecessors[step];
      path.add(step!);
    }
    path = path.reversed.toList();
    return path;
  }

  void calculateMinimumDistance(Vertex evaluationVertex, Edge edge,
      Map<String, double> distance, Map<Vertex, Vertex> predecessors) {
    double sourceDistance = distance[edge.vertexA.id]!;
    if (sourceDistance + edge.distance <
        (distance[evaluationVertex.id] ?? double.infinity)) {
      distance[evaluationVertex.id] = sourceDistance + edge.distance;
      predecessors[evaluationVertex] = edge.vertexA;
    }
  }
  

  Vertex getLowestDistanceVertex(List<Vertex> unsettledVertices, Map<String, double> distance) {
    Vertex lowestDistanceVertex = unsettledVertices[0];
    double lowestDistance = double.infinity;
    for (var vertex in unsettledVertices) {
      List<Edge> edgesOfVertex = verticesToEdges[vertex.id] ?? [];
      if (!edgesOfVertex.any((element) => element.vertexB == vertex)) {
        continue;
      }
      Edge edge = edges.firstWhere((element) => element.vertexB == vertex);
      double vertexDistance = distance[edge.vertexB.id] ?? double.infinity;
      if (vertexDistance < lowestDistance) {
        lowestDistance = vertexDistance;
        lowestDistanceVertex = vertex;
      }
    }
    return lowestDistanceVertex;
  }

  Dijkstra(
      {required this.vertices,
      required this.edges,
      required double this.metresPerPixel}) {
    if (vertices.isEmpty) {
      print("No vertices");
    }
    if (edges.isEmpty) {
      print("No edges");
    }
    makeSubdividedGraph();
    setDistancesOfEdges(edges);
  }

  Map<String, List<Edge>> verticesToEdges = {};
  List<Vertex> allVertices = [];

  makeSubdividedGraph() {
    double minDistanceInMeters = 0.75;
    double minDistanceInPixels = minDistanceInMeters / metresPerPixel;
    List<List<String>> checkedCombinations = [];
    int numberOfOriginalVertices = vertices.length;
    int verticesLimit = 1500;
    allVertices.addAll(vertices);
    for (var edge in edges) {
      if (numberOfOriginalVertices > verticesLimit) {
        break;
      }
      bool alreadyInCombinations = checkedCombinations.any((element) =>
          (element[0] == edge.vertexA.id && element[1] == edge.vertexB.id) ||
          (element[0] == edge.vertexB.id && element[1] == edge.vertexA.id));
      if (alreadyInCombinations){
        continue;
      }
      checkedCombinations.add([edge.vertexA.id, edge.vertexB.id]);
      checkedCombinations.add([edge.vertexB.id, edge.vertexA.id]);
      int vertexAX = edge.vertexA.x;
      int vertexAY = edge.vertexA.y;
      int vertexBX = edge.vertexB.x;
      int vertexBY = edge.vertexB.y;
      double distance =
          (vertexAX.toDouble() - vertexBX) * (vertexAX - vertexBX) +
              (vertexAY - vertexBY) * (vertexAY - vertexBY);
      distance = sqrt(distance);
      if (distance > minDistanceInPixels) {
        int numberOfVertices = (distance / minDistanceInPixels).ceil() - 1;
        if (numberOfVertices < 0) {
          continue;
        }
        if (numberOfVertices < 1) {
          numberOfVertices = 1;
        }
        if (numberOfVertices > 5) {
          numberOfVertices = 5;
        }
        int xDifference = (vertexBX - vertexAX) ~/ (numberOfVertices + 1);
        int yDifference = (vertexBY - vertexAY) ~/ (numberOfVertices + 1);
        for (int i = 1; i <= numberOfVertices; i++) {
          if (numberOfOriginalVertices > verticesLimit) {
            break;
          }
          numberOfOriginalVertices++;
          String id = (Globals.getFakeId() * -1).toString();
          String vertexName = "Subdivided vertex ${edge.vertexA.id}${edge.vertexB.id}";
          Vertex newVertex = Vertex(id, vertexName, vertexAX + xDifference * i,
              vertexAY + yDifference * i);
          allVertices.add(newVertex);

          Edge newEdge = Edge(vertexA: newVertex, vertexB: edge.vertexA);
          Edge newEdge2 = Edge(vertexA: newVertex, vertexB: edge.vertexB);

          Edge newEdgeReversed =
              Edge(vertexA: edge.vertexA, vertexB: newVertex);
          Edge newEdge2Reversed =
              Edge(vertexA: edge.vertexB, vertexB: newVertex);
            
          verticesToEdges[newVertex.id] = [
            newEdge,
            newEdge2,
            newEdgeReversed,
            newEdge2Reversed
          ];
        }
      }
    }
    //edges.addAll(newEdges);
  }
}
