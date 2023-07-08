import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tradeshow_guidance_app/models/site.dart';
import 'package:tradeshow_guidance_app/services/activeService.dart';
import 'package:tradeshow_guidance_app/services/globals.dart';
import 'package:tradeshow_guidance_app/services/httpService.dart';
import 'package:tradeshow_guidance_app/services/storageService.dart';
import 'package:tradeshow_guidance_app/views/tutorialView.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  _HomeViewState();

  List<Site> sites = [];

  Site? chosenSite;

  ActiveService activeService = ActiveService.instance;

  HttpService httpService = HttpService.instance;

  @override
  void initState() {
    httpService.loadingSites = true;
    HttpService.instance.getSites().then((value) {
      activeService.activeSites = value;
      httpService.loadingSites = false;
      if (value.length == 1) {
        chosenSite = value[0];
        HttpService.instance.setSite(chosenSite!);
      }
      if (!mounted) return;
      setState(() {});
    });

    httpService.getNetworkDevices();

    activeService.loadingSiteStream.listen((event) {
      if (!mounted) return;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool loadingSite = activeService.loadingSite;
    sites = activeService.activeSites;
    if (chosenSite == null) {
      if (StorageService.instance.getString("siteId") != null &&
          sites.any((element) =>
              element.id == StorageService.instance.getString("siteId"))) {
        chosenSite = sites.firstWhere((element) =>
            element.id == StorageService.instance.getString("siteId"));
      } else if (sites.isNotEmpty) {
        chosenSite = sites[0];
      }
    }
    bool loadingSites = httpService.loadingSites;
    bool loadedSiteSelected = chosenSite != null &&
        httpService.lastLoadedSite != null &&
        (chosenSite?.id == httpService.lastLoadedSite?.id);
    return MaterialApp(
        title: 'Home',
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(
                          onPressed: () {
                            activeService
                                .updateClickUsages("openTutorialDialog");
                            openTutorialDialog();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue,
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.help_outline,
                                  color: Colors.white, size: 30),
                              Text('Tutorial',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ],
                          )),
                    ),
                  ),
                  Container(
                      //padding: const EdgeInsets.fromLTRB(20, 20, 20, 70),
                      child: Image.asset('images/ucc_transparent.png',
                          fit: BoxFit.contain, width: 80, height: 80)),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: const Text(
                      'Welcome to the Tradeshow Guidance App!',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  getMiddleSection(),
                  Container(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: SingleChildScrollView(
                          child: Text(chosenSite != null
                              ? (chosenSite!.description)
                              : "Please select a site"),
                        ),
                      )),
                  Container(
                      height: 80,
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: loadingSite
                            ? Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text('SETTING SITE...'),
                                    SizedBox(width: 10),
                                    Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white)),
                                    ),
                                  ],
                                ),
                              )
                            : Text(loadedSiteSelected
                                ? 'SITE LOADED'
                                : 'SET SITE'),
                        onPressed: () {
                          if (chosenSite != null && !loadingSites) {
                            HttpService.instance.setSite(chosenSite!);
                          }
                        },
                      )),
                  Column(
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.email, color: Colors.grey[600]),
                            const SizedBox(width: 10),
                            Text(
                              'CONTACT ME - PAULCAFF2@GMAIL.COM',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          var url =
                              "https://www.linkedin.com/in/paul-caffrey-cs/";
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'images/linkedInImage.png',
                              width: 25,
                              height: 25,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ADD ME - PAUL CAFFREY',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.redAccent),
                            ),
                            onPressed: () async {
                              var url = Globals.survey_url;
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                Fluttertoast.showToast(
                                  msg:
                                      "Could not open link. Come talk to me in person or email me instead!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.black,
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'NOTE: If you could take two minutes to complete this survey after using the app, it would be greatly appreciated!',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(
                    height: 100,
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void openTutorialDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.only(left: 25, right: 25),
            title: Center(child: Text("Tutorial")),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            content: Container(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Close',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TutorialViewWidget()
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget getMiddleSection() {
    bool loadingSite = activeService.loadingSite;
    if (httpService.loadingSites) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(height: 10),
            Text('LOADING SITES...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.all(5.0),
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: DropdownButton<Site>(
        value: chosenSite,
        icon: const Icon(Icons.arrow_downward_sharp),
        iconSize: 24,
        elevation: 16,
        isExpanded: true,
        style: const TextStyle(
          color: Colors.deepPurple,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        underline: Container(
          height: 2,
          color: Colors.deepPurpleAccent,
        ),
        onChanged: loadingSite
            ? null
            : (Site? newValue) {
                setState(() {
                  if (newValue != chosenSite) {
                    chosenSite = newValue!;
                    StorageService.instance.setString("siteId", newValue.id);
                  }
                });
              },
        items: sites.map<DropdownMenuItem<Site>>((Site site) {
          return DropdownMenuItem<Site>(
            value: site,
            child: Text(
                '${site.sitename} ${activeService.activeSite?.id == site.id ? '(active)' : ''}'),
          );
        }).toList(),
      ),
    );
  }
}
