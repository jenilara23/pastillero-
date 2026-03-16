import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'bluetooth_config.dart';

class BluetoothSignal {
  final String id;
  final String name;
  final int rssi;

  const BluetoothSignal({
    required this.id,
    required this.name,
    required this.rssi,
  });
}

class BluetoothService {
  Future<List<BluetoothSignal>> scanEspSignals() async {
    final granted = await _requestPermissions();
    if (!granted) {
      throw Exception('Necesitamos permiso de Bluetooth para buscar tu pastillero.');
    }

    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    final Map<String, BluetoothSignal> found = {};
    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = result.device.platformName.trim();
        if (name.isEmpty || !BluetoothConfig.matchesEspName(name)) {
          continue;
        }
        final id = result.device.remoteId.str;
        found[id] = BluetoothSignal(id: id, name: name, rssi: result.rssi);
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: BluetoothConfig.scanTimeout);
      await Future.delayed(BluetoothConfig.scanTimeout + const Duration(milliseconds: 350));
      await FlutterBluePlus.stopScan();
    } finally {
      await sub.cancel();
    }

    final list = found.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return list;
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }
}

