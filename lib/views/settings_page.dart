import 'package:flutter/material.dart';
import 'package:tradeshow_guidance_app/services/activeService.dart';
import 'package:tradeshow_guidance_app/services/storageService.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _SettingsPageState();

  ActiveService activeService = ActiveService.instance;

  bool locationUpdates = true;
  bool scanOnlyWhenInApp = true;
  bool notifyMe = true;

  @override
  Widget build(BuildContext context) {
    locationUpdates =
        StorageService.getString("locationUpdates") == "false" ? false : true;
    scanOnlyWhenInApp =
        StorageService.getString("scanOnlyWhenInApp") == "false" ? false : true;
    notifyMe = StorageService.getString("notifyMe") == "false" ? false : true;
    return MaterialApp(
        title: 'Settings',
        home: Scaffold(
            body: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(15),
                  child: buildWidget(
                    text: 'Scan For Devices',
                    child: buildAdaptiveSwitch(
                      locationUpdates,
                      (bool value) => setState(() {
                        StorageService.setString(
                            "locationUpdates", value.toString());
                        activeService.updateBackgroundIsolate(true);
                      }),
                    ),
                  ),
                ),
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(15),
                  child: buildWidget(
                    text: 'Scan Only When In App',
                    active: locationUpdates,
                    child: buildAdaptiveSwitch(
                      scanOnlyWhenInApp,
                      locationUpdates
                          ? (bool value) => setState(() {
                                StorageService.setString(
                                    "scanOnlyWhenInApp", value.toString());
                                activeService.updateBackgroundIsolate(true);
                              })
                          : null,
                    ),
                  ),
                ),
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(15),
                  child: buildWidget(
                    text: "Send Location Notifications",
                    active: locationUpdates,
                    child: buildAdaptiveSwitch(
                      notifyMe,
                      locationUpdates
                          ? (bool value) => setState(() {
                                StorageService.setString(
                                    "notifyMe", value.toString());
                                    activeService.updateBackgroundIsolate(true);
                              })
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(15),
                  child: buildWidget(
                    text: '[DEV ONLY]',
                    active: true,
                    child: Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: 'Admin Password',
                        ),
                        initialValue: StorageService.getString("adminpassword"),
                        obscureText: true,
                        validator: (String? value) {
                          if (value != null && value.trim().isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {
                          StorageService.setString(
                              "adminpassword", value.toString());
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )));
  }

  Widget buildWidget({
    required Widget child,
    required String text,
    bool active = true,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.black : Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      );


  Widget buildAdaptiveSwitch(bool boolean, Function(bool)? func) {
    bool activeSwitch = func != null ? true : false;
    return Transform.scale(
      scale: 1.2,
      child: Switch.adaptive(
        thumbColor: MaterialStateProperty.all(
            activeSwitch ? Colors.black : Colors.grey),
        trackColor: MaterialStateProperty.all(
            activeSwitch ? Colors.black26 : Colors.black12),
        splashRadius: 50,
        value: boolean,
        onChanged: func,
      ),
    );
  }
}
