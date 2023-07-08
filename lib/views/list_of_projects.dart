import 'package:flutter/material.dart';
import 'package:tradeshow_guidance_app/models/section.dart';
import 'package:tradeshow_guidance_app/services/activeService.dart';
import 'package:tradeshow_guidance_app/services/mockApi.dart';
import 'package:tradeshow_guidance_app/services/storageService.dart';
import 'package:tradeshow_guidance_app/views/profile_page.dart';

import 'package:tradeshow_guidance_app/models/project.dart';

class ListOfProjects extends StatefulWidget {
  const ListOfProjects({super.key});

  @override
  State<ListOfProjects> createState() => _ListOfProjectsState();
}

class _ListOfProjectsState extends State<ListOfProjects> {
  List<Project>? projects;
  bool isLoaded = false;

  TextEditingController controller = TextEditingController();

  List<String> roomsByIdString = ["-1"];

  String searchForRoomWithId = "-1";
  Map<String, Section> rooms = {};

  int filtersApplied = 0;

  Map<String, dynamic> filters = {
    "interests": true,
    "notInterests": true,
    "visited": true,
    "notVisited": true,
    "roomId": "-1",
    "hideUnknown": true,
  };

  Map<String, dynamic> defaultFilters = {
    "interests": true,
    "notInterests": true,
    "visited": true,
    "notVisited": true,
    "roomId": "-1",
    "hideUnknown": true,
  };

  @override
  void initState() {
    projectsChanged = true;
    roomsByIdString = ["-1"];
    ActiveService.instance.availableSections.forEach((element) {
      roomsByIdString.add(element.id.toString());
      rooms[element.id.toString()] = element;
    });
    super.initState();
    getData();
  }

  bool markInterests = false;
  bool markVisited = false;

