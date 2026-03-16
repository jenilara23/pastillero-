import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import 'services/avatar_service.dart';

class AvatarMakerPage extends StatefulWidget {
  const AvatarMakerPage({super.key});

  @override
  State<AvatarMakerPage> createState() => _AvatarMakerPageState();
}

class _AvatarMakerPageState extends State<AvatarMakerPage> {
  final AvatarService _service = AvatarService();
  final GlobalKey _previewKey = GlobalKey();
  late final PersistentAvatarMakerController _controller;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = PersistentAvatarMakerController();
    _prepareEditor();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _prepareEditor() async {
    try {
      final config = await _service.cargarConfigPrevia();
      if (config != null) {
        await _controller.saveAvatarSVG(
          jsonAvatarOptions: jsonEncode(config),
        );
      }
    } on PostgrestException catch (e) {
      _service.logDbError(e);
    } catch (_) {
      // Si falla la carga previa, se permite editar con configuración local actual.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<File> _renderAvatarToPngFile() async {
    final boundary =
        _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final tmpDir = await Directory.systemTemp.createTemp('avatar_maker_');
    final file = File('${tmpDir.path}/avatar.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _guardarAvatar() async {
    setState(() => _saving = true);
    try {
      final avatarConfig = jsonDecode(_controller.getJsonOptionsSync())
          as Map<String, dynamic>;
      final file = await _renderAvatarToPngFile();
      final publicUrl = await _service.subirImagen(file);
      await _service.guardarAvatarConConfig(publicUrl, avatarConfig);

      if (mounted) Navigator.pop(context);
    } on StorageException catch (e) {
      _service.logStorageError(e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        title: const Text('Crear avatar'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.mint))
          : AvatarMakerControllerProvider(
              controller: _controller,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    key: _previewKey,
                    child: AvatarMakerAvatar(
                      controller: _controller,
                      radius: 64,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: AvatarMakerCustomizer(
                        controller: _controller,
                        autosave: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _guardarAvatar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text(
                                'Guardar avatar',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

