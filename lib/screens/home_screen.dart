import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/alarm.dart';
import '../models/app_theme.dart';
import '../models/alarm_storage.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import 'alarm_form_screen.dart';
import 'connectivity_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Alarm> _alarms = [];
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  ConnectionType _connectionType = ConnectionType.none;

  String get _userName {
    final user = supabase.auth.currentUser;
    final metadata = user?.userMetadata;
    if (metadata != null && metadata.containsKey('nombre')) {
      return metadata['nombre'];
    }
    return 'jenifer';
  }

  String get _avatarLetter =>
      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'J';

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await AlarmStorage.loadAlarms();
    setState(() {
      _alarms = alarms;
      _loading = false;
    });
    await NotificationService.scheduleAllAlarms(alarms);
  }

  Future<void> _saveAlarms() async {
    await AlarmStorage.saveAlarms(_alarms);
  }

  Future<void> _toggleAlarm(int id) async {
    final idx = _alarms.indexWhere((a) => a.id == id);
    if (idx < 0) return;
    setState(() => _alarms[idx].enabled = !_alarms[idx].enabled);
    _saveAlarms();
    if (_alarms[idx].enabled) {
      await NotificationService.scheduleAlarm(_alarms[idx]);
    } else {
      await NotificationService.cancelAlarm(id);
    }
  }

  Future<void> _deleteAlarm(int id) async {
    await NotificationService.cancelAlarm(id);
    setState(() => _alarms.removeWhere((a) => a.id == id));
    _saveAlarms();
  }

  void _editAlarm(Alarm alarm) async {
    final updated = await Navigator.push<Alarm>(
      context,
      MaterialPageRoute(builder: (_) => AlarmFormScreen(alarm: alarm)),
    );
    if (updated != null) {
      setState(() {
        final idx = _alarms.indexWhere((a) => a.id == updated.id);
        if (idx >= 0) _alarms[idx] = updated;
      });
      _saveAlarms();
      await NotificationService.cancelAlarm(updated.id);
      if (updated.enabled) {
        await NotificationService.scheduleAlarm(updated);
      }
    }
  }

  void _newAlarm() async {
    final newAlarm = await Navigator.push<Alarm>(
      context,
      MaterialPageRoute(builder: (_) => const AlarmFormScreen()),
    );
    if (newAlarm != null) {
      setState(() => _alarms.add(newAlarm));
      _saveAlarms();
      if (newAlarm.enabled) {
        await NotificationService.scheduleAlarm(newAlarm);
      }
    }
  }

  int get _activeCount => _alarms.where((a) => a.enabled).length;

  /// Alarmas que aplican para el día seleccionado en el calendario.
  /// Una alarma aplica si:
  ///   - Tiene el día específico activado, O
  ///   - No tiene ningún día activado (modo manual/diario)
  List<Alarm> get _alarmsForSelectedDay {
    final weekdayIdx = _selectedDate.weekday - 1; // Lun=0 … Dom=6
    return _alarms.where((a) {
      final hasDays = a.days.any((d) => d);
      if (!hasDays) return true; // alarma diaria → siempre visible
      return a.days[weekdayIdx];
    }).toList();
  }

  Future<void> _openConnectivity() async {
    final result = await Navigator.push<ConnectionType>(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectivityScreen(initialType: _connectionType),
      ),
    );
    if (result != null && mounted) {
      setState(() => _connectionType = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.mint))
                : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final user = supabase.auth.currentUser;
    final metadata = user?.userMetadata;
    final name = (metadata != null && metadata.containsKey('nombre'))
        ? metadata['nombre'] as String
        : 'Usuario';
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Drawer(
      backgroundColor: AppColors.navy,
      child: SafeArea(
        child: Column(
          children: [
            // ── Avatar + nombre ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.blue,
                    child: Text(
                      letter,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            // ── Opciones ──
            _drawerItem(
              icon: Icons.medication_outlined,
              title: 'Pastillero',
              subtitle: 'Gestionar medicamentos',
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(
              icon: Icons.wifi_tethering_rounded,
              title: 'Conectividad',
              subtitle: 'Bluetooth y WiFi',
              onTap: () {
                Navigator.pop(context);
                _openConnectivity();
              },
            ),
            _drawerItem(
              icon: Icons.settings_outlined,
              title: 'Configuración',
              subtitle: 'Ajustes de la app',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(color: Colors.white12, height: 1),
            // ── Cerrar Sesión ──
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.red, size: 22),
              title: const Text('Cerrar Sesión',
                  style: TextStyle(
                      color: AppColors.red, fontWeight: FontWeight.w700)),
              onTap: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: AppColors.blueLight, size: 22),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
      onTap: onTap,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue.withValues(alpha: 0.6),
                  ),
                  child: Center(
                    child: Text(
                      _avatarLetter,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bienvenido de vuelta', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                    Text('$_userName 👋', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
                const Spacer(),
                // ── Icono dinámico de conexión ──
                GestureDetector(
                  onTap: _openConnectivity,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _connectionType != ConnectionType.none
                          ? AppColors.green.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _connectionType == ConnectionType.bluetooth
                          ? Icons.bluetooth_connected_rounded
                          : _connectionType == ConnectionType.wifi
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                      size: 20,
                      color: _connectionType != ConnectionType.none
                          ? AppColors.green
                          : Colors.white54,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    _headerIconBtn(Icons.notifications_outlined,
                        onTap: _mostrarNotificacionPrueba),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: const Text('2',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) => _headerIconBtn(Icons.menu,
                      onTap: () => Scaffold.of(context).openDrawer()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatsStrip(),
            const SizedBox(height: 20),
            _buildCalendarStrip(),
          ],
        ),
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsStrip() {
    return Row(
      children: [
        _statChip(Icons.alarm_on_rounded, '$_activeCount', 'activas'),
        const SizedBox(width: 8),
        _statChip(Icons.medication_outlined, '${_alarms.length}', 'medicamentos'),
        const SizedBox(width: 8),
        _statChip(Icons.calendar_today_rounded, '${_alarmsForSelectedDay.length}', 'hoy'),
      ],
    );
  }

  Widget _statChip(IconData icon, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildCalendarStrip() {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 3 - i)));
    const dayNamesShort = ['Dom', 'Lun', 'Mar', 'Mier', 'Jue', 'Vie', 'Sáb'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 12),
          ...days.map((d) {
            final isSelected = d.day == _selectedDate.day;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDate = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayNamesShort[d.weekday % 7],
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? AppColors.navy : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected ? AppColors.navy : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final alarmsDay = _alarmsForSelectedDay;
    final today = DateTime.now();
    final isToday = _selectedDate.day == today.day &&
        _selectedDate.month == today.month &&
        _selectedDate.year == today.year;

    // Nombre del día
    const longNames = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    final dayLabel = isToday
        ? 'Hoy'
        : longNames[_selectedDate.weekday - 1];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildNewAlarmCard(),
        const SizedBox(height: 25),
        Row(
          children: [
            Text(dayLabel,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${alarmsDay.length} alarmas',
                  style:
                      const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (alarmsDay.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Column(
              children: [
                Icon(Icons.event_available_outlined,
                    color: Colors.white24, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Sin alarmas para $dayLabel',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...alarmsDay.map((alarm) => _buildAlarmCard(alarm)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildNewAlarmCard() {
    return GestureDetector(
      onTap: _newAlarm,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.mint.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nueva alarma', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Añade un recordatorio de medicamento', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmCard(Alarm alarm) {
    final color = hexToColor(alarm.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Slidable(
        key: ValueKey(alarm.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _editAlarm(alarm),
              backgroundColor: Colors.blue,
              icon: Icons.edit,
              borderRadius: BorderRadius.circular(20),
            ),
            SlidableAction(
              onPressed: (_) => _deleteAlarm(alarm.id),
              backgroundColor: Colors.red,
              icon: Icons.delete,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              Container(width: 4, height: 60, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alarm.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    Text(alarm.description, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 5),
                    Text(alarm.daysString, style: const TextStyle(color: Colors.black38, fontSize: 11)),
                    if (alarm.intervalHours != null)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                        child: Text('Cada ${alarm.intervalHours}h', style: const TextStyle(fontSize: 10, color: AppColors.navy, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(alarm.timeString.split(' ')[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy)),
                  Text(alarm.timeString.split(' ')[1], style: const TextStyle(fontSize: 12, color: AppColors.navy, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Switch(
                    value: alarm.enabled,
                    onChanged: (_) => _toggleAlarm(alarm.id),
                    activeThumbColor: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarNotificacionPrueba() async {
    await NotificationService.showNow(id: 999, title: 'Prueba', body: 'Esta es una notificación de prueba');
  }
}
