import 'package:flutter/material.dart';
import 'package:tradeshow_guidance_app/models/tutorialPageModel.dart';
import 'package:tradeshow_guidance_app/services/storageService.dart';

class TutorialViewWidget extends StatefulWidget {
  const TutorialViewWidget({Key? key}) : super(key: key);

  @override
  _TutorialViewWidgetState createState() => _TutorialViewWidgetState();
}

class _TutorialViewWidgetState extends State<TutorialViewWidget> {
  int pageNumber = 0;
  List<TutorialPageModel> pages = [];

  @override
  void initState() {
    pages.add(TutorialPageModel(
        "Welcome to the Tradeshow Guidance App",
        "This app will help you navigate a tradeshow area and find projects that you are interested in. The following pages will show you how to use the app.",
        "images/tutorial/TRADESHOWAPPEMBLEM.png"));
    pages.add(TutorialPageModel(
        "Setting Site",
        "A site is simply a tradeshow area. You can set the site by clicking the 'Set Site' button on the home page. This should automatically be done for you as this app is experimental.",
        "images/tutorial/SettingSite.png"));
    pages.add(TutorialPageModel(
        "Nav Bar",
        "To navigate through the app, there is a navigation bar at the bottom of the page.",
        "images/tutorial/NavBarPage.png"));
    pages.add(TutorialPageModel(
        "Map View",
        "The map view displays areas in which projects are located. The map can be zoomed in and out by pinching the screen. There are visual indicators on the map to show hints, projects, areas and the user's current location. These indicators can be interacted with. The next few pages will discuss this in detail.",
        "images/tutorial/mapView.png"));
    pages.add(TutorialPageModel(
        "Setting Destination",
        "In the map view, it is possible to set a destination. This destination will be used to calculate a path on the map from a given location. The default setting will pick a random project for you to visit. If you mark projects as visited, the app will automatically pick a new project for you to visit. If you have selected projects that you are interested in, this will be used to calculate a path to a project of interest. Marking projects as interests and visited will be discussed later.",
        "images/tutorial/setDestination.png"));
    pages.add(TutorialPageModel(
        "Hints",
        "Hints are visual indicators on the map that will help you determine where you are on a map. For example, above is a hint which shows a picture of an elevator. This can be viewed by clicking on a question mark on the map. There is also the option to click on the 'I'm Here' button, which will automatically set your location to the location of the hint.",
        "images/tutorial/hintExample.png"));
    pages.add(TutorialPageModel(
        "Manually Setting Location",
        "If you activate 'SET LOCATION', you can manually set your location by clicking on the map. Based on your set destination, a path/route will be generated to the destination.",
        "images/tutorial/settingLocationManually.png"));
    pages.add(TutorialPageModel(
        "Bottom Map Buttons",
        "The bottom map buttons have the following 3 functions - 1. Guessing Location, 2. Exiting an area, 3. Entering a suggested area. Guessing location will be discussed later. Exiting an area will change the map to the outer area. For example, if you are inside a room, the map will change to the hallway which leads to the room. The button to enter an area will appear if the set location is close to a room entrance.",
        "images/tutorial/BottomMapButtonsFunctions.png"));
    pages.add(TutorialPageModel(
        "Guessing Location",
        "Guessing location is a feature that allows you to ask the app to guess where you are on the map. This is an experimental feature and is not guaranteed to work. This feature can only be used roughly every 7 seconds due to Android restrictions. If you are inside a room, the location will be set to the door in which you are closest to. If you are in a larger area, the location will be an estimate of your location. These results may not be accurate, especially if you are in an area far away from important rooms. The next two pages will demonstrate this.",
        "images/tutorial/GuessingLocationExample.png"));
    pages.add(TutorialPageModel(
        "Correct Guess Example",
        "In this example, the guessed location is accurate. The user was in a location nearby important areas (the coloured circles indicate important areas.). An important area is one in which projects can be found. The green user icon displays the user's actual location, and the blue icon displays the guessed location.",
        "images/tutorial/CorrectGuessExample.png"));
    pages.add(TutorialPageModel(
        "Incorrect Guess Example",
        "In this example, the guessed location is inaccurate. The user was in a location far away from important areas. This means you may be better off manually setting your location or using hints. ",
        "images/tutorial/IncorrectGuessExamlpe.png"));
    pages.add(TutorialPageModel(
        "Projects View",
        "The projects view displays all projects at a site. The projects can be filtered by visits, interests or rooms. It is also possible to filter by an input that matches the project's title, description, creator, etc.",
        "images/tutorial/projectsViewPage.png"));
    pages.add(TutorialPageModel(
        "Quick Marking Visits",
        "In the Projects View, it is possible to quickly mark projects that you have visited. In a similar way, it is also possible to mark projects which you are interested in.",
        "images/tutorial/MarkingVisits.png"));
    pages.add(TutorialPageModel(
        "Project Page",
        "Clicking on a project will bring you to the project page. Here, more details on a project are available. It is also possible to mark a project as an interest, as visited, or set the project as a destination (if the project's location is known by the app.)",
        "images/tutorial/ProfileExample.png"));
    pages.add(TutorialPageModel(
        "Thank You For Trying The App!",
        "Thank you for downloading the app and completing this tutorial! If you have any questions, please contact me, or visit me on the day! My contact details are on the home page. I would also appreciate any feedback on the app, which you can give via email or through the survey link at the bottom of the home page. Enjoy the open day!",
        "images/tutorial/BottomOfHomePage.png"));
    pageNumber =
        (StorageService.instance.getInt("tutPageNumber") ?? 0) % pages.length;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      width: size.width - 20,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.all(5),
                  ),
                  onPressed: () {
                    setState(() {
                      pageNumber = (pageNumber - 1) % pages.length;
                      StorageService.instance
                          .setInt("tutPageNumber", pageNumber);
                    });
                  },
                  child:
                      Text("Previous", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(5),
                    backgroundColor: Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      pageNumber = (pageNumber + 1) % pages.length;
                      StorageService.instance
                          .setInt("tutPageNumber", pageNumber);
                    });
                  },
                  child: Text("Next", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text("Page ${pageNumber + 1} / ${pages.length}"),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: size.width - 20),
            child: Center(
              child:
                  Image.asset(pages[pageNumber].image, fit: BoxFit.scaleDown),
            ),
          ),
          const SizedBox(height: 10),
          Text(pages[pageNumber].title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(pages[pageNumber].description),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
