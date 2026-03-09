import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── Canal Android de alta prioridad ──────────────────────────────────────
  static const _channel = AndroidNotificationChannel(
    'pillcare_alarms_v3',
    'Alarmas Críticas PillCare',
    description: 'Alertas de alta prioridad para medicamentos',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  // ── Inicializar el plugin ─────────────────────────────────────────────────
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    debugPrint('🔔 [NotificationService] Inicializando...');
    await _plugin.initialize(settings);

    // Crear el canal en Android
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    debugPrint('🔔 [NotificationService] Canal Android creado: ${_channel.id}');

    // Solicitar permiso de notificaciones (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Solicitar permiso de alarmas exactas (Android 12+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // ── Programar todas las alarmas de la lista ───────────────────────────────
  static Future<void> scheduleAllAlarms(List<Alarm> alarms) async {
    debugPrint(
        '🔔 [NotificationService] Reprogramando ${alarms.length} alarmas...');
    await _plugin.cancelAll();
    for (final alarm in alarms) {
      if (alarm.enabled) {
        await scheduleAlarm(alarm);
      }
    }
  }

  // ── Programar una alarma (todos sus días activos) ─────────────────────────
  static Future<void> scheduleAlarm(Alarm alarm) async {
    // Si tiene modo intervalo Y no tiene días específicos → notificación diaria
    final hasDays = alarm.days.any((d) => d);
    if (!hasDays) {
      debugPrint(
          '🔔 [NotificationService] Programando alarma "${alarm.title}" (diaria)');
      await _scheduleForDay(alarm, null);
      return;
    }

    // days = [L, M, Mi, J, V, S, D] → weekday de Dart: Mon=1 … Sun=7
    const dayMap = [1, 2, 3, 4, 5, 6, 7];
    for (int i = 0; i < alarm.days.length; i++) {
      if (alarm.days[i]) {
        debugPrint(
            '🔔 [NotificationService] Programando alarma "${alarm.title}" para día ${dayMap[i]}');
        await _scheduleForDay(alarm, dayMap[i]);
      }
    }
  }

  // ── Programar para un día concreto de la semana ───────────────────────────
  static Future<void> _scheduleForDay(Alarm alarm, int? weekday) async {
    // Usar hashCode para garantizar ID dentro del rango 32-bit de Android
    final base = alarm.id.hashCode.abs() % 200000000;
    final notifId = weekday == null ? base : base + weekday;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );

    // Si weekday está definido, avanzar hasta el próximo día correcto
    if (weekday != null) {
      while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    } else if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    debugPrint(
        '🔔 [NotificationService] Programando a: ${scheduled.toString()} (ID: $notifId)');

    await _plugin.zonedSchedule(
      notifId,
      '💊 ${alarm.title}',
      alarm.description.isNotEmpty
          ? alarm.description
          : 'Hora de tu medicamento',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ticker: 'Alarma de medicamento: ${alarm.title}',
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            alarm.description.isNotEmpty
                ? alarm.description
                : 'Hora de tu medicamento',
            summaryText: 'PillCare',
          ),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: weekday != null
          ? DateTimeComponents.dayOfWeekAndTime
          : DateTimeComponents.time,
    );
  }

  // ── Notificación inmediata (prueba) ──────────────────────────────────────
  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ticker: 'Prueba de Alarma',
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // ── Cancelar todas las notificaciones de una alarma ───────────────────────
  static Future<void> cancelAlarm(int alarmId) async {
    debugPrint('🔔 [NotificationService] Cancelando alarmas para ID: $alarmId');
    final base = alarmId.hashCode.abs() % 200000000;
    // Cancelar el caso sin día (base) y los 7 días posibles (base+1 … base+7)
    await _plugin.cancel(base);
    for (int i = 1; i <= 7; i++) {
      await _plugin.cancel(base + i);
    }
  }

  // ── Cancelar todas ───────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    debugPrint(
        '🔔 [NotificationService] Cancelando absolutamente todas las notificaciones');
    await _plugin.cancelAll();
  }
}
