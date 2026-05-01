import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/bluetooth_service.dart';
import '../services/wifi_service.dart';

/// Tipo de conexión activa del pastillero
enum ConnectionType { none, bluetooth, wifi }

class ConnectivityScreen extends StatefulWidget {
  final ConnectionType initialType;
  const ConnectivityScreen({super.key, this.initialType = ConnectionType.none});

  @override
  State<ConnectivityScreen> createState() => _ConnectivityScreenState();
}

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final WifiService _wifiService = WifiService();

  late bool _bluetoothOn;
  late bool _wifiOn;
  String? _linkedEspName;
  String? _linkedWifiName;

  @override
  void initState() {
    super.initState();
    _wifiOn = widget.initialType == ConnectionType.wifi;
    // ✅ CAMBIO 1: Bluetooth ahora es independiente de WiFi
    _bluetoothOn = widget.initialType == ConnectionType.bluetooth;
  }

  ConnectionType get _currentType {
    if (_wifiOn && _bluetoothOn) return ConnectionType.wifi;
    if (_bluetoothOn) return ConnectionType.bluetooth;
    if (_wifiOn) return ConnectionType.wifi;
    return ConnectionType.none;
  }

  Future<void> _toggleBluetooth(bool val) async {
    if (!val) {
      setState(() {
        _bluetoothOn = false;
        _linkedEspName = null;
      });
      return;
    }

    final linkedSignal = await _showBluetoothScannerModal();
    if (!mounted || linkedSignal == null) return;

    setState(() {
      _bluetoothOn = true;
      _linkedEspName = linkedSignal.name;
    });
    _showSnack('Listo. Bluetooth conectado con $_linkedEspName');
  }

  Future<void> _toggleWifi(bool val) async {
    if (!val) {
      setState(() {
        _wifiOn = false;
        _linkedWifiName = null;
      });
      return;
    }

    // ✅ CAMBIO 2: Se eliminó la validación que obligaba activar Bluetooth primero

    final wifiSignal = await _showWifiScannerModal();
    if (!mounted || wifiSignal == null) return;

    setState(() {
      _wifiOn = true;
      _linkedWifiName = wifiSignal.ssid;
    });

    _showSnack('Perfecto. WiFi conectado a $_linkedWifiName');
  }

  Future<BluetoothSignal?> _showBluetoothScannerModal() {
    final futureSignals = _bluetoothService.scanEspSignals();
    int selected = -1;

    return showModalBottomSheet<BluetoothSignal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bluetooth',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Vamos a buscar tu pastillero cercano.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<List<BluetoothSignal>>(
                    future: futureSignals,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 26),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 10),
                                Text(
                                  'Buscando señales Bluetooth...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _modalMessage(
                          'No pudimos buscar Bluetooth.\nRevisa permisos y vuelve a intentar.',
                        );
                      }

                      final devices = snapshot.data ?? [];
                      if (devices.isEmpty) {
                        return _modalMessage(
                          'No encontramos un ESP32 cercano.\nAcerca el teléfono al pastillero e intenta de nuevo.',
                        );
                      }

                      return Column(
                        children: [
                          ...devices.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final isSelected = idx == selected;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setModalState(() => selected = idx),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.blue.withValues(alpha: 0.25)
                                        : Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.blue
                                          : Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.bluetooth_searching_rounded,
                                          color: Colors.white),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              'Señal: ${item.rssi} dBm',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? AppColors.green
                                            : Colors.white54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: selected < 0
                                  ? null
                                  : () => Navigator.pop(context, devices[selected]),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.green.withValues(alpha: 0.45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: const Text(
                                'Conectar por Bluetooth',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<WifiSignal?> _showWifiScannerModal() {
    final futureSignals = _wifiService.scanWifiSignals();
    int selected = -1;

    return showModalBottomSheet<WifiSignal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'WiFi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ahora elige la red para mantener el monitoreo activo.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<List<WifiSignal>>(
                    future: futureSignals,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 26),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 10),
                                Text(
                                  'Buscando redes WiFi...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _modalMessage(
                          'No pudimos buscar redes WiFi en este teléfono.\nRevisa permisos y vuelve a intentar.',
                        );
                      }

                      final networks = snapshot.data ?? [];
                      if (networks.isEmpty) {
                        return _modalMessage(
                          'No se encontraron redes WiFi cercanas.\nAcércate al router e intenta de nuevo.',
                        );
                      }

                      return Column(
                        children: [
                          ...networks.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final isSelected = idx == selected;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setModalState(() => selected = idx),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.purple.withValues(alpha: 0.28)
                                        : Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.purple
                                          : Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.wifi_rounded,
                                          color: Colors.white),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.ssid,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              'Intensidad: ${item.level} dBm',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? AppColors.green
                                            : Colors.white54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: selected < 0
                                  ? null
                                  : () => Navigator.pop(context, networks[selected]),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.green.withValues(alpha: 0.45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: const Text(
                                'Conectar WiFi',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _modalMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  _buildConnectionFlow(),
                  const SizedBox(height: 20),
                  _buildConnectionCard(
                    icon: Icons.bluetooth_rounded,
                    iconColor: AppColors.blue,
                    iconBg: AppColors.blue.withValues(alpha: 0.15),
                    title: 'Bluetooth',
                    subtitle: _bluetoothOn
                        ? 'Conectado: ${_linkedEspName ?? 'Pastillero ESP32'}'
                        : 'Toca para buscar tu pastillero cercano',
                    value: _bluetoothOn,
                    onChanged: _toggleBluetooth,
                  ),
                  const SizedBox(height: 14),
                  _buildConnectionCard(
                    icon: Icons.wifi_rounded,
                    iconColor: AppColors.purple,
                    iconBg: AppColors.purple.withValues(alpha: 0.15),
                    title: 'WiFi',
                    subtitle: _wifiOn
                        ? 'Conectado: ${_linkedWifiName ?? 'Red seleccionada'}'
                        : 'Toca para conectar tu red WiFi', // ✅ CAMBIO 3
                    value: _wifiOn,
                    onChanged: _toggleWifi,
                  ),
                  const SizedBox(height: 32),
                  _buildConnectButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, _currentType),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conectividad',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              Text(
                'Conecta tu pastillero inteligente',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionFlow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Opciones de conexión',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          SizedBox(height: 12),
          // ✅ CAMBIO 4: Instrucciones actualizadas — conexiones independientes
          Text(
            '1) Activa Bluetooth para conectarte directamente con tu pastillero.',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '2) Activa WiFi para mantener el seguimiento y recibir avisos importantes.',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Puedes activar Bluetooth, WiFi o ambos de forma independiente según tus necesidades.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton(BuildContext context) {
    final isConnected = _currentType != ConnectionType.none;
    final btnText = (_bluetoothOn && _wifiOn)
        ? 'Bluetooth y WiFi activos'
        : _bluetoothOn
            ? 'Bluetooth activo'
            : _wifiOn
                ? 'WiFi activo'
                : 'Sin conexion';

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, _currentType),
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? AppColors.green : AppColors.navyLight,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnected ? Icons.check_circle_outline : Icons.link_off_rounded,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              btnText,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}