  @override
  Widget build(BuildContext context) {
    filtersApplied = 0;
    filters.forEach((key, value) {
      if (defaultFilters[key] != value) filtersApplied++;
    });
    if (markInterests && markVisited) {
      markInterests = false;
      markVisited = false;
    }
    return StreamBuilder<List<Project>>(
      initialData: ActiveService.instance.projectList,
      stream: ActiveService.instance.projectListStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(25.0),
            child: Text(
              'No projects found. Have you set a site on the home page?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ));
        } else {
          return _buildListView(snapshot.data!);
        }
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.search),
                title: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                      hintText: 'Search Projects', border: InputBorder.none),
                  onChanged: onSearchTextChanged,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          TextButton(
              style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                  padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.all(0)),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.black87)),
              onPressed: () {
                setState(() {
                  openFiltersDialog();
                });
              },
              child: Center(
                child: FittedBox(
                  child: Row(
                    children: [
                      Text(
                        "OPEN FILTERS (${filtersApplied})",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TextButton(
                    style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.all(0)),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.black87)),
                    onPressed: () {
                      setState(() {
                        if (!mounted) return;
                        setState(() {
                          markInterests = !markInterests;
                          markVisited = false;
                        });
                      });
                    },
                    child: Center(
                      child: FittedBox(
                        child: Row(
                          children: [
                            Text(
                              "MARK INTERESTS",
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color:
                                      markInterests ? Colors.red : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TextButton(
                    style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.all(0)),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.black87)),
                    onPressed: () {
                      setState(() {
                        if (!mounted) return;
                        setState(() {
                          markInterests = false;
                          markVisited = !markVisited;
                        });
                      });
                    },
                    child: Center(
                      child: FittedBox(
                        child: Row(
                          children: [
                            Text(
                              "MARK VISITED",
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color:
                                      markVisited ? Colors.red : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  openFiltersDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                scrollable: true,
                title: const Text('Filters'),
                content: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      CheckboxListTile(
                        title: const Text('Marked Interests'),
                        value: filters["interests"],
                        onChanged: (bool? value) {
                          setDialogState(() {});
                          setState(() {
                            filters["interests"] = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Unmarked Interests'),
                        value: filters["notInterests"],
                        onChanged: (bool? value) {
                          setDialogState(() {});
                          setState(() {
                            filters["notInterests"] = value ?? false;
                          });
                        },
                      ),
                      const Divider(
                        color: Colors.black,
                      ),
                      CheckboxListTile(
                        title: const Text('Visited Projects'),
                        value: filters["visited"],
                        onChanged: (bool? value) {
                          setDialogState(() {});
                          setState(() {
                            filters["visited"] = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Unvisited Projects'),
                        value: filters["notVisited"],
                        onChanged: (bool? value) {
                          setDialogState(() {});
                          setState(() {
                            filters["notVisited"] = value ?? false;
                          });
                        },
                      ),
                      const Divider(
                        color: Colors.black,
                      ),
                      CheckboxListTile(
                        title: const Text('Hide Unknown Locations'),
                        value: filters["hideUnknown"],
                        onChanged: (bool? value) {
                          setDialogState(() {});
                          setState(() {
                            filters["hideUnknown"] = value ?? false;
                          });
                        },
                      ),
                      const Divider(
                        color: Colors.black,
                      ),
                      DropdownButtonFormField(
                        decoration: const InputDecoration(
                          labelText: 'Room',
                        ),
                        value: searchForRoomWithId,
                        items: roomsByIdString
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text((e == "-1"
                                      ? "All"
                                      : rooms[e] == null
                                          ? "error"
                                          : rooms[e]!.sectionName)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {});
                          setState(() {
                            filters["roomId"] = value.toString();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  Container(
                    width: double.infinity,
                    height: 60,
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setDialogState(() {
                          filters.forEach((key, value) {
                            filters[key] = defaultFilters[key] ?? false;
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        // fixedSize: Size(250, 50),
                      ),
                      child: const Text(
                        "RESTORE DEFAULTS",
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
                        "CONFIRM",
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }).then((value) {
      if (!mounted) return;
      setState(() {
        projectsChanged = true;
      });
    });
  }

  List<Project> projectsFiltered = [];
  bool projectsChanged = true;

  Widget _buildListView(List<Project> allProjects) {
    searchForRoomWithId = filters["roomId"] ?? "-1";
    Section? room = rooms[searchForRoomWithId];
    if (projectsChanged || projectsFiltered.isEmpty) {
      projectsChanged = false;
      projectsFiltered = [];
      if (filtersApplied == 0) {
        projectsFiltered = allProjects;
        if (filters["hideUnknown"]){
          projectsFiltered = projectsFiltered.where((element) => element.hasKnownLocation).toList();
        }
      } else {
        for (var project in allProjects) {
          bool projectIsInterest =
              StorageService.interestsContainProject(project);
          bool projectWasVisited = StorageService.projectWasVisited(project);
          int addToList = 0;
          if (filters["interests"] == true && projectIsInterest) {
            addToList++;
          } else if (filters["notInterests"] == true && !projectIsInterest) {
            addToList++;
          }
          if (filters["visited"] == true && projectWasVisited) {
            addToList++;
          } else if (filters["notVisited"] == true && !projectWasVisited) {
            addToList++;
          }
          if ((filters["roomId"] == "-1") ||
              (room != null && containsProjectWithDepth(room, project, 1))) {
            addToList++;
          }
          if ((filters["hideUnknown"]) && (!project.hasKnownLocation)) {
            addToList = 0;
          }
          if (addToList >= 3) {
            projectsFiltered.add(project);
          }
        }
      }
    }
    searchString = searchString.trim().toLowerCase();
    if (searchString.isNotEmpty) {
      projectsFiltered = projectsFiltered
          .where((project) =>
              project.projectName.toLowerCase().contains(searchString) ||
              project.projectOwner.toLowerCase().contains(searchString) ||
              project.supervisor.toLowerCase().contains(searchString) ||
              project.tags.toLowerCase().contains(searchString) ||
              project.projectDescription.toLowerCase().contains(searchString))
          .toList();
    }
    List<Project> projects =
        projectsFiltered;
    projects.sort((a, b) =>
        a.projectName.toLowerCase().compareTo(b.projectName.toLowerCase()));
    return ListView(
      children: <Widget>[
        _buildSearchBar(),
        const SizedBox(height: 5),
        SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Column(
            children: [
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: projects.length,
                  itemBuilder: (BuildContext context, int index) {
                    Project project = projects[index];
                    bool visited = StorageService.projectWasVisited(project);
                    bool interest =
                        StorageService.interestsContainProject(project);
                    return ListTile(
                      key: Key(project.id.toString()),
                      textColor: Colors.white,
                      tileColor: getTileColor(index, project),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: project.backgroundImage,
                      ),
                      title: Text(
                        project.projectName,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (markVisited)
                            if (visited)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            else
                              const Icon(
                                Icons.check_circle,
                                color: Colors.black45,
                              )
                          else if (interest)
                            const Icon(
                              Icons.star,
                              color: Colors.yellow,
                            )
                          else
                            Opacity(
                              opacity: markInterests ? 1 : 0,
                              child: const Icon(
                                Icons.star,
                                color: Colors.black45,
                              ),
                            )
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.projectOwner,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 15,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                project.roomLocation,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        bool refresh = false;
                        if (markInterests) {
                          if (interest) {
                            StorageService.removeProjectFromInterested(project);
                          } else {
                            StorageService.addInterestedProject(project);
                          }
                          refresh = true;
                        } else if (markVisited) {
                          if (visited) {
                            StorageService.removeFromVisitedProjects(project);
                          } else {
                            StorageService.addVisitedProject(project);
                          }
                          refresh = true;
                        } else {
                          Navigator.of(context).push(_createRoute(
                              ProfilePage(project: projects[index])));
                        }
                        if (refresh && mounted) {
                          setState(() {
                            projectsChanged = true;
                          });
                        }
                      },
                    );
                  }),
            ],
          ),
        )
      ],
    );
  }

  containsProjectWithDepth(Section section, Project project, int depth) {
    if (depth == 0) {
      return section.projects?.contains(project) ?? false;
    }
    if (section.projects?.contains(project) ?? false) {
      return true;
    }
    List<Section> subsections = section.subsections;
    for (var subsection in subsections) {
      if (containsProjectWithDepth(subsection, project, depth - 1)) {
        return true;
      }
    }
    return false;
  }

  containsProject(Section section, Project project) {
    if (projects?.contains(project) ?? false) {
      return true;
    }
    List<Section> subsections = section.subsections;
    for (var subsection in subsections) {
      if (subsection.containsProject(project)) {
        return true;
      }
    }
    return false;
  }

  Color getTileColor(int index, Project project) {
    return (index % 2 == 0) ? Colors.black38 : Colors.black45;
  }

  String searchString = "";

  onSearchTextChanged(String text) async {
    projectsChanged = true;
    searchString = text;
    setState(() {});
  }

  getData() async {
    if (projects != null) return;
    projects = await mockApi.getProjects();
    if (projects != null) {
      setState(() {
        isLoaded = true;
      });
    } else {
      setState(() {
        isLoaded = false;
      });
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
