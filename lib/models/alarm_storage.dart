import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm.dart';
import '../services/supabase_service.dart';

class AlarmStorage {
  static const _localKey = 'pillcare_alarms';

  // ─── Carga alarmas: Supabase si hay sesión, local si no ──────────────────
  static Future<List<Alarm>> loadAlarms() async {
    if (isLoggedIn) {
      debugPrint(
          '💾 [AlarmStorage] Cargando desde Supabase (Usuario: $currentUserId)');
      return _loadFromSupabase();
    } else {
      debugPrint('💾 [AlarmStorage] Cargando desde SharedPreferences (Local)');
      return _loadLocal();
    }
  }

  // ─── Guarda alarmas: Supabase si hay sesión, local si no ─────────────────
  static Future<void> saveAlarms(List<Alarm> alarms) async {
    if (isLoggedIn) {
      await _saveToSupabase(alarms);
    } else {
      await _saveLocal(alarms);
    }
  }

  // ─── Supabase: cargar ─────────────────────────────────────────────────────
  static Future<List<Alarm>> _loadFromSupabase() async {
    try {
      final userId = currentUserId;
      if (userId == null) return _defaultAlarms();

      final data = await supabase
          .from('alarmas')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      if (data.isEmpty) return _defaultAlarms();
      debugPrint(
          '💾 [AlarmStorage] ${data.length} alarmas recuperadas de Supabase');
      return data.map<Alarm>((row) => _fromRow(row)).toList();
    } catch (e) {
      debugPrint('💾 [AlarmStorage] ERROR cargando de Supabase: $e');
      return _defaultAlarms();
    }
  }

  // ─── Supabase: guardar (upsert completo) ─────────────────────────────────
  static Future<void> _saveToSupabase(List<Alarm> alarms) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      // Eliminar todas las alarmas del usuario y re-insertar
      await supabase.from('alarmas').delete().eq('user_id', userId);

      if (alarms.isEmpty) return;

      final rows = alarms.map((a) => _toRow(a, userId)).toList();
      await supabase.from('alarmas').insert(rows);
      debugPrint('💾 [AlarmStorage] Sincronizado con Supabase');
    } catch (e) {
      debugPrint('💾 [AlarmStorage] ERROR sincronizando con Supabase: $e');
      // Fallback a local si Supabase falla
      await _saveLocal(alarms);
    }
  }

  // ─── Local: cargar ────────────────────────────────────────────────────────
  static Future<List<Alarm>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_localKey);
    if (jsonStr == null || jsonStr.isEmpty) return _defaultAlarms();
    try {
      final alarms = Alarm.listFromJson(jsonStr);
      debugPrint(
          '💾 [AlarmStorage] ${alarms.length} alarmas recuperadas localmente');
      return alarms;
    } catch (e) {
      debugPrint('💾 [AlarmStorage] ERROR parseando JSON local: $e');
      return _defaultAlarms();
    }
  }

  // ─── Local: guardar ───────────────────────────────────────────────────────
  static Future<void> _saveLocal(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint(
        '💾 [AlarmStorage] Guardando ${alarms.length} alarmas localmente...');
    await prefs.setString(_localKey, Alarm.listToJson(alarms));
  }

  // ─── Conversión Alarm → fila de DB ───────────────────────────────────────
  static Map<String, dynamic> _toRow(Alarm a, String userId) => {
        'id': a.id,
        'user_id': userId,
        'title': a.title,
        'description': a.description,
        'hour': a.hour,
        'minute': a.minute,
        'days': a.days,
        'enabled': a.enabled,
        'color': a.color,
        'interval_hours': a.intervalHours,
        'calculated_times': a.calculatedTimes,
      };

  // ─── Conversión fila de DB → Alarm ───────────────────────────────────────
  static Alarm _fromRow(Map<String, dynamic> row) => Alarm(
        id: row['id'] as int,
        title: row['title'] as String,
        description: row['description'] as String? ?? '',
        hour: row['hour'] as int,
        minute: row['minute'] as int,
        days: List<bool>.from(row['days'] as List),
        enabled: row['enabled'] as bool? ?? true,
        color: row['color'] as String? ?? '#4a9ede',
        intervalHours: row['interval_hours'] as int?,
        calculatedTimes: List<String>.from(row['calculated_times'] ?? []),
      );

  // ─── Alarmas de ejemplo (primer inicio) ──────────────────────────────────
  static List<Alarm> _defaultAlarms() => [
        Alarm(
          id: 1,
          title: 'Ibuprofeno 400 mg',
          description: '1 comprimido con comida',
          hour: 18,
          minute: 0,
          days: [true, true, true, true, true, false, false],
          color: '#4a9ede',
          enabled: true,
        ),
        Alarm(
          id: 2,
          title: 'Vitamina D',
          description: '1 cápsula en ayunas',
          hour: 7,
          minute: 0,
          days: [true, true, true, true, true, true, true],
          color: '#48c774',
          enabled: true,
          intervalHours: 24,
        ),
      ];
}
