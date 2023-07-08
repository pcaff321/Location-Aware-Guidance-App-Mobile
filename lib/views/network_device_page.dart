import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:tradeshow_guidance_app/models/network_device.dart';
import 'package:tradeshow_guidance_app/models/site_map.dart';
import 'package:tradeshow_guidance_app/services/globals.dart';
import 'package:tradeshow_guidance_app/services/httpService.dart';
import 'package:tradeshow_guidance_app/views/profile_page.dart';

import '../models/project.dart';

class NetworkDevicePage extends StatefulWidget {
  NetworkDevicePage({super.key, required this.networkDevice});
  NetworkDevice networkDevice;

  @override
  _NetworkDevicePageState createState() =>
      _NetworkDevicePageState(networkDevice);
}

class _NetworkDevicePageState extends State<NetworkDevicePage> {
  _NetworkDevicePageState(this.networkDevice);
  NetworkDevice networkDevice;
  bool onServer = false;

  Project sampleProject = Project(-200);

  HttpService httpService = HttpService.instance;

  List<SiteMap> siteMaps = [];

  @override
  void initState() {
    siteMaps = httpService.siteMapsByNetworkDevices[networkDevice.id] ?? [];
    dropdownValue = siteMaps.isNotEmpty ? siteMaps[0] : null;
    super.initState();
  }

  TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    sampleProject.projectName = "Sample Project";
    sampleProject.projectDescription = "Sample Project Description";
    sampleProject.projectOwner = "Sample Project Owner";
    sampleProject.contactEmail = "Sample Project Owner Email";
    nameController.text = networkDevice.devicename;
    return MaterialApp(
      title: 'Network Device Information',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Text('Network Device Information'),
          centerTitle: true,
        ),
        body: ListView(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 0.9],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    height: 10,
                  ),
                  networkDevice.isbluetooth
                      ? const Icon(Icons.bluetooth,
                          size: 26, color: Colors.blue)
                      : const Icon(Icons.wifi, size: 26, color: Colors.green),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: (() {
                          Navigator.pop(context);
                        }),
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 16.0,
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        label: const Text('GO BACK',
                            style: TextStyle(color: Colors.white)), 
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                      'MAC Address: ${networkDevice.devicemac} + ${networkDevice.id}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                  Text('UUIDs: ${networkDevice.deviceuuids}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                      'Public: ${networkDevice.ispublic == true ? 'Yes' : 'No'}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                      'On Server: ${networkDevice.isOnServer == true ? 'Yes' : 'No'}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            networkDevice.isOnServer
                ? getServerWidgets(networkDevice, context)
                : const SizedBox(),
          ],
        ),
        floatingActionButton: networkDevice.isOnServer
            ? FloatingActionButton.extended(
                backgroundColor: Colors.red,
                label: const Text('SEND UPDATE TO SERVER'),
                onPressed: () {
                  if (networkDevice.devicename != nameController.text) {
                    networkDevice.devicename = nameController.text;
                    submitDeviceToServer(networkDevice);
                  }
                },
              )
            : FloatingActionButton.extended(
                backgroundColor: Colors.black87,
                label: const Text('ADD TO SERVER'),
                onPressed: () {
                  networkDevice.devicename = nameController.text;
                  submitDeviceToServer(networkDevice);
                },
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget getServerWidgets(NetworkDevice networkDevice, BuildContext context) {
    return Column(
      children: <Widget>[
        getAssociatedMapsWidget(networkDevice, context),
        const SizedBox(
          height: 10,
        ),
        //getAssociatedProjectsWidget(networkDevice, context),
      ],
    );
  }

  getAssociatedProjectsWidget(
      NetworkDevice networkDevice, BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(
          height: 10,
        ),
        const Text('Associated Projects',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            )),
        const SizedBox(
          height: 10,
        ),
        SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Container(
            height: 250,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 10,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ListTile(
                    title: Text("GET ASSOCITED PROJECTS TITLE"),
                    subtitle: Text("DESCRIPTION"),
                    onTap: () => {
                      Navigator.of(context).push(
                          _createRoute(ProfilePage(project: sampleProject)))
                    },
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  SiteMap? dropdownValue;

  getAssociatedMapsWidget(
      NetworkDevice networkDevice, BuildContext buildContext) {
    return Column(children: <Widget>[
      const SizedBox(
        height: 10,
      ),
      const Text('Associated Maps',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          )),
      const SizedBox(
        height: 10,
      ),
      DropdownButton<SiteMap>(
        value: dropdownValue,
        icon: const Icon(Icons.arrow_downward_sharp),
        iconSize: 24,
        elevation: 16,
        style: const TextStyle(
          color: Colors.deepPurple,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        underline: Container(
          height: 2,
          color: Colors.deepPurpleAccent,
        ),
        onChanged: (SiteMap? newValue) {
          setState(() {
            dropdownValue = newValue!;
          });
        },
        items: siteMaps.map<DropdownMenuItem<SiteMap>>((SiteMap value) {
          return DropdownMenuItem<SiteMap>(
            value: value,
            child: Text(value.mapname),
          );
        }).toList(),
      ),
      getMapImage(dropdownValue)
    ]);
  }

  getMapImage(SiteMap? dropdownValue) {
    if (dropdownValue == null) {
      return const Text("No Map Selected");
    }
    return Image.memory(Globals.getMapImage(dropdownValue.mapimage!).bytes);
  }

  void submitDeviceToServer(NetworkDevice device) async {
    Response response = await httpService.submitForm(
        device.toJson(), HttpService.BASE_URL + 'networkdevices');
    if (response.statusCode == 200 || response.statusCode == 201) {
      device.id = json.decode(response.body)['id'].toString();
      if (mounted) {
        setState(() {});
      }
    }
  }
}

Route _createRoute(target) {
  return PageRouteBuilder(
    transitionDuration: const Duration(seconds: 1),
    pageBuilder: (context, animation, secondaryAnimation) => target,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
