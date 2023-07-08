import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class Globals {
  static int _fakeIdCurrent = 1;
  static bool testMode = false;

  static ImageProvider noProjectImageProvider =
      AssetImage('images/no_user_image.jpg');

  static String survey_url =
      "https://docs.google.com/forms/d/e/1FAIpQLSfndxUdA0_vJ5bADn7seM0oawB2Nit7MsC_wsoBwg7ff73_ig/viewform?usp=sf_link";

  static getFakeId() {
    _fakeIdCurrent += 1;
    return _fakeIdCurrent;
  }

  static MemoryImage getMapImage(String imageBytesString) {
    MemoryImage memoryImage = MemoryImage(base64Decode(imageBytesString));

    return memoryImage;
  }
}
