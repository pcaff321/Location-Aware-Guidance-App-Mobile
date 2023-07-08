import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:tradeshow_guidance_app/models/section.dart';
import 'package:tradeshow_guidance_app/models/network_device.dart';
import 'package:tradeshow_guidance_app/services/activeService.dart';
import 'package:tradeshow_guidance_app/services/httpService.dart';
import 'package:tradeshow_guidance_app/services/networkDevicePulseService.dart';
import 'package:tradeshow_guidance_app/views/home_view.dart';
import 'package:tradeshow_guidance_app/views/mapView.dart';
import 'package:tradeshow_guidance_app/views/list_of_network_devices.dart';
import 'package:tradeshow_guidance_app/views/list_of_projects.dart';
import 'package:tradeshow_guidance_app/views/settings_page.dart';
import 'package:tradeshow_guidance_app/widgets/visitedProjectsDialog.dart';
import 'models/access_point.dart';
import 'services/storageService.dart';
//import 'package:flutter_isolate/flutter_isolate.dart';

final Map<String, String> _titlesOfFeatures = <String, String>{
  "0": "Home",
  "1": "Map",
  "2": "Projects",
  "3": "NetworkDevices",
  "4": "Settings",
};

@pragma('vm:entry-point')
void isolate1(SendPort sendPort) async {
  NetworkDeviceService ndser = NetworkDeviceService.getService();
  await StorageService.init();
  bool inBackground =
      StorageService.getString("scanOnlyWhenInApp") == "false" ? false : true;
  inBackground = false;
  ndser.initBeaconService(inBackground);

  await Future.delayed(const Duration(seconds: 3));
  bool locationUpdates =
      StorageService.getString("locationUpdates") == "false" ? false : true;
  bool updatingBools = false;
  ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  receivePort.listen((message) async {
    updatingBools = true;
    bool newLocationUpdates = locationUpdates;
    if (message.toString().substring(0, 6) == "update") {
      String bools = message.toString().substring(6);
      List<String> boolList = bools.split(",");
      newLocationUpdates = boolList[0] == "false" ? false : true;
      inBackground = boolList[1] == "false" ? false : true;
    }
    inBackground = false;
    if (locationUpdates != newLocationUpdates) {
      locationUpdates = newLocationUpdates;
      if (locationUpdates) {
        await ndser.initBeaconService(inBackground);
      } else {
        await ndser.stopBeaconService();
      }
    }
    updatingBools = false;
  });
  if (locationUpdates) {
    inBackground = false;
    await ndser.initBeaconService(inBackground);
  }

  bool restartingBluetooth = false;
  
  Timer.periodic(const Duration(seconds: 7), (timer) {
    if (updatingBools || !locationUpdates || restartingBluetooth) {
      return;
    }
    ndser.huntNetworkDevices().then((value) => {
          sendPort.send(value),
        });
  });


  Timer.periodic(const Duration(minutes: 14), (timer) async {
    if (restartingBluetooth) {
      return;
    }
    if (updatingBools) {
      await Future.delayed(const Duration(seconds: 5));
    }
    if (!locationUpdates) {
      return;
    }
    restartingBluetooth = true;
    await ndser.stopBeaconService();
    await Future.delayed(const Duration(seconds: 5));
    await ndser.initBeaconService(inBackground);
    restartingBluetooth = false;
  });
}

final List<Widget> _widgetOptions = <Widget>[
  //Index 0
  Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: const HomeView()),
  //Index 1
  Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Map'),
        centerTitle: true,
      ),
      body: const MapView()),
  //Index 2
  Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Projects'),
        centerTitle: true,
      ),
      body: const ListOfProjects()),
  // Index 3
  Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Network Devices'),
        centerTitle: true,
      ),
      body: const ListOfNetworkDevices()),
  // Index 4
  Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: const SettingsPage()),
];

