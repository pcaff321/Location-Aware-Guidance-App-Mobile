import 'dart:async';

import 'package:tradeshow_guidance_app/models/project.dart';
import 'package:tradeshow_guidance_app/models/section.dart';
import 'package:tradeshow_guidance_app/models/site.dart';
// import 'package:wifi_hunter/wifi_hunter_result.dart';

import '../models/network_device.dart';
import '../models/received_beacon_data.dart';

class ActiveService {
  static final ActiveService instance = ActiveService._();

  ActiveService._();

  static getService() {
    return instance;
  }

  final StreamController<bool> _updateMapView =
      StreamController<bool>.broadcast();

  Stream<bool> get updateMapViewStream => _updateMapView.stream;

  void updateMapView(bool updateMapView) {
    _updateMapView.sink.add(updateMapView);
  }

  bool loadingSite = false;

  final StreamController<bool> _loadingSiteController =
      StreamController<bool>.broadcast();

  Stream<bool> get loadingSiteStream => _loadingSiteController.stream;

  void setLoadingSite(bool loadingSite) {
    this.loadingSite = loadingSite;
    _loadingSiteController.sink.add(loadingSite);
  }

  List<ReceivedBeaconData> receivedBeaconDataList = [];

  final StreamController<List<ReceivedBeaconData>>
      _receivedBeaconDataListController =
      StreamController<List<ReceivedBeaconData>>.broadcast();

  Stream<List<ReceivedBeaconData>> get receivedBeaconDataListStream =>
      _receivedBeaconDataListController.stream;

  void updateReceivedBeaconDataList(
      List<ReceivedBeaconData> receivedBeaconDataList) {
    this.receivedBeaconDataList = receivedBeaconDataList;
    _receivedBeaconDataListController.sink.add(receivedBeaconDataList);
  }

  final StreamController<bool> updateBackgroundIsolateController =
      StreamController<bool>.broadcast();

  Stream<bool> get updateBackgroundIsolateStream =>
      updateBackgroundIsolateController.stream;

  void updateBackgroundIsolate(bool updateBackgroundIsolate) {
    updateBackgroundIsolateController.sink.add(updateBackgroundIsolate);
  }

  final StreamController<String> _clickUsagesController =
      StreamController<String>.broadcast();

  Stream<String> get clickUsagesStream => _clickUsagesController.stream;

  void updateClickUsages(String clickUsages) {
    _clickUsagesController.sink.add(clickUsages);
  }

  final StreamController<Map<String, int>> _usageTimeController =
      StreamController<Map<String, int>>.broadcast();

  Stream<Map<String, int>> get usageTimeStream => _usageTimeController.stream;

  void updateUsageTime(Map<String, int> usageTime) {
    _usageTimeController.sink.add(usageTime);
  }

  List<NetworkDevice> networkDeviceList = [];

  final StreamController<List<NetworkDevice>> _networkDeviceListController =
      StreamController<List<NetworkDevice>>.broadcast();

  Stream<List<NetworkDevice>> get networkDeviceListStream =>
      _networkDeviceListController.stream;

  void updateNetworkDeviceList(List<NetworkDevice> networkDeviceList) {
    this.networkDeviceList = networkDeviceList;
    _networkDeviceListController.sink.add(networkDeviceList);
  }

  final StreamController<List<Project>> _projectListController =
      StreamController<List<Project>>.broadcast();

  Stream<List<Project>> get projectListStream => _projectListController.stream;

  List<Project> projectList = [];

  void updateProjectList(List<Project> projectList) {
    this.projectList = projectList;
    _projectListController.sink.add(projectList);
  }

  final StreamController<List<double>> _userPositionController =
      StreamController<List<double>>.broadcast();

  Stream<List<double>> get userPositionStream => _userPositionController.stream;
  List<double> userPosition = [0, 0];

  void updateUserPosition(List<double> userPositionNew) {
    userPosition = userPositionNew;
    _userPositionController.sink.add(userPositionNew);
  }

  Stream<Section?> get visitedSectionStream => _visitedSectionController.stream;
  final StreamController<Section?> _visitedSectionController =
      StreamController<Section?>.broadcast();

  void suggestMarkAllProjectsWithinSectionAsVisited(Section? section) {
    if (section == null) {
      return;
    }
    _visitedSectionController.sink.add(section);
  }

  final StreamController<Section?> _currentSectionController =
      StreamController<Section?>.broadcast();
  Stream<Section?> get currentSectionStream => _currentSectionController.stream;
  Section? currentSection = null;

  int timeOfLastSectionUpdate = 0;

  void updateCurrentSection(Section? currentSectionNew) {
    int timeNow = DateTime.now().millisecondsSinceEpoch;
    int timeSpan = 5 * 60 * 1000; // 5 minutes in milliseconds
    if (timeOfLastSectionUpdate != 0 &&
        timeNow - timeOfLastSectionUpdate > timeSpan) {
      this.suggestMarkAllProjectsWithinSectionAsVisited(this.currentSection);
    }
    timeOfLastSectionUpdate = timeNow;
    currentSection = currentSectionNew;
    _currentSectionController.sink.add(currentSectionNew);
  }

  final StreamController<List<Section>> _availableSectionsController =
      StreamController<List<Section>>.broadcast();

  Stream<List<Section>> get availableSectionsStream =>
      _availableSectionsController.stream;
  List<Section> availableSections = [];

  void updateAvailableSections(List<Section> availableSectionsNew) {
    availableSections = availableSectionsNew;
    _availableSectionsController.sink.add(availableSectionsNew);
  }

  List<Site> activeSites = [];

  Stream<Site> get activeSiteStream => _activeSiteController.stream;
  final StreamController<Site> _activeSiteController =
      StreamController<Site>.broadcast();

  Site? activeSite;

  void updateActiveSite(Site activeSite) {
    _activeSiteController.sink.add(activeSite);
    activeSite = activeSite;
  }

  void dispose() {
    _receivedBeaconDataListController.close();
    _networkDeviceListController.close();
    _projectListController.close();
    _userPositionController.close();
  }
}
