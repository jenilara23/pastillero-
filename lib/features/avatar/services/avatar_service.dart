import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../perfil/models/perfil.dart';

class AvatarService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Perfil> leerPerfilActual() async {
    final response = await _client
        .from('perfiles')
        .select()
        .eq('id', _client.auth.currentUser!.id)
        .single();
    return Perfil.fromJson(response);
  }

  Future<String> subirImagen(File file) async {
    final userId = _client.auth.currentUser!.id;
    final storagePath = '$userId/avatar.png';

    await _client.storage.from('avatars').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/png',
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
    return publicUrl;
  }

  Future<void> guardarAvatarUrl(String publicUrl) async {
    await _client
        .from('perfiles')
        .update({'avatar_url': publicUrl})
        .eq('id', _client.auth.currentUser!.id);
  }

  Future<void> guardarAvatarConConfig(
    String publicUrl,
    Map<String, dynamic> avatarConfig,
  ) async {
    await _client
        .from('perfiles')
        .update({
          'avatar_url': publicUrl,
          'avatar_config': avatarConfig,
        })
        .eq('id', _client.auth.currentUser!.id);
  }

  Future<Map<String, dynamic>?> cargarConfigPrevia() async {
    final response = await _client
        .from('perfiles')
        .select('avatar_config')
        .eq('id', _client.auth.currentUser!.id)
        .single();

    final raw = response['avatar_config'];
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  // El paquete avatar_maker usa SharedPreferences local para su estado.
  Future<void> aplicarConfigLocal(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatarMakerSelectedOptions', jsonEncode(config));
  }

  Future<void> limpiarConfigLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatarMakerSelectedOptions');
    await prefs.remove('avatarMakerSVG');
  }

  void logDbError(PostgrestException e) {
    debugPrint('BD error: ${e.message}');
  }

  void logStorageError(StorageException e) {
    debugPrint('Storage error: ${e.message}');
  }
}

