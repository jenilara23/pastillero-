import 'package:flutter/material.dart';
import '../models/app_theme.dart';

/// Tipo de conexión activa del pastillero
enum ConnectionType { none, bluetooth, wifi }

class ConnectivityScreen extends StatefulWidget {
  final ConnectionType initialType;
  const ConnectivityScreen({super.key, this.initialType = ConnectionType.none});

  @override
  State<ConnectivityScreen> createState() => _ConnectivityScreenState();
}

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  late bool _bluetoothOn;
  late bool _wifiOn;

  @override
  void initState() {
    super.initState();
    _bluetoothOn = widget.initialType == ConnectionType.bluetooth;
    _wifiOn = widget.initialType == ConnectionType.wifi;
  }

  ConnectionType get _currentType {
    if (_bluetoothOn) return ConnectionType.bluetooth;
    if (_wifiOn) return ConnectionType.wifi;
    return ConnectionType.none;
  }

  void _toggleBluetooth(bool val) {
    setState(() {
      _bluetoothOn = val;
      if (val) _wifiOn = false; // Solo una conexión activa a la vez
    });
  }

  void _toggleWifi(bool val) {
    setState(() {
      _wifiOn = val;
      if (val) _bluetoothOn = false; // Solo una conexión activa a la vez
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {
        // Retorna el tipo de conexión al hacer back
      },
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  _buildConnectionCard(
                    icon: Icons.bluetooth_rounded,
                    iconColor: AppColors.blue,
                    iconBg: AppColors.blue.withValues(alpha: 0.15),
                    title: 'Bluetooth',
                    subtitle: _bluetoothOn ? 'Activado' : 'Desactivado',
                    value: _bluetoothOn,
                    onChanged: _toggleBluetooth,
                  ),
                  const SizedBox(height: 14),
                  _buildConnectionCard(
                    icon: Icons.wifi_rounded,
                    iconColor: AppColors.purple,
                    iconBg: AppColors.purple.withValues(alpha: 0.15),
                    title: 'WiFi',
                    subtitle: _wifiOn ? 'Activado' : 'Desactivado',
                    value: _wifiOn,
                    onChanged: _toggleWifi,
                  ),
                  const SizedBox(height: 24),
                  _buildInfoBanner(),
                  const SizedBox(height: 24),
                  _buildConnectionGuide(),
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

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.white70, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Información',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                SizedBox(height: 4),
                Text(
                  'Mantén tu pastillero conectado para recibir recordatorios automáticos y sincronizar tus medicamentos en tiempo real.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionGuide() {
    const steps = [
      'Enciende tu pastillero inteligente',
      'Activa Bluetooth o WiFi en esta aplicación',
      'Presiona "Conectar" en el dispositivo deseado',
      'Espera la confirmación de conexión exitosa',
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Guía de conexión',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildConnectButton(BuildContext context) {
    final isConnected = _currentType != ConnectionType.none;
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
              isConnected ? 'Conexión activa' : 'Sin conexión',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
