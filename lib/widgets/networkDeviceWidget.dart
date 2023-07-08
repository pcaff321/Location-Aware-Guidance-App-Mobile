import 'package:tradeshow_guidance_app/models/network_device.dart';

import 'package:flutter/material.dart';

class NetworkDeviceWidget extends StatelessWidget {
  final NetworkDevice networkDevice;

  const NetworkDeviceWidget({Key? key, required this.networkDevice})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(networkDevice.devicename),
      subtitle: Text(networkDevice.devicemac),
      trailing: Text(networkDevice.isbluetooth ? 'Bluetooth' : 'WiFi'),
    );
  }
}

