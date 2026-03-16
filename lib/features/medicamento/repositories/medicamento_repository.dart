import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medicamento.dart';

class MedicamentoRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Medicamento>> obtenerMedicamentosConStock() async {
    try {
      final response = await _client
          .from('v_medicamentos_con_stock')
          .select()
          .order('nombre', ascending: true);

      return (response as List)
          .map((row) => Medicamento.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException {
      rethrow;
    }
  }

  Future<void> insertarMedicamento({
    required String nombre,
    required String presentacion,
    required String dosis,
    required int cantidadTotal,
    required String color,
    String? notas,
  }) async {
    try {
      await _client.from('medicamentos').insert({
        'user_id': _userId,
        'nombre': nombre,
        'presentacion': presentacion,
        'dosis': dosis,
        'cantidad_total': cantidadTotal,
        'cantidad_actual': cantidadTotal,
        'color': color,
        'notas': notas,
      });
    } on PostgrestException {
      rethrow;
    }
  }

  Future<void> actualizarMedicamento({
    required String medicamentoId,
    required String nuevoNombre,
    required String nuevaDosis,
    required String nuevaPresentacion,
    String? nuevasNotas,
  }) async {
    try {
      await _client.from('medicamentos').update({
        'nombre': nuevoNombre,
        'dosis': nuevaDosis,
        'presentacion': nuevaPresentacion,
        'notas': nuevasNotas,
      }).eq('id', medicamentoId).eq('user_id', _userId);
    } on PostgrestException {
      rethrow;
    }
  }

  Future<void> reabastecerStock({
    required String medicamentoId,
    required int nuevaCantidadTotal,
    required int nuevaCantidadActual,
  }) async {
    try {
      await _client.from('medicamentos').update({
        'cantidad_total': nuevaCantidadTotal,
        'cantidad_actual': nuevaCantidadActual,
      }).eq('id', medicamentoId).eq('user_id', _userId);
    } on PostgrestException {
      rethrow;
    }
  }

  Future<void> eliminarMedicamento(String medicamentoId) async {
    try {
      await _client
          .from('medicamentos')
          .delete()
          .eq('id', medicamentoId)
          .eq('user_id', _userId);
    } on PostgrestException {
      rethrow;
    }
  }

  Stream<List<Medicamento>> suscribirMedicamentosTiempoReal() {
    return _client
        .from('medicamentos')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .map((rows) => rows.map(Medicamento.fromJson).toList());
  }
}

