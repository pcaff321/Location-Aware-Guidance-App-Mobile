import 'package:flutter/material.dart';
import 'package:tradeshow_guidance_app/models/network_device.dart';
import 'package:tradeshow_guidance_app/services/activeService.dart';
import 'package:tradeshow_guidance_app/views/network_device_page.dart';

class ListOfNetworkDevices extends StatefulWidget {
  const ListOfNetworkDevices({Key? key}) : super(key: key);

  @override
  _ListOfNetworkDevicesState createState() => _ListOfNetworkDevicesState();
}

class _ListOfNetworkDevicesState extends State<ListOfNetworkDevices> {
  bool isLoaded = false;

  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NetworkDevice>>(
      initialData: ActiveService.instance.networkDeviceList,
      stream: ActiveService.instance.networkDeviceListStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data'));
        } else {
          return _buildListView(snapshot.data!);
        }
      },
    );
  }

  Widget _buildListView(List<NetworkDevice> allNetworkDevices) {
    List<NetworkDevice> networkDevices = allNetworkDevices
        .where((networkDevice) =>
            networkDevice.devicename
                .toLowerCase()
                .contains(controller.text.toLowerCase()) ||
            networkDevice.devicemac
                .toLowerCase()
                .contains(controller.text.toLowerCase()) ||
                (networkDevice.uuid != null && networkDevice.uuid!.toLowerCase().contains(controller.text.toLowerCase()))
                || (networkDevice.major != null && networkDevice.major!.toLowerCase().contains(controller.text.toLowerCase()))
                || (networkDevice.minor != null && networkDevice.minor!.toLowerCase().contains(controller.text.toLowerCase()))
                )
        .toList();
    int bluetooth = -1;
    int wifi = -1;
    return ListView(
      children: <Widget>[
        _buildSearchBar(),
        const SizedBox(height: 10),
        SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Column(
            children: [
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: networkDevices.length,
                  itemBuilder: (BuildContext context, int index) {
                    NetworkDevice networkDevice = networkDevices[index];
                    return ListTile(
                      key: Key(networkDevice.id),
                      textColor: Colors.white,
                      tileColor: _getTileColor(networkDevice, bluetooth, wifi),
                      title: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("${networkDevice.devicename}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      subtitle: getSubitle(networkDevice),
                      trailing: _buildTrailing(networkDevice),
                      onTap: () => {
                        Navigator.of(context).push(_createRoute(
                            NetworkDevicePage(networkDevice: networkDevices[index])))
                      },
                    );
                  }),
            ],
          ),
        )
      ],
    );
  }

  Color _getTileColor(NetworkDevice networkDevice, int bluetooth, int wifi) {
    if (networkDevice.isbluetooth) {
      return (bluetooth++ % 2 == 0) ? Colors.blue : Colors.lightBlue;
    } else {
      return (wifi++ % 2 == 0) ? Colors.green : Colors.lightGreen;
    }
  }

  Widget getSubitle(NetworkDevice networkDevice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("MAC: ${networkDevice.devicemac}"),
        Text("Major/Minor: ${networkDevice.getMajorMinor()}"),
      ],
    );
  }

  Widget _buildTrailing(NetworkDevice networkDevice) {
    double distance = double.parse(networkDevice.distance ?? "99999");
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('${distance.toStringAsFixed(2)} m'),
        SizedBox(width: 8),
        Icon(networkDevice.isbluetooth ? Icons.bluetooth : Icons.wifi)
      ],
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
                leading: Icon(Icons.search),
                title: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                      hintText: 'Search by Name, MAC, UUID, Major or Minor',
                      border: InputBorder.none),
                  onChanged: onSearchTextChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  onSearchTextChanged(String text) async {
    setState(() {});
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
