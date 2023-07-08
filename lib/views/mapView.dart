import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tradeshow_guidance_app/models/edge.dart';
import 'package:tradeshow_guidance_app/models/hint.dart';
import 'package:tradeshow_guidance_app/models/project.dart';
import 'package:tradeshow_guidance_app/models/project_to_section.dart';
import 'package:tradeshow_guidance_app/models/section.dart';
import 'package:tradeshow_guidance_app/models/network_device.dart';
import 'package:tradeshow_guidance_app/models/site.dart';
import 'package:tradeshow_guidance_app/models/site_map.dart';
import 'package:tradeshow_guidance_app/models/vertex.dart';
import 'package:tradeshow_guidance_app/services/activeService.dart';
import 'package:tradeshow_guidance_app/services/destination_setting.dart';
import 'package:tradeshow_guidance_app/services/dijkstra.dart';
import 'package:tradeshow_guidance_app/services/httpService.dart';
import 'package:tradeshow_guidance_app/services/storageService.dart';
import 'package:tradeshow_guidance_app/views/profile_page.dart';

import 'dart:ui' as ui;

import '../models/access_point.dart';
import '../services/globals.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Color beaconColor = Colors.green;

  Map<String, Color> beaconColors = {};

  double imageResizeRatio = 1;

  ActiveService activeService = ActiveService.instance;
  HttpService httpService = HttpService.instance;

  AccessPoint? closestBeacon;

  Section? currentSection;

  final viewTransformationController = TransformationController();

  List<Vertex> pathVertices = [];

  bool allowLocationUpdate = true;

  List<Section> availableSections = [];

  Section? enterSectionSuggestion;
  Section? exitSectionSuggestion;

  bool showUserLocation = true;
  bool showVertices = false;
  bool showAccessPoints = false;
  bool showSubSections = true;
  bool showHints = true;
  bool showRoutes = true;
  bool showProjects = true;

  bool connectTargetProject = false;

  int destinationSetting = 0;
  Project? targetProject;
  Section? targetSection;

  List<StreamSubscription> loadingSubs = [];

  Site? currentSite;

  List<double> currentLocation = [0, 0];

  bool fromClosestBeacon = false;

  List<Edge> edges = [];
  Dijkstra? dijkstra;
  List<ProjectToSection> projectsToSectionsHere = [];

  List<Hint> hints = [];

  double? quickestPath;

  bool restartedState = true;

  Image? currentImage;

  String? currentImageMapId;

  List<StreamSubscription> subscriptions = [];

  void cancelSubscriptions() {
    for (StreamSubscription sub in subscriptions) {
      sub.cancel();
    }
    subscriptions = [];
  }

  @override
  void initState() {
    bool? showUserLocationBool =
        StorageService.instance.getBool("showUserLocation");
    showUserLocation = showUserLocationBool ?? true;
    bool? showSubSectionsBool =
        StorageService.instance.getBool("showSubSections");
    showSubSections = showSubSectionsBool ?? true;
    bool? showHintsBool = StorageService.instance.getBool("showHints");
    showHints = showHintsBool ?? true;
    bool? showRoutesBool = StorageService.instance.getBool("showRoutes");
    showRoutes = showRoutesBool ?? true;
    bool? allowLocationUpdateBool =
        StorageService.instance.getBool("allowLocationUpdate");
    allowLocationUpdate = allowLocationUpdateBool ?? true;

    int? destinationSettingInt =
        StorageService.instance.getInt("destinationSetting");
    destinationSetting = destinationSettingInt ?? 0;
    int? targetProjectIdInt = StorageService.instance.getInt("targetProjectId");
    if (targetProjectIdInt != null &&
        targetProjectIdInt > 0 &&
        Project.projectCache
            .any((project) => project.id == targetProjectIdInt)) {
      targetProject = Project.projectCache
          .firstWhere((project) => project.id == targetProjectIdInt);
    }
    int? targetSectionIdInt = StorageService.instance.getInt("targetSectionId");
    if (targetSectionIdInt != null &&
        targetSectionIdInt > 0 &&
        Section.cache.any((section) => section.id == targetSectionIdInt)) {
      targetSection = Section.cache
          .firstWhere((section) => section.id == targetSectionIdInt);
    }

    subscriptions.add(activeService.currentSectionStream.listen((section) {
      if (section != currentSection) {
        pathVertices = [];
        destinationVertex = null;
        currentSection = section;
        List<Vertex> verticesHere = currentSection!.innerMap.vertices;
        projectsToSectionsHere = ProjectToSection.cache
            .where((projectToSection) =>
                projectToSection.section.id == currentSection!.id)
            .toList();
        verticesHere = verticesHere.map((Vertex v) => v).toList();
        edges = currentSection!.innerMap.edges;
        dijkstra = Dijkstra(
            vertices: verticesHere,
            edges: edges,
            metresPerPixel: currentSection!.innerMap.metresPerPixel);
        hints = httpService
                .hintsBySiteMapId[currentSection!.innerMap.id.toString()] ??
            [];
        if (mounted) {
          setState(() {});
        } else {
          cancelSubscriptions();
        }
      }
    }));

    subscriptions.add(activeService.loadingSiteStream.listen((newSite) {
      if (mounted) {
        setState(() {});
      } else {
        cancelSubscriptions();
      }
    }));

    subscriptions.add(activeService.updateMapViewStream.listen((updateMap) {
      if (mounted) {
        setState(() {});
      } else {
        cancelSubscriptions();
      }
    }));

    subscriptions.add(activeService.userPositionStream.listen((position) {
      if (!mounted) {
        cancelSubscriptions();
        return;
      }
      if (currentLocation[0] == position[0] &&
          currentLocation[1] == position[1]) {
        return;
      }
      setState(() {});
    }));

    super.initState();
  }

  List<Vertex> candidateVs = [];

  List<double> pointA = [0, 0];
  List<double> pointB = [0, 0];
  bool setPointA = false;
  bool setPointB = false;

  double? distanceInMetres = 10000;

  int lastLocationEstimationClick = 0;

  GlobalKey mapKey = GlobalKey();
  double mapWidth = 0;
  double mapHeight = 0;

  int mapKeyRetries = 0;

  @override
  Widget build(BuildContext context) {
    if (activeService.loadingSite) {
      return const Center(child: CircularProgressIndicator());
    }
    if (activeService.currentSection != currentSection) {
      currentSection = activeService.currentSection;
      List<Vertex> verticesHere = currentSection!.innerMap.vertices;
      verticesHere = verticesHere.map((Vertex v) => v).toList();
      projectsToSectionsHere = ProjectToSection.cache
          .where((projectToSection) =>
              projectToSection.section.id == currentSection!.id)
          .toList();
      edges = currentSection!.innerMap.edges;
      dijkstra = Dijkstra(
          vertices: verticesHere,
          edges: edges,
          metresPerPixel: currentSection!.innerMap.metresPerPixel);
      hints = httpService
              .hintsBySiteMapId[currentSection!.innerMap.id.toString()] ??
          [];
      userLocation = [0, 0];

      viewTransformationController.value = Matrix4.identity();
    }
    if (currentSection == null) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(25.0),
        child: Text(
          "No site selected. Please make sure that you have a site selected on the home page.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
    }
    Widget distanceNote = Container();
    if ((showRoutes) &&
        quickestPath != null &&
        quickestPath! > 0 &&
        quickestPath! < 10000 &&
        currentSection != null) {
      distanceInMetres =
          (quickestPath! * currentSection!.innerMap.metresPerPixel);
      distanceNote = Text(
          "Distance to destination: ~${distanceInMetres!.toStringAsFixed(2)}m");
    } else {
      pathVertices = [];
    }
    List<AccessPoint> newAPs = [];
    for (int i = 0; i < 6; i++) {
      AccessPoint newAP = AccessPoint(
          name: "AP$i", uuids: ["uuid$i"], macAddress: "NONE", venues: []);
      newAP.locationX = 20 * i;
      newAP.locationY = 20 * i;
      newAPs.add(newAP);
    }
    availableSections = activeService.availableSections;
    if (currentSection != null && !availableSections.contains(currentSection)) {
      availableSections.add(currentSection!);
    }
    Widget interactiveViewer = getInteractiveViewer(context);
    List<Widget> floatingButtonsOriginal = [
      FloatingActionButton(
        heroTag: currentSection!.id.toString() + "mapView",
        onPressed: () {
          activeService.updateClickUsages("locationEstimationClick");
          setState(() {
            int now = DateTime.now().millisecondsSinceEpoch;
            int sevenSecondsInMilliseconds = 7000;
            if (now - lastLocationEstimationClick <
                sevenSecondsInMilliseconds) {
              int secondsLeft = (sevenSecondsInMilliseconds -
                      (now - lastLocationEstimationClick)) ~/
                  1000;
              Fluttertoast.showToast(
                msg:
                    "Please wait $secondsLeft seconds before trying to guess location again.",
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black,
                textColor: Colors.white,
                fontSize: 16.0,
              );
              return;
            }
            lastLocationEstimationClick = now;
            fromClosestBeacon = true;
            updateLocation(userLocation[0] * imageResizeRatio,
                userLocation[1] * imageResizeRatio);
          });
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.route_sharp),
      ),
      const SizedBox(width: 10),
      FloatingActionButton(
        heroTag: currentSection!.id.toString() + "mapView2",
        onPressed: () {
          if (currentSection == null || currentSection!.outerMap == null) {
            return;
          }
          Section? sectionAbove;
          for (var section in availableSections) {
            if (section.innerMap == currentSection!.outerMap!) {
              sectionAbove = section;
            }
          }
          if (sectionAbove != null) {
            activeService.updateCurrentSection(sectionAbove);
          }
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.logout),
      ),
    ];
    if (enterSectionSuggestion != null) {
      floatingButtonsOriginal.add(const SizedBox(width: 10));
      floatingButtonsOriginal.add(FloatingActionButton(
        heroTag: currentSection!.id.toString() + "mapView3",
        onPressed: () {
          if (enterSectionSuggestion != null) {
            activeService.updateCurrentSection(enterSectionSuggestion!);
            enterSectionSuggestion = null;
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.meeting_room),
      ));
    }
    List<Widget> floatingButtons = [];
    if (enterSectionSuggestion != null) {
      floatingButtons
          .add(Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.green.withOpacity(0.7),
            ),
            color: Colors.black.withOpacity(0.7),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Enter " + enterSectionSuggestion!.sectionName + "?",
                style: TextStyle(
                    color: Colors.white,
                    overflow: TextOverflow.ellipsis,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: floatingButtonsOriginal,
        )
      ]));
    } else if (exitSectionSuggestion != null &&
        distanceInMetres != null &&
        distanceInMetres! < 1.25) {
      floatingButtons
          .add(Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.red.withOpacity(0.7),
            ),
            color: Colors.black.withOpacity(0.7),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Exit " + exitSectionSuggestion!.sectionName + "?",
                style: TextStyle(
                    color: Colors.red,
                    overflow: TextOverflow.ellipsis,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: floatingButtonsOriginal,
        )
      ]));
    } else {
      floatingButtons = floatingButtonsOriginal;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white10,
        title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              DropdownButton(
                  icon: const Icon(Icons.arrow_downward_sharp),
                  iconEnabledColor: Colors.black,
                  iconDisabledColor: Colors.transparent,
                  iconSize: 24,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  value: currentSection,
                  alignment: Alignment.center,
                  items: availableSections
                      .map<DropdownMenuItem<Section>>((Section value) {
                    return DropdownMenuItem<Section>(
                      value: value,
                      child: Text(
                          value.sectionName.length > 15
                              ? value.sectionName.substring(0, 15) + "..."
                              : value.sectionName,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: availableSections.length > 1
                      ? (Section? newValue) {
                          activeService.updateCurrentSection(availableSections
                              .firstWhere((element) => element == newValue));
                        }
                      : null),
            ]),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Column(
                  children: [
                    TextButton(
                        style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            padding: MaterialStateProperty.all<EdgeInsets>(
                                const EdgeInsets.all(0)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.black87)),
                        onPressed: () {
                          setState(() {
                            allowLocationUpdate = !allowLocationUpdate;
                            StorageService.instance.setBool(
                                "allowLocationUpdate", allowLocationUpdate);
                          });
                        },
                        child: Center(
                          child: FittedBox(
                            child: Row(
                              children: [
                                Text(
                                  "SET LOCATION",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: allowLocationUpdate
                                          ? Colors.red
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.location_on,
                                  size: 20.0,
                                  color: allowLocationUpdate
                                      ? Colors.red
                                      : Colors.white,
                                )
                              ],
                            ),
                          ),
                        )),
                    TextButton(
                        style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            padding: MaterialStateProperty.all<EdgeInsets>(
                                const EdgeInsets.all(0)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.black87)),
                        onPressed: () {
                          setState(() {
                            showRoutes = !showRoutes;
                            updateLocation(userLocation[0] * imageResizeRatio,
                                userLocation[1] * imageResizeRatio);
                            StorageService.instance
                                .setBool("showRoutes", showRoutes);
                          });
                        },
                        child: Center(
                          child: FittedBox(
                            child: Row(
                              children: [
                                Text(
                                  showRoutes ? "HIDE ROUTES" : "SHOW ROUTES",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              )),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Column(
                  children: [
                    TextButton(
                        style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            padding: MaterialStateProperty.all<EdgeInsets>(
                                const EdgeInsets.all(0)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.black87)),
                        onPressed: () {
                          setState(() {
                            showSubSections = !showSubSections;
                            StorageService.instance
                                .setBool("showSubSections", showSubSections);
                          });
                        },
                        child: Center(
                          child: FittedBox(
                            child: Row(
                              children: [
                                Text(
                                  showSubSections ? "HIDE AREAS" : "SHOW AREAS",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )),
                    TextButton(
                        style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            padding: MaterialStateProperty.all<EdgeInsets>(
                                const EdgeInsets.all(0)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.black87)),
                        onPressed: () {
                          setState(() {
                            showHints = !showHints;
                            StorageService.instance
                                .setBool("showHints", showHints);
                          });
                        },
                        child: Center(
                          child: FittedBox(
                            child: Row(
                              children: [
                                Text(
                                  showHints ? "HIDE HINTS" : "SHOW HINTS",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              )),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Column(
                  children: [
                    TextButton(
                        style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            padding: MaterialStateProperty.all<EdgeInsets>(
                                const EdgeInsets.all(0)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.black87)),
                        onPressed: () {
                          activeService
                              .updateClickUsages("setDestinationClick");
                          setState(() {
                            openDestinationDialog();
                          });
                        },
                        child: Center(
                          child: FittedBox(
                            child: Row(
                              children: [
                                Text(
                                  "SET DESTINATION [${getDestination()}]",
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )),
                    distanceNote
                  ],
                ),
              )),
            ],
          ),
          Expanded(child: interactiveViewer),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: floatingButtons,
      ),
    );
  }

  List<NetworkDevice> usefulDevices = [];

  List<Vertex> findBestStartPositionBasedOnNetworkDeviceRanges(
      List<NetworkDevice> networkDevices,
      List<Vertex> vertices,
      AccessPoint closestNetworkDevice,
      double metresInPixels) {
    usefulDevices = [];
    bool closestBeaconToClosestVertex = false;
    List<NetworkDevice> candidateNetworkDevices = [];
    if (vertices.isEmpty) {
      return [];
    }
    if ((this.currentSection?.subsections ?? []).isEmpty) {
      closestBeaconToClosestVertex = true;
    }
    NetworkDevice? closestNetworkDeviceFromAP;
    if (NetworkDevice.cache.any(
        (element) => element.devicemac == closestNetworkDevice.macAddress)) {
      closestNetworkDeviceFromAP = NetworkDevice.cache.firstWhere(
          (element) => element.devicemac == closestNetworkDevice.macAddress);
    } else {
      closestNetworkDeviceFromAP = null;
    }
    double networkDeviceDistance = double.maxFinite;
    if (closestNetworkDeviceFromAP != null) {
      networkDeviceDistance = getDeviceEstimation(closestNetworkDeviceFromAP);
    }
    if (closestBeaconToClosestVertex) {
      if (networkDeviceDistance > 3.0) {
        return [];
      }
      Vertex? closestVertexToClosestNetworkDevice;
      double closestDistanceToNetworkDevice = double.maxFinite;
      for (Vertex vertex in dijkstra!.vertices) {
        double distance = sqrt(
            pow(vertex.x - closestNetworkDevice.locationX!, 2) +
                pow(vertex.y - closestNetworkDevice.locationY!, 2));
        if (distance < closestDistanceToNetworkDevice) {
          closestDistanceToNetworkDevice = distance;
          closestVertexToClosestNetworkDevice = vertex;
        }
      }
      if (closestVertexToClosestNetworkDevice == null) {
        return [];
      }
      return [closestVertexToClosestNetworkDevice];
    }

    for (NetworkDevice networkDevice in networkDevices) {
      if (networkDevice.distance != null) {
        candidateNetworkDevices.add(networkDevice);
      }
    }
    List<Vertex> candidateVertices = [];
    int mostIntersections = 0;
    int mostIntersectionsWithClosest = 0;
    List<Vertex> bestVertices = [];
    List<NetworkDevice> usefulDevicesForBest = [];
    Vertex closestVertexToClosestNetworkDevice = vertices.first;
    double closestDistanceToNetworkDevice = double.infinity;
    for (Vertex vertex in vertices) {
      int total = 0;
      bool withinClosest = false;
      List<NetworkDevice> usefulDevicesForVertex = [];
      for (NetworkDevice networkDevice in candidateNetworkDevices) {
        if (networkDevice.distance != null &&
            networkDevice.relatedAP != null &&
            networkDevice.relatedAP!.locationX != null &&
            networkDevice.relatedAP!.locationY != null) {
          bool isClosest = networkDevice.relatedAP!.macAddress ==
              closestNetworkDevice.macAddress;
          double deviceDistance = getDeviceEstimation(networkDevice);
          if (isClosest) {
            deviceDistance = deviceDistance + 0.25;
          } else {
            deviceDistance = deviceDistance; // * 1.25;
          }
          double distance = deviceDistance / metresInPixels;
          List<int> p1 = [vertex.x, vertex.y];
          List<int> p2 = [
            networkDevice.relatedAP!.locationX!,
            networkDevice.relatedAP!.locationY!
          ];
          double distanceBetweenPoints = getDistance(p1, p2);
          if (isClosest &&
              distanceBetweenPoints < closestDistanceToNetworkDevice) {
            closestDistanceToNetworkDevice = distanceBetweenPoints;
            closestVertexToClosestNetworkDevice = vertex;
          }
          if (distanceBetweenPoints <= distance) {
            total++;
            usefulDevicesForVertex.add(networkDevice);
            if (isClosest) {
              withinClosest = true;
            }
          }
        }
      }
      if (total > mostIntersections) {
        candidateVertices = [vertex];
        usefulDevices = usefulDevicesForVertex;
        mostIntersections = total;
      } else if (total == mostIntersections) {
        candidateVertices.add(vertex);
        usefulDevices.addAll(usefulDevicesForVertex);
      }
      if (withinClosest) {
        if (total > mostIntersectionsWithClosest) {
          usefulDevicesForBest = usefulDevicesForVertex;
          bestVertices = [vertex];
          mostIntersectionsWithClosest = total;
        } else if (total == mostIntersectionsWithClosest) {
          usefulDevicesForBest.addAll(usefulDevicesForVertex);
          bestVertices.add(vertex);
        }
      }
    }
    if (bestVertices.length > 0 && networkDeviceDistance < 1.5) {
      usefulDevices = usefulDevicesForBest.toSet().toList();
      return bestVertices;
    }
    if (candidateVertices.length > 0) {
      usefulDevices = usefulDevices.toSet().toList();
      return candidateVertices;
    }
    return [closestVertexToClosestNetworkDevice];
  }

  Widget getInteractiveViewer(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return InteractiveViewer(
      constrained: true,
      boundaryMargin: EdgeInsets.all(80),
      transformationController: viewTransformationController,
      minScale: 1.0,
      maxScale: 10.0,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
                onTapDown: (position) {
                  //if (!allowLocationUpdate) return;
                  final tapPosition = position.localPosition;
                  final x = tapPosition.dx;
                  final y = tapPosition.dy;
                  if (allowLocationUpdate) {
                    activeService.updateClickUsages("setLocationClick");
                    updateLocation(x, y);
                  }
                  if (setPointA) {
                    pointA = [x, y];
                  } else if (setPointB) {
                    pointB = [x, y];
                  }
                  if (!mounted) return;
                  setState(() {});
                },
                child: Stack(children: getMapWidgets(context))),
          ],
        ),
      ),
    );
  }

  List<double> userLocation = [0.0, 0.0];

  double originalImageX = 800.0;
  double originalImageY = 400.0;
  bool calculatingImageDimensions = false;

  SiteMap? lastCheckedMap;
  String? lastCheckedMapId;

  double metresPerPixel = 1.0;

  double lastDistance = 0.0;

  List<Widget> getMapWidgets(BuildContext context) {
    List<String> networkDevicesMacs =
        activeService.networkDeviceList.map((e) => e.devicemac).toList();
    if (currentSection != null) {
      metresPerPixel = currentSection!.innerMap.metresPerPixel;
    } else {
      metresPerPixel = 0.005;
    }
    ui.Size size = MediaQuery.of(context).size;
    //var decodedImage = decodeImageFromList(imageBytes);

    Image image;

    if (currentImage != null &&
        currentImageMapId == currentSection!.innerMap.id) {
      image = currentImage!;
      try {
        var mapKeyContext = mapKey.currentContext;
        var box = mapKeyContext?.findRenderObject() as RenderBox;
        if (box != null) {
          var testSize = box.size;
          mapWidth = testSize.width;
          mapHeight = testSize.height;
        }
        mapKeyRetries += 1;
      } catch (e) {
        print(e);
      }
    } else {
      mapKeyRetries = 0;
      Uint8List imageBytes =
          Globals.getMapImage(currentSection!.innerMap.mapimage!).bytes;
      image = Image.memory(
        imageBytes,
        fit: BoxFit.contain,
      );
      currentImage = image;
      currentImageMapId = currentSection!.innerMap.id;
    }

    if (currentSection!.innerMap.id != lastCheckedMapId) {
      calculatingImageDimensions = true;
      _calculateImageDimension(image).then((value) {
        calculatingImageDimensions = false;
        originalImageX = value.width;
        originalImageY = value.height;
        if (!mounted) return;
        setState(() {});
      });
    }

    lastCheckedMapId = currentSection!.innerMap.id;

    List<Widget> mapWidgets = [
      ConstrainedBox(
          key: mapKey,
          constraints: BoxConstraints(
            maxWidth: size.width,
            maxHeight: size.height - 400,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: image,
          )),
    ];

    if (calculatingImageDimensions) {
      return mapWidgets +
          [
            Container(
              height: 20,
            ),
            Center(
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.7),
                      ),
                      color: Colors.black.withOpacity(0.7),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("LOADING MAP...",
                              style: TextStyle(
                                  color: Colors.white,
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )))
          ];
    }

    double testMapWidth = mapWidth;
    if (testMapWidth < 3) {
      if (mapKeyRetries < 4) {
        Timer(Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {});
        });
      }
      testMapWidth = size.width;
    }

    double testMapHeight = mapHeight;
    if (testMapHeight < 3) {
      testMapHeight = size.height;
    }

    imageResizeRatio = (testMapWidth / originalImageX);

    updateColors();

    List<Offset> linePoints = [];

    // List<double> userLocation = activeService.userPosition;
    double? userLocationX;
    double? userLocationY;
    double beaconSize = 24;

    if (showUserLocation) {
      if (userLocation.isNotEmpty &&
          userLocation.length == 2 &&
          !userLocation[0].isNaN &&
          !userLocation[1].isNaN &&
          userLocation[0] > 0 &&
          userLocation[1] > 0) {
        userLocationX =
            userLocation[0] * imageResizeRatio; // - (beaconSize * 2);
        userLocationY = userLocation[1] * imageResizeRatio;
        linePoints.add(Offset(userLocationX, userLocationY));
      }
    }

    if (showRoutes && pathVertices.isNotEmpty) {
      for (Vertex vertex in pathVertices) {
        linePoints.add(
            Offset(vertex.x * imageResizeRatio, vertex.y * imageResizeRatio));
      }
      if (pathVertices.length == 1) {
        if (userLocationX != null &&
            userLocationY != null &&
            userLocationX > 0 &&
            userLocationY > 0) {
          quickestPath = getDistance([
            userLocationX / imageResizeRatio,
            userLocationY / imageResizeRatio
          ], [
            pathVertices[0].x,
            pathVertices[0].y
          ]);
        }
      }

      if (connectTargetProject && targetProject != null) {
        if (ProjectToSection.cache
            .any((element) => element.project.id == targetProject!.id)) {
          ProjectToSection projectToSection = ProjectToSection.cache
              .firstWhere((element) => element.project.id == targetProject!.id);
          if (projectToSection.section.id == currentSection!.id &&
              projectToSection.x != null &&
              projectToSection.y != null &&
              projectToSection.x! > 0 &&
              projectToSection.y! > 0) {
            linePoints.add(Offset(projectToSection.x! * imageResizeRatio,
                projectToSection.y! * imageResizeRatio));
          }
        }
      }

      mapWidgets.add(
        CustomPaint(
          size: Size(size.width, originalImageY * imageResizeRatio),
          painter: MyPainter(points: linePoints),
        ),
      );
    }

    enterSectionSuggestion = null;
    exitSectionSuggestion = null;

    if (Section.findParentSection(currentSection) != null) {
      List<String> exitDoorIdsOfSubsection =
          httpService.exitsBySectionId[currentSection!.id.toString()] ?? [];
      List<Vertex> exitDoorsOfSubsection = [];
      for (String doorId in exitDoorIdsOfSubsection) {
        if (!Vertex.vertexCache.any((element) => element.id == doorId)) {
          continue;
        }
        exitDoorsOfSubsection.add(
            Vertex.vertexCache.firstWhere((element) => element.id == doorId));
      }

      for (Vertex door in exitDoorsOfSubsection) {
        double distance =
            getDistance([userLocation[0], userLocation[1]], [door.x, door.y]) *
                metresPerPixel;
        if (distance <= 0.8) {
          exitSectionSuggestion = currentSection!;
        }
      }
    }

    for (Section subsection in currentSection!.subsections) {
      bool insideRoom = false;
      if (userLocation.isNotEmpty &&
          userLocation.length == 2 &&
          !userLocation[0].isNaN &&
          !userLocation[1].isNaN) {
        insideRoom = subsection.containsPoint(
            userLocation[0].toInt(), userLocation[1].toInt());
      }
      if (insideRoom) {
        enterSectionSuggestion = subsection;
      }
      List<String> doorIdsOfSubsection =
          httpService.doorsBySectionId[subsection.id.toString()] ?? [];
      List<Vertex> doorsOfSubsection = [];
      for (String doorId in doorIdsOfSubsection) {
        if (!Vertex.vertexCache.any((element) => element.id == doorId)) {
          continue;
        }
        doorsOfSubsection.add(
            Vertex.vertexCache.firstWhere((element) => element.id == doorId));
      }

      for (Vertex door in doorsOfSubsection) {
        double distance =
            getDistance([userLocation[0], userLocation[1]], [door.x, door.y]) *
                metresPerPixel;
        if (distance <= 3) {
          enterSectionSuggestion = subsection;
          insideRoom = true;
        }
      }
      if (suggestedProject != null &&
          subsection.containsProject(suggestedProject!) &&
          insideRoom) {
        enterSectionSuggestion = subsection;
        break;
      }
    }

    for (Section subsection in currentSection!.subsections) {
      bool insideRoom = false;

      if (enterSectionSuggestion != null &&
          enterSectionSuggestion!.id == subsection.id) {
        insideRoom = true;
      }

      if (showSubSections) {
        List<Project> projectsWithin = subsection.getAllProjectsWithinSection();
        double top = (subsection.topLeftY * imageResizeRatio) - 1;
        double left = (subsection.topLeftX * imageResizeRatio) - 1;
        double width = ((subsection.bottomRightX - subsection.topLeftX) *
                imageResizeRatio) +
            3;
        double height = ((subsection.bottomRightY - subsection.topLeftY) *
                imageResizeRatio) +
            2;
        Color borderColor = insideRoom ? Colors.red : Colors.green;
        Color insideColor = insideRoom
            ? Colors.red.withOpacity(0.20)
            : Colors.green.withOpacity(0.20);
        if (suggestedProject != null &&
            subsection.containsProject(suggestedProject!)) {
          borderColor = insideRoom ? Colors.red : Colors.blue;
          insideColor = insideRoom
              ? Colors.red.withOpacity(0.20)
              : Colors.blue.withOpacity(0.20);
        }
        mapWidgets.add(Positioned(
            top: top,
            left: left,
            child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: borderColor,
                    width: 2,
                  ),
                  color: insideColor,
                ),
                child: Center(
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        children: [
                          Text(
                            subsection.sectionName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black),
                          ),
                          Text(
                            "[${projectsWithin.length} projects]",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black),
                          ),
                          Text(
                            "[${countInterestedProjects(projectsWithin)} marked projects]",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ))));
      }
    }

    List<AccessPoint> beacons =
        (httpService.networkDevicesByMap[currentSection!.innerMap.id] ?? [])
            .map((e) => e.relatedAP!)
            .toList();

    beacons = beacons
        .where((element) => networkDevicesMacs.contains(element.macAddress))
        .toList();


    double closestDistance = 1000000000;

    List<NetworkDevice> networkDevices = activeService.networkDeviceList;
    for (NetworkDevice networkDevice in networkDevices) {
      if (networkDevice.relatedAP != null && networkDevice.distance != null) {
        if (double.parse(networkDevice.distance!) < closestDistance) {
          closestDistance = double.parse(networkDevice.distance!);
        }
      }
    }

    if (showHints) {
      for (var hint in hints) {
        double hintSize = 20;
        double locationX = hint.x.toDouble();
        double locationY = hint.y.toDouble();
        mapWidgets.add(Positioned(
            top: (locationY * imageResizeRatio) - hintSize,
            left: (locationX * imageResizeRatio) - (hintSize / 2),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              icon: Icon(
                Icons.contact_support,
                color: Color.fromARGB(255, 24, 100, 26),
                size: hintSize,
              ),
              onPressed: () {
                activeService.updateClickUsages("hintClicked");
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(hint.name),
                        content: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxHeight: double.infinity),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Center(
                                      child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 240),
                                    child: Image.memory(Globals.getMapImage(
                                            hint.hintImage ?? "")
                                        .bytes),
                                  )),
                                  const SizedBox(height: 10),
                                  Text(hint.hintText)
                                ],
                              ),
                            )),
                        actions: [
                          Container(
                            width: double.infinity,
                            height: 60,
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                activeService
                                    .updateClickUsages("hintImHereClicked");
                                setState(() {
                                  updateLocation(
                                      hint.x.toDouble() * imageResizeRatio,
                                      hint.y.toDouble() * imageResizeRatio,
                                      toClosestVertex: true);
                                });
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                // fixedSize: Size(250, 50),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "I'M HERE",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.location_on)
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            height: 60,
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                // fixedSize: Size(250, 50),
                              ),
                              child: const Text(
                                "CLOSE",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      );
                    });
              },
            )));
      }
    }

    if (showProjects) {
      for (var projectLocation in projectsToSectionsHere) {
        if (projectLocation.x == null ||
            projectLocation.x! <= 0 ||
            projectLocation.y == null ||
            projectLocation.y! <= 0) {
          continue;
        }
        double iconSize = 16;
        double locationX = projectLocation.x!.toDouble();
        double locationY = projectLocation.y!.toDouble();
        IconButton? icon;
        bool interest =
            StorageService.interestsContainProject(projectLocation.project);
        bool visited =
            StorageService.projectWasVisited(projectLocation.project);
        if (interest) {
          icon = IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              icon: Icon(Icons.star,
                  color: visited ? Colors.green : Colors.yellow,
                  size: iconSize),
              iconSize: iconSize,
              onPressed: () {
                Navigator.of(context)
                    .push(_createRoute(
                        ProfilePage(project: projectLocation.project)))
                    .then((value) {
                  afterProfilePage();
                });
              });
        } else {
          icon = IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              icon: Icon(Icons.assignment,
                  color: visited ? Colors.green : Colors.blue, size: iconSize),
              iconSize: iconSize,
              onPressed: () {
                Navigator.of(context)
                    .push(_createRoute(
                        ProfilePage(project: projectLocation.project)))
                    .then((value) {
                  if (mounted) {
                    afterProfilePage();
                  }
                });
              });
        }
        locationX = (locationX * imageResizeRatio) - (iconSize * 0.5);
        locationY = (locationY * imageResizeRatio) - (iconSize * 0.5);
        mapWidgets.add(Positioned(
            top: locationY, // * imageResizeRatio,
            left: locationX, // * imageResizeRatio,
            child: icon));
      }
    }

    if (showVertices) {
      List<Vertex> verticesAll = dijkstra!.allVertices;
      for (var vertex in verticesAll) {
        double beaconSize = 10;
        double locationX = vertex.x.toDouble();
        double locationY = vertex.y.toDouble();

        Color routeColor = Colors.black;
        if (pathVertices.contains(vertex)) {
          routeColor = Colors.red;
          beaconSize = 30;
        }
        if (vertex == closestVertex) {
          routeColor = Colors.blue;
        } else if (vertex == destinationVertex) {
          routeColor = Colors.green;
        }
        routeColor = routeColor.withOpacity(0.3);
        locationX = (locationX * imageResizeRatio) - (beaconSize / 2);
        locationY = (locationY * imageResizeRatio) - (beaconSize / 2);
        mapWidgets.add(Positioned(
            top: locationY,
            left: locationX,
            child: Icon(
              Icons.circle,
              color: routeColor,
              size: beaconSize,
            )));
      }
    }

    if (showAccessPoints) {
      metresPerPixel = currentSection!.innerMap.metresPerPixel;
      beacons = beacons
          .where((element) => networkDevicesMacs.contains(element.macAddress))
          .toList();
      for (var beacon in beacons) {
        double beaconSize = 10;
        Color beaconColor = getBeaconColor(beacon.name);
        if (NetworkDevice.cache.any((element) =>
            element.relatedAP != null &&
            element.relatedAP!.macAddress == beacon.macAddress)) {
          NetworkDevice networkDevice = NetworkDevice.cache.firstWhere(
              (element) =>
                  element.relatedAP != null &&
                  element.relatedAP!.macAddress == beacon.macAddress);
          if (networkDevice.distance != null) {
            beaconSize =
                ((((getDeviceEstimation(networkDevice) / metresPerPixel) + 6) *
                            imageResizeRatio) *
                        4) +
                    beaconSize;
          }
        }
        
        if (beaconSize < 1) {
          beaconSize = 1;
        }
        beaconColor = beaconColor.withOpacity(0.3);
        double locationX =
            (beacon.locationX! * imageResizeRatio) - (beaconSize / 2);
        double locationY =
            (beacon.locationY! * imageResizeRatio) - (beaconSize / 2);
        mapWidgets.add(Positioned(
            top: locationY, // * imageResizeRatio,
            left: locationX, // * imageResizeRatio,
            child: Icon(
              Icons.circle,
              color: beaconColor,
              size: beaconSize,
            )));
      }
    }

    if (showUserLocation && userLocationX != null && userLocationY != null) {
      mapWidgets.add(Positioned(
          top: (userLocationY) - (beaconSize),
          left: (userLocationX) - (beaconSize / 2),
          child: const Icon(
            Icons.person_pin,
            color: Colors.green,
            size: 24,
          )));
    }

    closestBeacon = null;


    if (pointA.isNotEmpty && pointA.length == 2) {
      double pointAX = pointA[0];
      double pointAY = pointA[1];
      int beaconSize = 2;
      mapWidgets.add(Positioned(
          left: pointAX - (beaconSize / 2),
          top: pointAY - (beaconSize / 2),
          child: Container(
            width: beaconSize.toDouble(),
            height: beaconSize.toDouble(),
            decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.circular(beaconSize * 2)),
          )));
      double pointBX = pointB[0];
      double pointBY = pointB[1];
      mapWidgets.add(Positioned(
          left: pointBX - (beaconSize / 2),
          top: pointBY - (beaconSize / 2),
          child: Container(
            width: beaconSize.toDouble(),
            height: beaconSize.toDouble(),
            decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(beaconSize * 2)),
          )));
      double distanceBetweenPoints =
          ((getDistance(pointA, pointB) + 6) / imageResizeRatio) *
              currentSection!.innerMap.metresPerPixel;
      lastDistance = distanceBetweenPoints;
    }

    return mapWidgets;
  }

  int countInterestedProjects(List<Project> projects) {
    int count = 0;
    for (Project project in projects) {
      if (StorageService.interestsContainProject(project)) {
        count++;
      }
    }
    return count;
  }

  void afterProfilePage() {
    int? destinationSettingInt =
        StorageService.instance.getInt("destinationSetting");
    destinationSetting = destinationSettingInt ?? 0;
    int? targetProjectIdInt = StorageService.instance.getInt("targetProjectId");
    if (targetProjectIdInt != null &&
        targetProjectIdInt > 0 &&
        Project.projectCache
            .any((project) => project.id == targetProjectIdInt)) {
      targetProject = Project.projectCache
          .firstWhere((project) => project.id == targetProjectIdInt);
    }
    int? targetSectionIdInt = StorageService.instance.getInt("targetSectionId");
    if (targetSectionIdInt != null &&
        targetSectionIdInt > 0 &&
        Section.cache.any((section) => section.id == targetSectionIdInt)) {
      targetSection = Section.cache
          .firstWhere((section) => section.id == targetSectionIdInt);
    }
    if (mounted) {
      setState(() {
        updateLocation(userLocation[0] * imageResizeRatio,
            userLocation[1] * imageResizeRatio);
      });
    }
  }

  Project? suggestedProject;

  double? getZoomFactorBasedOnMapSize() {
    double? zoomFactor;
    if (currentSection != null) {
      double distanceBetweenPixelInMetres =
          currentSection!.innerMap.metresPerPixel;
      double originalImageX = 800.0;
      double screenX = MediaQuery.of(context).size.width;
      double resizeRatio = screenX / originalImageX;
      double metresPerPixelResized = distanceBetweenPixelInMetres * resizeRatio;
      double pixelsNeededForOneMetre = 1 / metresPerPixelResized;
      zoomFactor = screenX / (pixelsNeededForOneMetre * 3);
    }
    return zoomFactor;
  }

  Vertex? closestVertex;
  Vertex? destinationVertex;
  int lastGottenProjectId = -1;

  void updateLocation(double x, double y, {bool toClosestVertex = false}) {
    if (!mounted) return;
    if (currentSection != null) {
      metresPerPixel = currentSection!.innerMap.metresPerPixel;
    }
    double closest = double.infinity;
    closestBeacon = null;

    userLocation = [x / imageResizeRatio, y / imageResizeRatio];

    List<String> networkDevicesMacs =
        activeService.networkDeviceList.map((e) => e.devicemac).toList();

    List<AccessPoint> mapAPs =
        (httpService.networkDevicesByMap[currentSection!.innerMap.id] ?? [])
            .map((e) => e.relatedAP!)
            .toList();

    mapAPs = mapAPs
        .where((element) => networkDevicesMacs.contains(element.macAddress))
        .toList();

    List<NetworkDevice> devicesFound = activeService.networkDeviceList;
    List<NetworkDevice> devicesCandidates = [];

    devicesFound.forEach((device) {
      if (device.distance != null) {
        double distance = double.parse(device.distance!);
        if (!mapAPs.any((element) => element.macAddress == device.devicemac)) {
          return;
        }
        AccessPoint relatedAP = mapAPs
            .firstWhere((element) => element.macAddress == device.devicemac);
        devicesCandidates.add(device);
        if (distance < closest) {
          closestBeacon = relatedAP;
          closest = distance;
        }
      }
    });

    if (fromClosestBeacon && closestBeacon != null) {
      x = closestBeacon!.locationX! * imageResizeRatio;
      y = closestBeacon!.locationY! * imageResizeRatio;
    }

    double closestV = double.infinity;
    double closestCandidate = double.infinity;

    List<String> candidates = [];

    connectTargetProject = false;

    suggestedProject = null;

    if (destinationSetting == DestinationSetting.PROJECT) {
      int? targetProjectIdInt =
          StorageService.instance.getInt("targetProjectId");
      if (targetProjectIdInt != null &&
          lastGottenProjectId != targetProjectIdInt &&
          targetProjectIdInt > 0 &&
          Project.projectCache
              .any((project) => project.id == targetProjectIdInt)) {
        targetProject = Project.projectCache
            .firstWhere((project) => project.id == targetProjectIdInt);
        lastGottenProjectId = targetProjectIdInt;
      }
    }

    if (destinationSetting == DestinationSetting.PROJECT &&
        targetProject != null) {
      connectTargetProject = true;
      suggestedProject = targetProject;
      candidates =
          findTargetProjectVerticesFromSection(currentSection!, targetProject!);
    } else if (destinationSetting == DestinationSetting.ROOM &&
        targetSection != null) {
      if (targetSection == currentSection) {
        candidates = [];
        pathVertices = [];
        destinationVertex = null;
        Fluttertoast.showToast(
          msg: "You are already in the target room.",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        candidates = findTargetRoomVerticesFromSection(targetSection!);
      }
    } else if (destinationSetting == DestinationSetting.EXIT) {
      List<String> potentialExits =
          httpService.exitsBySectionId[currentSection!.id.toString()] ?? [];
      candidates = [];
      for (String potentialExit in potentialExits) {
        if (Vertex.vertexCache.any((element) => element.id == potentialExit)) {
          candidates.add(potentialExit);
        }
      }
    } else if (destinationSetting == DestinationSetting.CLOSEST_ROOM) {
      List<Section> subsections = currentSection!.subsections;
      candidates = [];
      for (Section subsection in subsections) {
        List<String> subsectionDoors =
            httpService.doorsBySectionId[subsection.id.toString()] ?? [];
        for (String subsectionDoor in subsectionDoors) {
          if (!candidates.contains(subsectionDoor)) {
            candidates.add(subsectionDoor);
          }
        }
      }
    } else {
      // default algorithm
      if (currentSection == null) {
        candidates = [];
        return;
      }
      Section? targetRoomByMostInterestAndNotVisited;
      suggestedProject = null;
      List<Project> interestedProjects = StorageService.getInterestedProjects();
      List<Project> visitedProjects = StorageService.getVisitedProjects();
      List<ProjectToSection> projectToSectionList = ProjectToSection.cache
          .where((element) =>
              element.x != null &&
              element.y != null &&
              element.x != 0 &&
              element.y != 0)
          .toList();
      bool unvisitedFavoriteProjectsExist = interestedProjects.any((element) =>
          !visitedProjects.contains(element) &&
          element.hasKnownLocation &&
          projectToSectionList.any((p) => p.project.id == element.id));
      interestedProjects = interestedProjects
          .where((element) =>
              element.hasKnownLocation &&
              projectToSectionList.any((p) => p.project.id == element.id))
          .toList();
      if (unvisitedFavoriteProjectsExist) {
        int mostInterests = -1;
        List<Project> currentSectionProjects = [];
        if (currentSection!.projects != null &&
            currentSection!.projects!.isNotEmpty) {
          currentSectionProjects = currentSection!.projects!
              .where((element) =>
                  !visitedProjects.contains(element) &&
                  projectsToSectionsHere.any((p) => p.project.id == element.id))
              .toList();
        }
        if (currentSectionProjects.isNotEmpty &&
            interestedProjects.any((element) =>
                currentSectionProjects.any((p) => p.id == element.id))) {
          targetRoomByMostInterestAndNotVisited = currentSection;
          suggestedProject = interestedProjects.firstWhere((element) =>
              currentSectionProjects.any((p) => p.id == element.id));
        }
        if (suggestedProject == null) {
          double lowestRatio = double.infinity;
          Section? lowestRatioRoom;
          double highestRatio = -1;
          Section? highestRatioRoom;
          int totalProjectsInLowestRatio = 0;
          int totalProjectsInHighestRatio = 0;
          Set<Project> unvisitedFavoriteProjects = {};
          for (Section subsection in availableSections) {
            List<Project> projects = ProjectToSection.cache
                .where((projectToSection) =>
                    projectToSection.section.id == subsection.id &&
                    projectToSection.x != null &&
                    projectToSection.y != null &&
                    projectToSection.x != 0 &&
                    projectToSection.y != 0)
                .map((e) => e.project)
                .toList();
            projects = projects
                .where((element) =>
                    interestedProjects.contains(element) &&
                    !visitedProjects.contains(element))
                .toList();
            unvisitedFavoriteProjects.addAll(projects);
            if (subsection.id == currentSection!.id && projects.isNotEmpty) {
              targetRoomByMostInterestAndNotVisited = subsection;
              suggestedProject = projects.first;
              break;
            }
            if (projects.length > mostInterests) {
              targetRoomByMostInterestAndNotVisited = subsection;
              mostInterests = projects.length;
              if (projects.isNotEmpty) {
                suggestedProject = projects.first;
              }
            }
            if ((subsection.projects ?? []).length > 0 && projects.length > 0) {
              double ratio =
                  projects.length / (subsection.projects ?? []).length;
              if (ratio < lowestRatio) {
                totalProjectsInLowestRatio = projects.length;
                lowestRatio = ratio;
                lowestRatioRoom = subsection;
              }
              if (ratio > highestRatio) {
                totalProjectsInHighestRatio = projects.length;
                highestRatio = ratio;
                highestRatioRoom = subsection;
              }
            }
          }
          if (totalProjectsInLowestRatio - totalProjectsInHighestRatio <= 2 &&
              totalProjectsInLowestRatio >= 3) {
            if (lowestRatioRoom != null &&
                unvisitedFavoriteProjects.isNotEmpty) {
              List<Project> projectsInLowestRatioRoom =
                  unvisitedFavoriteProjects
                      .where((element) => ProjectToSection.cache.any(
                          (projectToSection) =>
                              projectToSection.section.id ==
                                  lowestRatioRoom!.id &&
                              projectToSection.project.id == element.id))
                      .toList();
              if (projectsInLowestRatioRoom.isNotEmpty) {
                suggestedProject = projectsInLowestRatioRoom.first;
              } else {
                suggestedProject = unvisitedFavoriteProjects.first;
              }
            }
          } else {
            if (highestRatioRoom != null &&
                unvisitedFavoriteProjects.isNotEmpty) {
              List<Project> projectsInHighestRatioRoom =
                  unvisitedFavoriteProjects
                      .where((element) => ProjectToSection.cache.any(
                          (projectToSection) =>
                              projectToSection.section.id ==
                                  highestRatioRoom!.id &&
                              projectToSection.project.id == element.id))
                      .toList();
              if (projectsInHighestRatioRoom.isNotEmpty) {
                suggestedProject = projectsInHighestRatioRoom.first;
              } else {
                suggestedProject = unvisitedFavoriteProjects.first;
              }
            }
          }
        }
      } else {
        int mostUnvisited = -1;
        List<Project> currentSectionProjects = [];
        if (currentSection!.projects != null &&
            currentSection!.projects!.isNotEmpty) {
          currentSectionProjects = currentSection!.projects!
              .where((element) => !visitedProjects.contains(element))
              .toList();
        }
        if (currentSectionProjects.isNotEmpty) {
          targetRoomByMostInterestAndNotVisited = currentSection;
        } else {
          for (Section subsection in availableSections) {
            List<Project> projects = subsection.projects ?? [];
            projects = projects
                .where((element) => !visitedProjects.contains(element))
                .toList();
            if (projects.length > mostUnvisited) {
              targetRoomByMostInterestAndNotVisited = subsection;
              mostUnvisited = projects.length;
            }
          }
        }
      }
      if (targetRoomByMostInterestAndNotVisited != null &&
          suggestedProject == null &&
          targetRoomByMostInterestAndNotVisited.projects != null &&
          targetRoomByMostInterestAndNotVisited.projects!.isNotEmpty) {
        List<Project> targetRoomProjects = targetRoomByMostInterestAndNotVisited
            .projects!
            .where((element) => element.hasKnownLocation)
            .toList();
        if (visitedProjects.isNotEmpty) {
          targetRoomProjects = targetRoomProjects
              .where((element) => !visitedProjects.contains(element))
              .toList();
        }
        if (targetRoomProjects.isNotEmpty) {
          String pseudoMacOfDevice = StorageService.getPseudoMac();
          int pseudoMacOfDeviceInt = 2;
          try {
            int.tryParse(pseudoMacOfDevice, radix: 16) ?? DateTime.now().hour;
          } catch (e) {
            pseudoMacOfDeviceInt = DateTime.now().hour;
          }
          targetRoomProjects.shuffle(Random(pseudoMacOfDeviceInt));
          suggestedProject = targetRoomProjects.first;
        }
      }
      if (suggestedProject != null && currentSection != null) {
        targetProject = suggestedProject;
        connectTargetProject = true;
        Section? suggestedProjectSection;
        for (Section section in availableSections) {
          if (section.projects != null &&
              section.projects!.contains(suggestedProject)) {
            suggestedProjectSection = section;
            break;
          }
        }
        if (suggestedProjectSection != null &&
            suggestedProjectSection.id != currentSection!.id) {
          candidates =
              findTargetRoomVerticesFromSection(suggestedProjectSection);
        } else {
          candidates = findTargetProjectVerticesFromSection(
              currentSection!, suggestedProject!);
        }
      } else if (targetRoomByMostInterestAndNotVisited != null) {
        candidates = findTargetRoomVerticesFromSection(
            targetRoomByMostInterestAndNotVisited);
      } else {
        candidates = [];
      }
    }

    double oneMetreInPixels = 1 / currentSection!.innerMap.metresPerPixel;

    List<Vertex> top3ClosestVertices = [];
    Map<Vertex, double> verticesAndDistances = {};
    List<Vertex> destinationVs = [];
    List<Vertex> verticesHere = dijkstra!.allVertices;
    int numberOfVertices = verticesHere.length;
    for (var vertex in verticesHere) {
      double distance = getDistance(
          [x, y], [vertex.x * imageResizeRatio, vertex.y * imageResizeRatio]);
      if (distance < closestV) {
        if ((closestV * 1.6) > distance) {
          top3ClosestVertices = [vertex];
        } else if (oneMetreInPixels > 1 && distance < oneMetreInPixels * 2) {
          if (top3ClosestVertices.length >= 7) {
            top3ClosestVertices.removeLast();
          }
          top3ClosestVertices.insert(0, vertex);
        }
        closestVertex = vertex;
        closestV = distance;
        verticesAndDistances[vertex] = distance;
      }
      if (candidates
          .any((element) => element.toString() == vertex.id.toString())) {
        destinationVs.add(vertex);
        candidates = candidates
            .where((element) => element.toString() != vertex.id.toString())
            .toList();
        if (distance < closestCandidate) {
          destinationVertex = vertex;
          closestCandidate = distance;
        }
      }
      if (numberOfVertices > 100 && distance * metresPerPixel < 0.6) {
        break;
      }
    }

    if (toClosestVertex && closestVertex != null) {
      userLocation = [closestVertex!.x.toDouble(), closestVertex!.y.toDouble()];
    }

    Vertex? closestVertexToClosestBeacon;
    double closestBeaconDistance = double.infinity;

    if (closestBeacon != null && fromClosestBeacon) {
      if (currentSection!.subsections.isEmpty) {
        candidateVs = dijkstra!.vertices;
        usefulDevices = [];
      } else {
        candidateVs = findBestStartPositionBasedOnNetworkDeviceRanges(
            devicesCandidates, verticesHere, closestBeacon!, metresPerPixel);
      }
      bool withinIntersections = usefulDevices.length > 1;
      double furthestCandidateVertexFromClosestBeacon = 0;
      double closesstCandidateVertexFromClosestBeaconWithinIntersections =
          double.infinity;
      for (var vertex in candidateVs) {
        double distance = getDistance([
          closestBeacon!.locationX! * imageResizeRatio,
          closestBeacon!.locationY! * imageResizeRatio
        ], [
          vertex.x * imageResizeRatio,
          vertex.y * imageResizeRatio
        ]);
        if (distance < closestBeaconDistance) {
          closestVertexToClosestBeacon = vertex;
          closestBeaconDistance = distance;
        }
        if (withinIntersections) {
          if (distance > furthestCandidateVertexFromClosestBeacon) {
            furthestCandidateVertexFromClosestBeacon = distance;
            closestVertex = vertex;
            closestVertexToClosestBeacon = vertex;
          }
        } else {
          if (distance <
              closesstCandidateVertexFromClosestBeaconWithinIntersections) {
            closesstCandidateVertexFromClosestBeaconWithinIntersections =
                distance;
            closestVertex = vertex;
            closestVertexToClosestBeacon = vertex;
          }
        }
      }

      if (closestVertexToClosestBeacon != null) {
        closestVertex = closestVertexToClosestBeacon;
        top3ClosestVertices = [closestVertex!];
        userLocation = [
          closestVertex!.x.toDouble(),
          closestVertex!.y.toDouble()
        ];
      }
    }

    if (fromClosestBeacon && closestVertexToClosestBeacon == null) {
      Fluttertoast.showToast(
        msg:
            "No beacons detected from your current location - Cannot suggest path",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    fromClosestBeacon = false;

    double closestX = userLocation[0];
    double closestY = userLocation[1];

    if (closestVertex != null) {
      closestX = closestVertex!.x.toDouble();
      closestY = closestVertex!.y.toDouble();
    }

    candidates.forEach((element) {
      if (Vertex.vertexCache.any((element2) => element2.id == element)) {
        Vertex vertex =
            Vertex.vertexCache.firstWhere((element2) => element2.id == element);
        if (!verticesHere.any((element2) => element2.id == vertex.id)) {
          return;
        }
        destinationVs.add(vertex);
        double distance = getDistance([closestX, closestY],
            [vertex.x * imageResizeRatio, vertex.y * imageResizeRatio]);
        if (distance < closestCandidate) {
          destinationVertex = vertex;
          closestCandidate = distance;
        }
      }
    });

    List<Vertex> newDestinationVs = [];
    double closestCandidateMax = closestCandidate * 1.2 / imageResizeRatio;
    if (destinationVertex != null) {
      for (Vertex destinationV in destinationVs) {
        double distanceOfV =
            getDistance([closestX, closestY], [destinationV.x, destinationV.y]);
        if (distanceOfV < closestCandidateMax) {
          newDestinationVs.add(destinationV);
        }
      }
    }
    destinationVs = newDestinationVs;

    if (top3ClosestVertices.isEmpty && closestVertex != null) {
      top3ClosestVertices = [closestVertex!];
    }

    if (!(closestVertex == null || destinationVertex == null) &&
        verticesHere.isNotEmpty &&
        edges.isNotEmpty &&
        dijkstra != null) {
      // var startTime = DateTime.now();
      quickestPath = double.infinity;

      top3ClosestVertices = [closestVertex!];
      if (destinationVs.isEmpty) {
        destinationVs = [destinationVertex!];
      }

      activeService.updateClickUsages(
          DestinationSetting.getDescription(destinationSetting).trim());

      if (x > 0.5 && y > 0.5) {
        bool breakAll = false;
        for (Vertex vertex in top3ClosestVertices) {
          if (breakAll) {
            break;
          }
          for (Vertex destinationV in destinationVs) {
            if (vertex != destinationV) {
              List<Vertex> routeVertices =
                  dijkstra!.calculateShortestPath(vertex, destinationV);
              double pathLength = 0;
              for (int i = 0; i < routeVertices.length - 1; i++) {
                pathLength += getDistance(
                    [routeVertices[i].x, routeVertices[i].y],
                    [routeVertices[i + 1].x, routeVertices[i + 1].y]);
              }
              if (routeVertices.isNotEmpty) {
                pathLength += verticesAndDistances[routeVertices.first] ?? 0;
              }
              if (pathLength < quickestPath! && pathLength > 0) {
                quickestPath = pathLength;
                pathVertices = routeVertices;
                closestVertex = vertex;
              } else if (pathVertices.isEmpty) {
                pathVertices = routeVertices;
              }
            } else {
              pathVertices = [vertex];
              quickestPath = 0;
              closestVertex = vertex;
              breakAll = true;
              break;
            }
          }
        }

        // var endTime = DateTime.now();
        // print(
        //     "Dijkstra took ${endTime.difference(startTime).inMilliseconds}ms");
      } else if (destinationVertex != null) {
        pathVertices = [destinationVertex!];
      } else {
        pathVertices = [];
      }
    } else if (destinationVertex != null &&
        destinationVertex == closestVertex) {
      pathVertices = [destinationVertex!];
    } else {
      pathVertices = [];
    }
    updateColors();
  }

  void updateColors() {
    Map<String, Color> newColors = {};
    if (beaconColors.isNotEmpty) {
      return;
    }
    newColors["CD:63:12:C4:DA:2D"] = Colors.lightBlue;
    newColors["C8:09:41:E3:C2:BD"] = const Color.fromARGB(255, 6, 56, 97);
    newColors["E4:23:CC:66:85:E7"] = Colors.lightGreen;
    newColors["D9:AD:1D:4F:88:E9"] = Colors.yellow;
    newColors["NONE"] = Colors.purple;
    beaconColors = newColors;
  }

  String getDestination() {
    String toReturn = "Default";
    if (destinationSetting == DestinationSetting.BEACON) {
      toReturn = "Closest Beacon";
    } else if (destinationSetting == DestinationSetting.CLOSEST_ROOM) {
      toReturn = "Closest Room With Projects";
    } else if (destinationSetting == DestinationSetting.PROJECT) {
      toReturn = "Project: ${targetProject?.projectName ?? "None"}";
    } else if (destinationSetting == DestinationSetting.ROOM) {
      toReturn = "Room: ${targetSection?.sectionName ?? "None"}";
    } else if (destinationSetting == DestinationSetting.EXIT) {
      toReturn = "Exit";
    }
    toReturn = toReturn.trim();
    toReturn =
        toReturn.length > 25 ? toReturn.substring(0, 25) + "..." : toReturn;
    return toReturn;
  }

  late int newDestinationSetting = destinationSetting;

  openDestinationDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                      20.0,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.only(
                  top: 10.0,
                ),
                title: const Text(
                  "Set Destination",
                  style: TextStyle(fontSize: 24.0),
                ),
                content: Container(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: newDestinationSetting,
                            onChanged: (int? newValue) {
                              setDialogState(() {
                                newDestinationSetting = newValue!;
                              });
                              setDialogState(() {});
                            },
                            items: DestinationSetting.getOptions()
                                .map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(
                                    DestinationSetting.getDescription(value)),
                              );
                            }).toList(),
                          ),
                        ),
                        getRoutePlanningWidgets(
                            newDestinationSetting, setDialogState),
                        Container(
                          width: double.infinity,
                          height: 60,
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                destinationSetting = newDestinationSetting;
                                StorageService.instance.setInt(
                                    "destinationSetting", destinationSetting);
                                if (destinationSetting ==
                                    DestinationSetting.PROJECT) {
                                  targetProject = newTargetProject;
                                  StorageService.instance.setInt(
                                      "targetProjectId",
                                      (targetProject?.id ?? -1));
                                } else if (destinationSetting ==
                                    DestinationSetting.ROOM) {
                                  targetSection = newTargetSection;
                                  StorageService.instance.setInt(
                                      "targetSectionId",
                                      (targetSection?.id ?? -1));
                                }
                              });
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              // fixedSize: Size(250, 50),
                            ),
                            child: const Text(
                              "SET DESTINATION",
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 60,
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              newDestinationSetting = destinationSetting;
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              // fixedSize: Size(250, 50),
                            ),
                            child: const Text(
                              "CANCEL",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }).then((value) {
      if (mounted) {
        afterProfilePage();
      }
    });
  }

  getRoutePlanningWidgets(int destinationSetting, StateSetter setDialogState) {
    switch (destinationSetting) {
      case DestinationSetting.BEACON:
        return beaconWidgets();
      case DestinationSetting.CLOSEST_ROOM:
        return closestRoomWidgets();
      case DestinationSetting.PROJECT:
        return projectWidgets(setDialogState);
      case DestinationSetting.ROOM:
        return roomWidgets(setDialogState);
      case DestinationSetting.EXIT:
        return exitWidgets();
      default:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              child: const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "This is the default route planning option. It will take you to the location which has the most projects that you have marked as interested. If you have no projects marked as interests, you will be to the room with the most projects.",
                style: TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
    }
  }

  exitWidgets() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: const Text('Description',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "This will direct you to the nearest exit.",
            style: TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  beaconWidgets() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: const Text('Description'),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "This will direct you to the closest beacon.",
            style: TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  closestRoomWidgets() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: const Text('Description',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "This setting will find the closest room with projects and navigate to it. If there are no rooms with projects, it will navigate to the closest area.",
            style: TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Project? newTargetProject;

  projectWidgets(StateSetter setDialogState) {
    List<Project> projects = getProjects();
    projects = projects
        .where((element) => element.roomLocation != Project.UNKNOW_LOCATION)
        .toList();
    projects.sort((a, b) =>
        a.projectName.toLowerCase().compareTo(b.projectName.toLowerCase()));
    if (newTargetProject == null) {
      newTargetProject = projects.isEmpty ? null : projects[0];
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(3.0),
          child: DropdownButton<Project>(
            itemHeight: null,
            isExpanded: true,
            value: (newTargetProject ??
                (projects.isNotEmpty ? projects[0] : null)),
            onChanged: (Project? newValue) {
              setDialogState(() {
                newTargetProject = newValue!;
              });
            },
            items: projects.map<DropdownMenuItem<Project>>((Project value) {
              return DropdownMenuItem<Project>(
                value: value,
                child: ListTile(
                    title: Text(value.projectName,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(value.projectOwner,
                        overflow: TextOverflow.ellipsis),
                    trailing: Opacity(
                      opacity: StorageService.interestsContainId(value.id ?? -1)
                          ? 1
                          : 0,
                      child: const Icon(
                        Icons.star,
                        color: Colors.yellow,
                      ),
                    )),
              );
            }).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          child: const Text('Description',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "This setting will navigate to the project you select.",
            style: TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Project> getProjects() {
    return ActiveService.instance.projectList;
  }

  Section? newTargetSection;

  roomWidgets(StateSetter setDialogState) {
    List<Section> rooms = getRooms();
    if (newTargetSection == null) {
      newTargetSection = rooms.isNotEmpty ? rooms[0] : null;
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<Section>(
            isExpanded: true,
            value: (newTargetSection ?? (rooms.isNotEmpty ? rooms[0] : null)),
            onChanged: (Section? newValue) {
              setDialogState(() {
                newTargetSection = newValue!;
              });
            },
            items: rooms.map<DropdownMenuItem<Section>>((Section value) {
              return DropdownMenuItem<Section>(
                value: value,
                child: Text(value.sectionName),
              );
            }).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          child: const Text('Description',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "This setting will navigate to the area you select.",
            style: TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Section> getRooms() {
    return availableSections;
  }

  List<String> findTargetProjectVerticesFromSection(
      Section section, Project project) {
    if (currentSection != null && !currentSection!.containsProject(project)) {
      List<String> exitsOfSection =
          httpService.exitsBySectionId[currentSection!.id.toString()] ?? [];
      return exitsOfSection;
    }
    if (projectsToSectionsHere
        .any((element) => element.project.id == project.id)) {
      ProjectToSection projectToSection = projectsToSectionsHere
          .where((element) => element.project.id == project.id)
          .first;
      Section sectionOfProject = projectToSection.section;
      if (section.id == sectionOfProject.id) {
        List<Vertex> sectionVertices =
            dijkstra == null ? [] : dijkstra!.allVertices;
        if (sectionVertices.isEmpty) {
          return [];
        }

        Vertex closestVertex = sectionVertices[0];
        double closestDistance = double.infinity;
        for (Vertex vertex in sectionVertices) {
          double distance = getDistance(
              [projectToSection.x, projectToSection.y], [vertex.x, vertex.y]);
          if (distance < closestDistance) {
            closestDistance = distance;
            closestVertex = vertex;
          }
        }
        return [closestVertex.id];
      }
    }
    List<String> vertices = [];
    List<Section> allSubsections = section.getAllSubsections();
    for (Section subsection in allSubsections) {
      if (subsection.containsProject(project)) {
        List<String> subsectionVertices =
            httpService.doorsBySectionId[subsection.id.toString()] ?? [];
        for (String subsectionVertex in subsectionVertices) {
          if (!vertices.contains(subsectionVertex)) {
            vertices.add(subsectionVertex);
          }
        }
      }
    }
    if (vertices.isEmpty) {
      if (Section.cache
          .any((element) => element.subsections.contains(section))) {
        Section parentSection = Section.cache
            .firstWhere((element) => element.subsections.contains(section));
        if (parentSection.id != section.id) {
          vertices =
              findTargetProjectVerticesFromSection(parentSection, project);
        }
      }
    }
    return vertices;
  }

  List<String> findTargetRoomVerticesFromSection(Section section) {
    if (currentSection == null) {
      return [];
    }
    if (section.id == currentSection!.id) {
      return [];
    }
    if (!currentSection!.containsSection(section)) {
      return httpService.exitsBySectionId[currentSection!.id.toString()] ?? [];
    }
    List<String> vertices = [];
    for (Section subsection in availableSections) {
      if (subsection.containsSection(section)) {
        List<String> subsectionVertices =
            httpService.doorsBySectionId[subsection.id.toString()] ?? [];
        for (String subsectionVertex in subsectionVertices) {
          if (!vertices.contains(subsectionVertex)) {
            vertices.add(subsectionVertex);
          }
        }
      } else if (section.containsSection(subsection)) {
        List<String> exitIds =
            httpService.exitsBySectionId[subsection.id.toString()] ?? [];
        for (String exitId in exitIds) {
          if (!vertices.contains(exitId)) {
            vertices.add(exitId);
          }
        }
      }
    }
    return vertices;
  }

  Route _createRoute(target) {
    return PageRouteBuilder(
      transitionDuration: const Duration(seconds: 1),
      pageBuilder: (context, animation, secondaryAnimation) => target,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Color getBeaconColor(String name) {
    name = name.toLowerCase();
    Color beaconColor = Colors.blue;
    if (name.contains("green")) {
      beaconColor = Colors.green;
    } else if (name.contains("blue")) {
      if (name.contains("dark")) {
        beaconColor = Color.fromARGB(255, 11, 66, 112);
      } else {
        beaconColor = Colors.blue;
      }
    } else if (name.contains("white")) {
      beaconColor = Colors.yellow;
    }
    return beaconColor;
  }
}

double getDistance(p1, p2) {
  double distance =
      (sqrt(pow((p1[0] - p2[0]), 2) + pow((p1[1] - p2[1]), 2))).abs();
  return distance;
}

List<AccessPoint> getBeaconExamples() {
  return beaconFromJson("""[
    {"name": "Mint Cocktail",
        "uuids": ["ebd21ab7-c471-770b-e4df-70ee82026a17"],
        "identifier": "",
        "macAddress": "C2:05:31:8F:61:7E",
        "locationX": 405,
        "locationY": 55,
        "venues": ["UCC"]
    },
    {"name": "Icy Marshmallow",
        "uuids": ["c9ad67d9-0f82-40ac-b097-46c5ce31fe84"],
        "identifier": "",
        "macAddress": "EA:39:DA:A4:12:A0",
        "locationX": 150,
        "locationY": 195,
        "venues": ["UCC"]
    },
     {"name": "Mint",
        "uuids": ["efajfeao-0f82-40ac-b097-46c5ce31fe84"],
        "identifier": "",
        "macAddress": "BF:39:DA:A4:12:A0",
        "locationX": 410,
        "locationY": 240,
        "venues": ["UCC"]
    }
]""");
}

Future<ui.Size> _calculateImageDimension(Image image) {
  Completer<ui.Size> completer = Completer();
  image.image.resolve(const ImageConfiguration()).addListener(
    ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        var myImage = image.image;
        ui.Size size =
            ui.Size(myImage.width.toDouble(), myImage.height.toDouble());
        completer.complete(size);
      },
    ),
  );
  return completer.future;
}

class MyPainter extends CustomPainter {
  List<Offset> points;

  MyPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    const pointMode = ui.PointMode.polygon;
    final List<Offset> points = [];
    points.addAll(this.points);

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(pointMode, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return false;
  }
}

double getDeviceEstimation(NetworkDevice device) {
  // based off of:
  // https://reprage.com/posts/2014-07-07-how-accurate-are-estimote-ibeacons/
  double distance = 0.0;
  try {
    distance = double.parse(device.distance!);
  } catch (e) {
    return 0;
  }
// 1.0m 	+/- 0.1m
// 2.0m 	+/- 1.1m
// 3.0m 	+/- 0.9m
// 4.0m 	+/- 0.9m
// 5.0m 	+/- 1.6m
// 6.0m 	+/- 2.3m
// 7.0m 	+/- 1.7m
// 8.0m 	+/- 2.0m
  if (distance < 1) {
    return distance + 0.1;
  }
  if (distance < 2) {
    return distance + 1.1;
  }
  if (distance < 3) {
    return distance + 0.9;
  }
  if (distance < 4) {
    return distance + 0.9;
  }
  if (distance < 5) {
    return distance + 1.6;
  }
  if (distance < 6) {
    return distance + 2.3;
  }
  if (distance < 7) {
    return distance + 1.7;
  }
  if (distance < 8) {
    return distance + 2.0;
  }
  return distance + 3;
  // if (distance < 1) {
  //   return distance + 0.5;
  // }
  // if (distance < 4) {
  //   return distance + 1.5;
  // }
  // if (distance < 6) {
  //   return distance + 2.5;
  // }
  // if (distance < 8) {
  //   return distance + 3.5;
  // }
  // return distance + 5.0;
  // if (distance < 1) {
  //   return distance + 0.8;
  // }
  // if (distance < 3) {
  //   return distance + 1.5;
  // }
  // if (distance < 5) {
  //   return distance + 2;
  // }
  // return distance + 3;
}

List<Vertex> findBestStartPositionBasedOnNetworkDeviceRanges(
    List<NetworkDevice> networkDevices,
    List<Vertex> vertices,
    AccessPoint closestNetworkDevice,
    double metresInPixels) {
  List<NetworkDevice> candidateNetworkDevices = [];
  for (NetworkDevice networkDevice in networkDevices) {
    if (networkDevice.distance != null) {
      candidateNetworkDevices.add(networkDevice);
    }
  }
  List<Vertex> candidateVertices = [];
  int mostIntersections = 0;
  int mostIntersectionsWithClosest = 0;
  List<Vertex> bestVertices = [];
  for (Vertex vertex in vertices) {
    int total = 0;
    //int totalClosest = 0;
    bool withinClosest = false;
    for (NetworkDevice networkDevice in candidateNetworkDevices) {
      if (networkDevice.distance != null &&
          networkDevice.relatedAP != null &&
          networkDevice.relatedAP!.locationX != null &&
          networkDevice.relatedAP!.locationY != null) {
        bool isClosest = networkDevice.relatedAP!.macAddress ==
            closestNetworkDevice.macAddress;
        double deviceDistance = getDeviceEstimation(networkDevice);
        if (isClosest) {
          deviceDistance = deviceDistance + 1.5;
        }
        double distance = deviceDistance / metresInPixels;
        List<int> p1 = [vertex.x, vertex.y];
        List<int> p2 = [
          networkDevice.relatedAP!.locationX!,
          networkDevice.relatedAP!.locationY!
        ];
        double distanceBetweenPoints = getDistance(p1, p2);
        if (distanceBetweenPoints <= distance) {
          total++;
          if (isClosest) {
            withinClosest = true;
          }
        }
      }
    }
    if (total > mostIntersections) {
      candidateVertices = [vertex];
      mostIntersections = total;
    } else if (total == mostIntersections) {
      candidateVertices.add(vertex);
    }
    if (withinClosest) {
      if (total > mostIntersectionsWithClosest) {
        bestVertices = [vertex];
        mostIntersectionsWithClosest = total;
      } else if (total == mostIntersectionsWithClosest) {
        bestVertices.add(vertex);
      }
    }
  }
  if (bestVertices.length > 0) {
    return bestVertices;
  }
  return candidateVertices;
}
