import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

import 'wifi_config.dart';

class WifiSignal {
  final String ssid;
  final String bssid;
  final int level;

  const WifiSignal({
    required this.ssid,
    required this.bssid,
    required this.level,
  });
}

class WifiService {
  Future<List<WifiSignal>> scanWifiSignals() async {
    final granted = await _requestPermissions();
    if (!granted) {
      throw Exception('Necesitamos permiso de ubicación para buscar redes WiFi.');
    }

    final can = await WiFiScan.instance.canStartScan(askPermissions: false);
    if (can != CanStartScan.yes) {
      throw Exception('No se pudo iniciar el escaneo WiFi en este dispositivo.');
    }

    final started = await WiFiScan.instance.startScan();
    if (!started) {
      throw Exception('No pudimos escanear redes WiFi por ahora. Inténtalo de nuevo.');
    }

    await Future.delayed(WifiConfig.scanWait);
    final results = await WiFiScan.instance.getScannedResults();

    final unique = <String, WifiSignal>{};
    for (final ap in results) {
      if (!WifiConfig.isUsableSsid(ap.ssid)) continue;
      final key = '${ap.ssid}_${ap.bssid}';
      unique[key] = WifiSignal(
        ssid: ap.ssid,
        bssid: ap.bssid,
        level: ap.level,
      );
    }

    final list = unique.values.toList()..sort((a, b) => b.level.compareTo(a.level));
    return list;
  }

  Future<bool> _requestPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }
}

