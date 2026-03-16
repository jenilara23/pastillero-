import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alarm.dart';

class AlarmaRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Alarm>> obtenerAlarmasPorMedicamento(String medicamentoId) async {
    try {
      final response = await _client
          .from('alarmas')
          .select()
          .eq('medicamento_id', medicamentoId)
          .eq('user_id', _userId)
          .order('hour', ascending: true);

      return (response as List)
          .map((row) => Alarm.fromSupabase(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException {
      rethrow;
    }
  }

  Future<List<Alarm>> obtenerAlarmasUsuario() async {
    try {
      final response = await _client
          .from('alarmas')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((row) => Alarm.fromSupabase(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException {
      rethrow;
    }
  }

  Future<void> insertarAlarma(Alarm alarma) async {
    if (alarma.medicamentoId == null || alarma.medicamentoId!.isEmpty) {
      throw PostgrestException(
        message: 'Selecciona un medicamento para crear la alarma.',
      );
    }

    try {
      await _client.from('alarmas').insert({
        'id': alarma.id,
        'user_id': _userId,
        'medicamento_id': alarma.medicamentoId,
        'pastillas_por_toma': alarma.pastillasPorToma,
        'title': alarma.title,
        'color': alarma.color,
        'hour': alarma.hour,
        'minute': alarma.minute,
        'days': alarma.supabaseDayCodes,
        'interval_hours': alarma.intervalHours,
        'enabled': true,
        'calculated_times': alarma.calculatedTimes,
      });
    } on PostgrestException {
      rethrow;
    }
  }

  Future<void> actualizarEstadoAlarma({
    required int alarmaId,
    required bool nuevoEstado,
  }) async {
    try {
      await _client
          .from('alarmas')
          .update({'enabled': nuevoEstado})
          .eq('id', alarmaId)
          .eq('user_id', _userId);
    } on PostgrestException {
      rethrow;
    }
  }

  Future<void> eliminarAlarma(int alarmaId) async {
    try {
      await _client
          .from('alarmas')
          .delete()
          .eq('id', alarmaId)
          .eq('user_id', _userId);
    } on PostgrestException {
      rethrow;
    }
  }
}

