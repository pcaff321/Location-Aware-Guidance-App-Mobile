class DestinationSetting {
  static const int DEFAULT = 0;
  static const int CLOSEST_ROOM = 1;
  static const int BEACON = 3;
  static const int ROOM = 4;
  static const int PROJECT = 5;
  static const int EXIT = 6;

  static String getDescription(int value) {
    switch (value) {
      case DEFAULT:
        return 'Default';
      case CLOSEST_ROOM:
        return 'Closest Area';
      case BEACON:
        return 'Beacon';
      case ROOM:
        return 'Choose Area / Room';
      case PROJECT:
        return 'Choose Project';
      case EXIT:
        return 'Exit';
      default:
        return 'Unknown';
    }
  }

  static List<int> getOptions() {
    return [DEFAULT, CLOSEST_ROOM, EXIT, ROOM, PROJECT];
  }
}