import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/alarm.dart';
import '../models/app_theme.dart';
import '../models/alarm_storage.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import 'alarm_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Alarm> _alarms = [];
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  bool _pastilleroConectado = false;
  bool _conectando = false;

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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.navyLight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.blue,
                  child: Text(_avatarLetter, style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bluetooth_rounded, color: Colors.white),
            title: const Text('Pastillero', style: TextStyle(color: Colors.white)),
            subtitle: Text(_pastilleroConectado ? 'Conectado' : 'Desconectado', style: const TextStyle(color: Colors.white70)),
            onTap: () {
              Navigator.pop(context);
              _conectarPastillero();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.white),
            title: const Text('Configuración', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await supabase.auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
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
                    color: AppColors.blue.withOpacity(0.6),
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
                    Text('Bienvenido de vuelta', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                    Text('$_userName 👋', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
                const Spacer(),
                Stack(
                  children: [
                    _headerIconBtn(Icons.notifications_outlined, onTap: _mostrarNotificacionPrueba),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) => _headerIconBtn(Icons.menu, onTap: () => Scaffold.of(context).openDrawer()),
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
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsStrip() {
    return Row(
      children: [
        _statChip('9 activas'),
        const SizedBox(width: 10),
        _statChip('9 medic...'),
        const SizedBox(width: 10),
        _statChip('Hoy'),
      ],
    );
  }

  Widget _statChip(String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
            ),
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
        color: Colors.white.withOpacity(0.05),
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildNewAlarmCard(),
        const SizedBox(height: 25),
        Row(
          children: [
            const Text('Hoy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_alarms.length} alarmas', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (_alarms.isEmpty)
           const Padding(
             padding: EdgeInsets.only(top: 20),
             child: Center(child: Text('No hay alarmas para hoy', style: TextStyle(color: Colors.white54))),
           )
        else
          ..._alarms.map((alarm) => _buildAlarmCard(alarm)),
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
          color: AppColors.mint.withOpacity(0.8),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
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
                        decoration: BoxDecoration(color: AppColors.mint.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
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

  void _conectarPastillero() async {
    setState(() => _conectando = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _conectando = false;
      _pastilleroConectado = !_pastilleroConectado;
    });
  }

  Future<void> _mostrarNotificacionPrueba() async {
    await NotificationService.showNow(id: 999, title: 'Prueba', body: 'Esta es una notificación de prueba');
  }
}
