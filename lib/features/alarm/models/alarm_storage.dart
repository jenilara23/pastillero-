import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'alarm.dart';
import '../../../core/config/supabase_service.dart';
import '../repositories/alarma_repository.dart';

class AlarmStorage {
  static const _localKey = 'pillcare_alarms';
  static final AlarmaRepository _alarmaRepo = AlarmaRepository();

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
      if (userId == null) return [];

      final alarms = await _alarmaRepo.obtenerAlarmasUsuario();
      debugPrint(
          '💾 [AlarmStorage] ${alarms.length} alarmas recuperadas de Supabase');
      return alarms;
    } on PostgrestException catch (e) {
      debugPrint('💾 [AlarmStorage] ERROR Supabase: ${e.message} (${e.code})');
      return [];
    } catch (e) {
      debugPrint('💾 [AlarmStorage] ERROR cargando de Supabase: $e');
      return [];
    }
  }

  // ─── Supabase: guardar (upsert completo) ─────────────────────────────────
  static Future<void> _saveToSupabase(List<Alarm> alarms) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await supabase.from('alarmas').delete().eq('user_id', userId);
      for (final alarm in alarms) {
        if (alarm.medicamentoId == null || alarm.medicamentoId!.isEmpty) {
          continue;
        }
        await _alarmaRepo.insertarAlarma(alarm);
      }
      debugPrint('💾 [AlarmStorage] Sincronizado con Supabase');
    } on PostgrestException catch (e) {
      debugPrint('💾 [AlarmStorage] ERROR Supabase: ${e.message} (${e.code})');
      await _saveLocal(alarms);
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
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final alarms = Alarm.listFromJson(jsonStr);
      debugPrint(
          '💾 [AlarmStorage] ${alarms.length} alarmas recuperadas localmente');
      return alarms;
    } catch (e) {
      debugPrint('💾 [AlarmStorage] ERROR parseando JSON local: $e');
      return [];
    }
  }

  // ─── Local: guardar ───────────────────────────────────────────────────────
  static Future<void> _saveLocal(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint(
        '💾 [AlarmStorage] Guardando ${alarms.length} alarmas localmente...');
    await prefs.setString(_localKey, Alarm.listToJson(alarms));
  }

}
