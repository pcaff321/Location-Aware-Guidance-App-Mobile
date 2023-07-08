import 'package:flutter/material.dart';
import 'package:tradeshow_guidance_app/models/project.dart';
import 'package:tradeshow_guidance_app/models/section.dart';
import 'package:tradeshow_guidance_app/services/storageService.dart';

getVisitedProjectsDialog(BuildContext context, Section section) {
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
            "Mark Projects as Visited",
            style: TextStyle(fontSize: 24.0),
          ),
          content: Container(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                        "It looks like you may have visited some projects in this section. Would you like to mark them as visited?",
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 40,
                    padding: const EdgeInsets.all(5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        List<Project> projectsInSection =
                            section.projects ?? [];
                        projectsInSection.forEach((element) {
                          element.visited = true;
                        });
                        setDialogState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 34, 98, 36),
                        // fixedSize: Size(250, 50),
                      ),
                      child: const Text(
                        "SELECT ALL",
                      ),
                    ),
                  ),
                                  Container(
                    width: double.infinity,
                    height: 40,
                    padding: const EdgeInsets.all(5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        List<Project> projectsInSection =
                            section.projects ?? [];
                        projectsInSection.forEach((element) {
                          element.visited = false;
                        });
                        setDialogState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 148, 33, 33),
                        // fixedSize: Size(250, 50),
                      ),
                      child: const Text(
                        "DESELECT ALL",
                      ),
                    ),
                  ),
                  getProjectsCheckBoxList(setDialogState, section),
                  Container(
                    width: double.infinity,
                    height: 60,
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        List<Project> projectsInSection =
                            section.projects ?? [];
                        projectsInSection = projectsInSection
                            .where((element) => element.visited ?? false)
                            .toList();
                        StorageService.saveVisitedProjects(projectsInSection);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        // fixedSize: Size(250, 50),
                      ),
                      child: const Text(
                        "MARK SELECTED AS VISITED",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));
    },
  );
}

getProjectsCheckBoxList(StateSetter setDialogState, Section section) {
  List<Project> projectsInSection = section.projects ?? [];
  projectsInSection.sort((a, b) => a.projectName.compareTo(b.projectName));
  return SingleChildScrollView(
    child: Column(
      children: [
        Container(
          height: 200,
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              return Divider(color: Color.fromARGB(43, 0, 0, 0)
              ,
              thickness: 2,
              indent: 20,
              endIndent: 20,);
            },
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: projectsInSection.length,
            itemBuilder: (BuildContext context, int index) {
              return CheckboxListTile(
                tristate: true,
                title: Text(projectsInSection[index].projectName),
                subtitle: Text(projectsInSection[index].projectOwner),
                secondary: Opacity(
                    opacity: StorageService.interestsContainProject(
                            projectsInSection[index])
                        ? 1
                        : 0,
                    child: const Icon(
                      Icons.star,
                      color: Colors.yellow,
                    )),
                value: projectsInSection[index].visited ?? false,
                onChanged: (bool? value) {
                  value = value ?? false;
                  setDialogState(() {
                    projectsInSection[index].visited = value;
                  });
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
