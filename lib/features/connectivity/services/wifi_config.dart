class WifiConfig {
  static const Duration scanWait = Duration(seconds: 3);

  static bool isUsableSsid(String ssid) => ssid.trim().isNotEmpty;
}

