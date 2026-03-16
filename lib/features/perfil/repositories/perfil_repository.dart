import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/perfil.dart';

class PerfilRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<Perfil> obtenerPerfilActual() async {
    final response = await _client
        .from('perfiles')
        .select()
        .eq('id', _userId)
        .single();

    return Perfil.fromJson(response);
  }

  Future<void> actualizarPerfil({
    required String nuevoNombre,
    String? nuevaAvatarUrl,
  }) async {
    await _client.from('perfiles').update({
      'nombre': nuevoNombre,
      'avatar_url': nuevaAvatarUrl,
    }).eq('id', _userId);
  }

  Future<void> guardarPerfilInicial({
    required String nombre,
    String? avatarUrl,
  }) async {
    await _client.from('perfiles').upsert({
      'id': _userId,
      'nombre': nombre,
      'avatar_url': avatarUrl,
    });
  }
}

