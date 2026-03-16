class BluetoothConfig {
  static const Duration scanTimeout = Duration(seconds: 8);

  // Nombres frecuentes para detectar el pastillero ESP32.
  static const List<String> espNameHints = [
    'esp32',
    'esp-',
    'pastillero',
    'pillcare',
  ];

  static bool matchesEspName(String name) {
    final normalized = name.toLowerCase();
    return espNameHints.any(normalized.contains);
  }
}

