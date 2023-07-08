import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tradeshow_guidance_app/services/activeService.dart';
import 'package:tradeshow_guidance_app/services/destination_setting.dart';
import 'package:tradeshow_guidance_app/services/storageService.dart';

import '../models/project.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key, required this.project});
  Project project;

  @override
  _ProfilePageState createState() => _ProfilePageState(project);
}

class _ProfilePageState extends State<ProfilePage> {
  _ProfilePageState(this.project);
  Project project;
  bool interested = false;
  bool visited = false;

  Map<String, Color> tagColors = {
    "ai": Colors.black12,
    "bluetooth": Colors.black26,
    "research": Colors.black38,
    "mobile": Colors.black54,
    "cloud": Colors.grey,
    "algorithms": Colors.blueGrey,
    "machine-learning": Colors.brown
  };

  ActiveService activeService = ActiveService.instance;

  @override
  void initState() {
    activeService.updateClickUsages("profile_page");
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        activeService.updateUsageTime({"profile_page": 1});
      } else {
        timer.cancel();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    interested = StorageService.interestsContainProject(project);
    visited = StorageService.projectWasVisited(project);
    int destinationSettingInt =
        StorageService.instance.getInt("destinationSetting") ?? -1;
    bool destinationSetToProject =
        (destinationSettingInt == DestinationSetting.PROJECT);
    int targetProjectId =
        StorageService.instance.getInt("targetProjectId") ?? -1;
    bool markedAsLocation =
        destinationSetToProject && (targetProjectId == project.id);
    return MaterialApp(
      title: 'Project Information',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Text('Project Information'),
          centerTitle: true,
        ),
        body: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 15.0, right: 15.0, top: 5.0, bottom: 2.5),
                        child: ElevatedButton.icon(
                          onPressed: (() {
                            Navigator.pop(context);
                          }),
                          icon: const Icon(
                            // <-- Icon
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
                              style:
                                  TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: getBorderColor(),
                        minRadius: 55.0,
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundColor: Colors.white,
                          backgroundImage: project.backgroundImage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    project.projectOwner,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.email_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        "${project.contactEmail}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    project.projectName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        "${project.roomLocation}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        "Supervisor: ${project.supervisor}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () {
                      if (markedAsLocation) {
                        return;
                      }
                      activeService
                          .updateClickUsages("project_set_as_destination");
                      StorageService.instance.setInt(
                          "destinationSetting", DestinationSetting.PROJECT);
                      StorageService.instance
                          .setInt("targetProjectId", project.id ?? -1);
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor:
                            markedAsLocation ? Colors.red : Colors.white),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          markedAsLocation
                              ? "CURRENT DESTINATION"
                              : "SET AS DESTINATION",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Icon(
                          Icons.location_on,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  subtitle: Container(
                    child: Markdown(
                      padding: const EdgeInsets.all(3.0),
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(Theme.of(context))
                              .copyWith(textScaleFactor: 1.3),
                      data: project.projectDescription.trim(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 200),
          ],
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: "btn2${project.id}",
                    backgroundColor: Colors.black87,
                    label: Row(children: [
                      visited
                          ? const Text('UNMARK AS VISITED')
                          : const Text('MARK AS VISITED'),
                      const SizedBox(
                        width: 5,
                      ),
                      visited
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.check_circle_outline)
                    ]),
                    onPressed: () {
                      if (visited) {
                        StorageService.removeFromVisitedProjects(project);
                        setState(() {
                          visited = false;
                        });
                      } else {
                        activeService
                            .updateClickUsages("markVisitedClick");
                        StorageService.addVisitedProject(project);
                        setState(() {
                          visited = true;
                        });
                      }
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  FloatingActionButton.extended(
                    heroTag: "btn1${project.id}",
                    backgroundColor: Colors.black87,
                    label: Row(children: [
                      interested
                          ? const Text('UNMARK AS INTERESTED')
                          : const Text('MARK AS INTERESTED'),
                      const SizedBox(
                        width: 5,
                      ),
                      interested
                          ? const Icon(Icons.star, color: Colors.yellow)
                          : const Icon(Icons.star_outline, color: Colors.white)
                    ]),
                    onPressed: () {
                      if (interested) {
                        StorageService.removeProjectFromInterested(project);
                        setState(() {
                          interested = false;
                        });
                      } else {
                        activeService
                            .updateClickUsages("markedInterestedClick");
                        StorageService.addInterestedProject(project);
                        setState(() {
                          interested = true;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
  
  getBorderColor() {
    if (visited) {
      return Color.fromARGB(255, 6, 117, 10);
    } else if (interested) {
      return Color.fromARGB(255, 189, 171, 13);
    } else {
      return Colors.black;
    }
  }
}
