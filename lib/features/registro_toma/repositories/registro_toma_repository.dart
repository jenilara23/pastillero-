import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/registro_toma.dart';

class RegistroTomaRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<void> registrarToma({
    required int alarmaId,
    required String medicamentoId,
    required String estado,
    required int pastillasPorToma,
  }) async {
    try {
      await _client.rpc('registrar_toma', params: {
        'p_alarma_id': alarmaId,
        'p_medicamento_id': medicamentoId,
        'p_estado': estado,
        'p_pastillas': pastillasPorToma,
      });
    } on PostgrestException catch (e) {
      debugPrint('Supabase error: ${e.message} | code: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      rethrow;
    }
  }

  /// Devuelve el historial de tomas del usuario, ordenado por fecha desc.
  /// [limite] limita los resultados (por defecto 50).
  Future<List<RegistroToma>> obtenerHistorial({int limite = 50}) async {
    try {
      final response = await _client
          .from('registro_tomas')
          .select()
          .eq('user_id', _userId)
          .order('tomada_at', ascending: false)
          .limit(limite);

      return (response as List)
          .map((row) => RegistroToma.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('Supabase error: ${e.message} | code: ${e.code}');
      rethrow;
    }
  }

  /// Historial filtrado por medicamento.
  Future<List<RegistroToma>> obtenerHistorialPorMedicamento(
      String medicamentoId) async {
    try {
      final response = await _client
          .from('registro_tomas')
          .select()
          .eq('user_id', _userId)
          .eq('medicamento_id', medicamentoId)
          .order('tomada_at', ascending: false)
          .limit(100);

      return (response as List)
          .map((row) => RegistroToma.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('Supabase error: ${e.message} | code: ${e.code}');
      rethrow;
    }
  }
}



