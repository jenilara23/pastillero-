import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/stock_alerta.dart';

class StockAlertaRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<StockAlerta>> obtenerAlertasNoLeidas() async {
    try {
      final response = await _client
          .from('stock_alertas')
          .select('''
            *,
            medicamentos (nombre, color, presentacion)
          ''')
          .eq('user_id', _userId)
          .eq('leida', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => StockAlerta.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException {
      rethrow;
    }
  }

  Future<void> marcarLeida(String alertaId) async {
    try {
      await _client
          .from('stock_alertas')
          .update({'leida': true})
          .eq('id', alertaId)
          .eq('user_id', _userId);
    } on PostgrestException {
      rethrow;
    }
  }

  Stream<List<StockAlerta>> suscribirAlertasTiempoReal() {
    return _client
        .from('stock_alertas')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .map((rows) => rows
            .map((row) => StockAlerta.fromJson(row))
            .where((a) => a.leida == false)
            .toList());
  }
}

