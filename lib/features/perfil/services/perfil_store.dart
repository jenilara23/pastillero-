import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/perfil.dart';
import '../repositories/perfil_repository.dart';

class PerfilStore extends ValueNotifier<Perfil?> {
  PerfilStore._() : super(null);

  static final PerfilStore instance = PerfilStore._();
  final PerfilRepository _repository = PerfilRepository();

  Perfil? get current => value;

  Future<void> loadCurrentPerfil() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      value = null;
      return;
    }

    try {
      value = await _repository.obtenerPerfilActual();
    } on PostgrestException catch (e) {
      debugPrint('PerfilStore error: ${e.message} | code: ${e.code}');
      value = null;
    } catch (e) {
      debugPrint('PerfilStore error inesperado: $e');
      value = null;
    }
  }

  Future<void> refresh() => loadCurrentPerfil();

  Future<void> update({required String nombre, String? avatarUrl}) async {
    await _repository.actualizarPerfil(
      nuevoNombre: nombre,
      nuevaAvatarUrl: avatarUrl,
    );
    await loadCurrentPerfil();
  }

  Future<void> saveInitial({required String nombre, String? avatarUrl}) async {
    await _repository.guardarPerfilInicial(nombre: nombre, avatarUrl: avatarUrl);
    await loadCurrentPerfil();
  }

  void clear() => value = null;
}

