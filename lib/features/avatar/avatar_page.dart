import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pillcare/core/theme/app_theme.dart';
import 'package:pillcare/features/avatar/avatar_maker_page.dart';
import 'package:pillcare/features/avatar/avatar_upload_page.dart';
import 'package:pillcare/features/avatar/services/avatar_service.dart';
import 'package:pillcare/features/avatar/widgets/avatar_option_card.dart';
import 'package:pillcare/features/avatar/widgets/avatar_preview.dart';
import 'package:pillcare/features/perfil/models/perfil.dart';
import 'package:pillcare/features/perfil/services/perfil_store.dart';

class AvatarPage extends StatefulWidget {
  const AvatarPage({super.key});

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage> {
  final AvatarService _service = AvatarService();

  Perfil? _perfil;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPerfil();
  }

  Future<void> _loadPerfil() async {
    setState(() => _loading = true);
    try {
      final perfil = await _service.leerPerfilActual();
      if (!mounted) return;
      setState(() => _perfil = perfil);
    } on PostgrestException catch (e) {
      _service.logDbError(e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUploadPage() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AvatarUploadPage()),
    );
    await _afterChildSaved();
  }

  Future<void> _openMakerPage() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AvatarMakerPage()),
    );
    await _afterChildSaved();
  }

  Future<void> _afterChildSaved() async {
    await _loadPerfil();
    await PerfilStore.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _perfil?.nombre ?? 'Usuario';

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        title: const Text('Mi avatar'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.mint))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              children: [
                Center(
                  child: AvatarPreview(
                    avatarUrl: _perfil?.avatarUrl,
                    nombre: nombre,
                    size: 120,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elige cómo quieres personalizar tu avatar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                AvatarOptionCard(
                  title: 'Subir foto',
                  subtitle: 'Selecciona una imagen desde galería',
                  icon: Icons.photo_library_outlined,
                  onTap: _openUploadPage,
                ),
                const SizedBox(height: 12),
                AvatarOptionCard(
                  title: 'Crear avatar',
                  subtitle: 'Diseña tu avatar estilo Wii',
                  icon: Icons.person_outline_rounded,
                  onTap: _openMakerPage,
                ),
              ],
            ),
    );
  }
}

