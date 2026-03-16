import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../alarm/models/alarm.dart';
import '../../../core/theme/app_theme.dart';
import '../../alarm/models/alarm_storage.dart';
import '../../perfil/models/perfil.dart';
import '../../stock/models/stock_alerta.dart';
import '../../../core/config/supabase_service.dart';
import '../../alarm/services/notification_service.dart';
import '../../perfil/services/perfil_store.dart';
import '../../stock/repositories/stock_alerta_repository.dart';
import '../../registro_toma/repositories/registro_toma_repository.dart';
import '../../alarm/repositories/alarma_repository.dart';
import '../../alarm/screens/alarm_form_screen.dart';
import '../../connectivity/screens/connectivity_screen.dart';
import '../../avatar/avatar_page.dart';
import '../../avatar/widgets/avatar_preview.dart';
import '../../medicamento/screens/medicamentos_screen.dart';
import '../../perfil/screens/profile_screen.dart';
import '../../registro_toma/screens/historial_tomas_screen.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StockAlertaRepository _stockAlertaRepo = StockAlertaRepository();
  final RegistroTomaRepository _registroTomaRepo = RegistroTomaRepository();
  final AlarmaRepository _alarmaRepo = AlarmaRepository();

  List<Alarm> _alarms = [];
  List<StockAlerta> _stockNoLeidas = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _calendarAnchorDate = DateTime.now();
  double _calendarDragDx = 0;
  bool _loading = true;
  ConnectionType _connectionType = ConnectionType.none;
  StreamSubscription<List<StockAlerta>>? _stockSub;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _moveCalendarWindow(int days) {
    setState(() {
      _calendarAnchorDate = _dateOnly(_calendarAnchorDate.add(Duration(days: days)));
      _selectedDate = _dateOnly(_selectedDate.add(Duration(days: days)));
    });
  }

  void _onCalendarDragUpdate(DragUpdateDetails details) {
    _calendarDragDx += details.primaryDelta ?? 0;
    const trigger = 28.0;

    if (_calendarDragDx <= -trigger) {
      _calendarDragDx = 0;
      _moveCalendarWindow(1);
    } else if (_calendarDragDx >= trigger) {
      _calendarDragDx = 0;
      _moveCalendarWindow(-1);
    }
  }

  void _onCalendarDragEnd(_) {
    _calendarDragDx = 0;
  }

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    _subscribeStockAlerts();
    if (isLoggedIn && PerfilStore.instance.current == null) {
      PerfilStore.instance.loadCurrentPerfil();
    }
  }

  @override
  void dispose() {
    _stockSub?.cancel();
    super.dispose();
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
    if (isLoggedIn) {
      try {
        await _alarmaRepo.actualizarEstadoAlarma(
          alarmaId: id,
          nuevoEstado: _alarms[idx].enabled,
        );
      } on PostgrestException catch (e) {
        if (mounted) {
          _showSnack('No se pudo actualizar en Supabase: ${e.message}');
        }
      }
    }
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
    if (isLoggedIn) {
      try {
        await _alarmaRepo.eliminarAlarma(id);
      } on PostgrestException catch (e) {
        if (mounted) {
          _showSnack('No se pudo eliminar en Supabase: ${e.message}');
        }
      }
    }
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

  void _subscribeStockAlerts() {
    if (!isLoggedIn) return;
    _stockSub = _stockAlertaRepo.suscribirAlertasTiempoReal().listen((data) {
      if (!mounted) return;
      setState(() => _stockNoLeidas = data.where((a) => !a.leida).toList());
    });
  }

  int get _activeCount => _alarms.where((a) => a.enabled).length;

  bool _appliesToWeekday(Alarm alarm, int weekdayIdx) {
    final hasDays = alarm.days.any((d) => d);
    if (!hasDays) return true;
    return alarm.days[weekdayIdx];
  }

  String _perfilNombre(Perfil? perfil) {
    final nombre = perfil?.nombre.trim();
    return (nombre != null && nombre.isNotEmpty) ? nombre : 'Usuario';
  }


  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Alarmas que aplican para el día seleccionado en el calendario.
  /// Una alarma aplica si:
  ///   - Tiene el día específico activado, O
  ///   - No tiene ningún día activado (modo manual/diario)
  List<Alarm> get _alarmsForSelectedDay {
    final weekdayIdx = _selectedDate.weekday - 1; // Lun=0 … Dom=6
    return _alarms.where((a) => _appliesToWeekday(a, weekdayIdx)).toList();
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

  void _showConnectivityHint() {
    final isConnected = _connectionType != ConnectionType.none;
    final statusText = _connectionType == ConnectionType.wifi
        ? 'WiFi activo'
        : _connectionType == ConnectionType.bluetooth
            ? 'Bluetooth activo'
            : 'Sin conexión';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? AppColors.green.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isConnected
                        ? AppColors.green.withValues(alpha: 0.6)
                        : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _connectionType == ConnectionType.bluetooth
                      ? Icons.bluetooth_connected_rounded
                      : Icons.wifi_rounded,
                  color: isConnected ? AppColors.green : Colors.white38,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                statusText,
                style: TextStyle(
                  color: isConnected ? AppColors.green : Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Para conectar o configurar tu pastillero\nve al menú y abre Conectividad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(Icons.menu_rounded, size: 18),
                  label: const Text(
                    'Abrir menú',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
    return Drawer(
      backgroundColor: AppColors.navy,
      child: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<Perfil?>(
              valueListenable: PerfilStore.instance,
              builder: (context, perfil, _) {
                return DrawerHeader(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AvatarPreview(
                        avatarUrl: perfil?.avatarUrl,
                        nombre: _perfilNombre(perfil),
                        size: 64,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AvatarPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _perfilNombre(perfil),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Editar perfil',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            // ── Opciones ──
            _drawerItem(
              icon: Icons.person_outline_rounded,
              title: 'Perfil',
              subtitle: 'Ver tu información',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
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
            ValueListenableBuilder<Perfil?>(
              valueListenable: PerfilStore.instance,
              builder: (context, perfil, _) {
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: AvatarPreview(
                    avatarUrl: perfil?.avatarUrl,
                    nombre: _perfilNombre(perfil),
                    size: 32,
                  ),
                  title: const Text(
                    'Mi avatar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'Editar foto o avatar',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AvatarPage()),
                    );
                  },
                );
              },
            ),
            _drawerItem(
              icon: Icons.medication_outlined,
              title: 'Pastillero',
              subtitle: 'Gestionar medicamentos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MedicamentosScreen()),
                );
              },
            ),
            _drawerItem(
              icon: Icons.history_rounded,
              title: 'Historial de tomas',
              subtitle: 'Ver registros anteriores',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HistorialTomasScreen()),
                );
              },
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
                PerfilStore.instance.clear();
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
                ValueListenableBuilder<Perfil?>(
                  valueListenable: PerfilStore.instance,
                  builder: (context, perfil, _) => AvatarPreview(
                    avatarUrl: perfil?.avatarUrl,
                    nombre: _perfilNombre(perfil),
                    size: 44,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AvatarPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder<Perfil?>(
                  valueListenable: PerfilStore.instance,
                  builder: (context, perfil, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bienvenido de vuelta', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                        Text('${_perfilNombre(perfil)} 👋', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    );
                  },
                ),
                const Spacer(),
                // ── Indicador visual de conexión (solo informativo) ──
                GestureDetector(
                  onTap: _showConnectivityHint,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _connectionType != ConnectionType.none
                          ? AppColors.green.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _connectionType != ConnectionType.none
                            ? AppColors.green.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _connectionType == ConnectionType.bluetooth
                              ? Icons.bluetooth_connected_rounded
                              : _connectionType == ConnectionType.wifi
                                  ? Icons.wifi_rounded
                                  : Icons.wifi_rounded,
                          size: 18,
                          color: _connectionType != ConnectionType.none
                              ? AppColors.green
                              : Colors.white30,
                        ),
                        if (_connectionType == ConnectionType.none)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 8,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    _headerIconBtn(Icons.notifications_outlined,
                        onTap: _openStockAlertsSheet),
                    if (_stockNoLeidas.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            '${_stockNoLeidas.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                          ),
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
    final base = _dateOnly(_calendarAnchorDate);
    final days = List.generate(7, (i) => base.add(Duration(days: i - 3)));
    const dayNamesShort = ['Dom', 'Lun', 'Mar', 'Mier', 'Jue', 'Vie', 'Sáb'];

    return GestureDetector(
      onHorizontalDragUpdate: _onCalendarDragUpdate,
      onHorizontalDragEnd: _onCalendarDragEnd,
      onHorizontalDragCancel: () => _calendarDragDx = 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ...days.map((d) {
              final isSelected = _isSameDate(d, _selectedDate);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = _dateOnly(d);
                    _calendarAnchorDate = _dateOnly(d);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: isSelected ? 0.18 : 0.10),
                          blurRadius: isSelected ? 10 : 7,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
          ],
        ),
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
        child: GestureDetector(
          onTap: () => _openTakeOptions(alarm),
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
      ),
    );
  }

  Future<void> _openStockAlertsSheet() async {
    try {
      final alerts = await _stockAlertaRepo.obtenerAlertasNoLeidas();
      if (!mounted) return;
      setState(() => _stockNoLeidas = alerts);
    } on PostgrestException catch (e) {
      if (mounted) _showSnack(e.message);
      return;
    }

    if (_stockNoLeidas.isEmpty) {
      _showSnack('No tienes alertas de stock pendientes.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Alertas de stock',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ..._stockNoLeidas.map(
                  (alerta) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () async {
                        try {
                          await _stockAlertaRepo.marcarLeida(alerta.id);
                          if (!mounted) return;
                          setState(() {
                            _stockNoLeidas
                                .removeWhere((item) => item.id == alerta.id);
                          });
                        } on PostgrestException catch (e) {
                          if (mounted) _showSnack(e.message);
                        }
                      },
                      child: Row(
                      children: [
                        Icon(
                          alerta.tipo == 'agotado'
                              ? Icons.error_outline_rounded
                              : Icons.warning_amber_rounded,
                          color: alerta.tipo == 'agotado'
                              ? AppColors.red
                              : AppColors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Te quedan ${alerta.diasRestantes ?? 0} dias de ${alerta.medicamento?.nombre ?? 'tu medicamento'}',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await _stockAlertaRepo.marcarLeida(alerta.id);
                              if (!mounted) return;
                              setState(() {
                                _stockNoLeidas
                                    .removeWhere((item) => item.id == alerta.id);
                              });
                            } on PostgrestException catch (e) {
                              if (mounted) _showSnack(e.message);
                            }
                          },
                          child: const Text('Marcar leida'),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTakeOptions(Alarm alarm) async {
    if (alarm.medicamentoId == null || alarm.medicamentoId!.isEmpty) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Confirmar toma',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline,
                      color: AppColors.green),
                  title: const Text('Tomar'),
                  onTap: () => Navigator.pop(context, 'tomada'),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.remove_circle_outline, color: AppColors.red),
                  title: const Text('Omitir'),
                  onTap: () => Navigator.pop(context, 'omitida'),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule, color: AppColors.amber),
                  title: const Text('Posponer'),
                  onTap: () => Navigator.pop(context, 'pospuesta'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;

    try {
      await _registroTomaRepo.registrarToma(
        alarmaId: alarm.id,
        medicamentoId: alarm.medicamentoId!,
        estado: action,
        pastillasPorToma: alarm.pastillasPorToma,
      );
      if (mounted) _showSnack('Toma registrada: $action');
    } on PostgrestException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      if (mounted) _showSnack('Error inesperado: $e');
    }
  }
}