Map<String, int> usageClicks = {};
Map<String, int> usageTime = {};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  ActiveService activeService = ActiveService.instance;

  Map<String, dynamic>? savedUsageTime = StorageService.getMap("usageTime");
  if (savedUsageTime != null) {
    for (String key in savedUsageTime.keys) {
      try {
        usageTime[key] = savedUsageTime[key];
      } catch (e) {
        usageTime[key] = 0;
      }
    }
  }

  Map<String, dynamic>? savedUsageClicks = StorageService.getMap("usageClicks");
  if (savedUsageClicks != null) {
    for (String key in savedUsageClicks.keys) {
      try {
        usageClicks[key] = savedUsageClicks[key];
      } catch (e) {
        usageClicks[key] = 0;
      }
    }
  }

  activeService.clickUsagesStream.listen((feature) {
    usageClicks[feature] = (usageClicks[feature] ?? 0) + 1;
  });

  activeService.usageTimeStream.listen((featureMappedToSecond) {
    String feature = featureMappedToSecond.keys.first;
    usageTime[feature] =
        (usageTime[feature] ?? 0) + featureMappedToSecond[feature]!;
  });

  Map<String, int> usageLastTime = {};

  Timer.periodic(Duration(seconds: 15), (timer) {
    StorageService.saveMap("usageTime", usageTime);
    StorageService.saveMap("usageClicks", usageClicks);
  });

  Timer.periodic(Duration(seconds: 30), (timer) {
    String pseudoMac = StorageService.getPseudoMac();
    List<Map<String, dynamic>> featuresToSend = [];
    usageTime.forEach((key, value) {
      if (value > 0) {
        if (usageLastTime[key] != null && usageLastTime[key]! >= value) {
          return;
        }
        Map<String, dynamic> feature = {};
        feature["featureName"] = key;
        if (feature["featureName"] == null) {
          return;
        }
        feature["usageCountInSeconds"] = value.toString();
        usageLastTime[key] = value;
        featuresToSend.add(feature);
      }
    });
    usageClicks.forEach((key, value) {
      if (value > 0) {
        String newKey = (_titlesOfFeatures[key] ?? key) + "Click";
        if (usageLastTime[newKey] != null && usageLastTime[newKey]! >= value) {
          return;
        }
        Map<String, dynamic> feature = {};
        feature["featureName"] = newKey;
        if (feature["featureName"] == null) {
          return;
        }
        feature["usageCountInSeconds"] = value.toString();
        usageLastTime[newKey] = value;
        featuresToSend.add(feature);
      }
    });
    StorageService.saveMap("usageTime", usageTime);
    StorageService.saveMap("usageClicks", usageClicks);
    if (featuresToSend.length > 0) {
      HttpService.instance.updateUsage(pseudoMac, featuresToSend);
    }
  });

  ByteData data =
      await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
  SecurityContext.defaultContext
      .setTrustedCertificatesBytes(data.buffer.asUint8List());

  HttpOverrides.global = MyHttpOverrides();

  ReceivePort receivePort = ReceivePort();

  await FlutterIsolate.spawn<SendPort>(isolate1, receivePort.sendPort);

  StreamController<dynamic> backgroundIsolateStream =
      StreamController<dynamic>.broadcast();
  receivePort.listen((message) {
    backgroundIsolateStream.add(message);
  });
  SendPort sendPort = await backgroundIsolateStream.stream.first;

  activeService.updateBackgroundIsolateStream.listen((bool value) async {
    bool inBackground =
        StorageService.getString("scanOnlyInApp") == "false" ? true : false;
    bool locationUpdates =
        StorageService.getString("locationUpdates") == "false" ? false : true;
    sendPort.send(
        "update" + locationUpdates.toString() + "," + inBackground.toString());
  });

  backgroundIsolateStream.stream.listen((message) async {
    List<NetworkDevice> foundNetworkDevices =
        NetworkDevice.networkDevicesFromJson(message.toString());
    activeService.updateNetworkDeviceList(foundNetworkDevices);

    List<AccessPoint> accessPoints = AccessPoint.cache;

    foundNetworkDevices.forEach((element1) {
      List<NetworkDevice> relatedDevices = NetworkDevice.cache
          .where((element2) => element2.devicemac == element1.devicemac)
          .toList();
      for (var element in relatedDevices) {
        if (accessPoints.any((ap) {
          return ap.macAddress == element.devicemac;
        })) {
          element.relatedAP = accessPoints
              .firstWhere((ap) => ap.macAddress == element.devicemac);
        }
      }
    });
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // late final NotificationService notificationService;

  // void listenToNotificationStream() =>
  //     notificationService.behaviorSubject.listen((payload) {
  //       print('payload $payload');
  //     });

  MyApp({super.key});

  static const String _title = 'Tradeshow Guidance App';

  @override
  Widget build(BuildContext context) {
    // notificationService = NotificationService();
    // listenToNotificationStream();
    // notificationService.initializePlatformNotifications();

    return const MaterialApp(
      title: _title,
      color: Colors.black45,
      home: BottomNavigationWidget(),
    );
  }
}

class BottomNavigationWidget extends StatefulWidget {
  const BottomNavigationWidget({super.key});

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  int _selectedIndex = 0;

  @override
  void initState() {
    Timer.periodic(Duration(seconds: 7), (timer) {
      String? featureName = _titlesOfFeatures[_selectedIndex.toString()];
      if (featureName == null) return;
      usageTime[featureName] = (usageTime[featureName] ?? 0) + 1;
    });
    ActiveService.instance.visitedSectionStream.listen((section) {
      if (section == null) return;
      showVisitedProjectsDialog(context, section);
    });
    super.initState();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }
    usageClicks[index.toString()] = (usageClicks[index.toString()] ?? 0) + 1;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            backgroundColor: Colors.black87,
            label: 'Home',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.black87,
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.black87,
            icon: Icon(Icons.format_list_bulleted),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.black87,
            icon: Icon(Icons.wifi),
            label: 'Network Devices',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.black87,
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        backgroundColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
      ),
    );
  }

  showVisitedProjectsDialog(BuildContext context, Section section) {
    if (section.projects == null || section.projects!.isEmpty) return;
    showDialog(
        context: context,
        builder: (context) {
          return getVisitedProjectsDialog(context, section);
        });
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
