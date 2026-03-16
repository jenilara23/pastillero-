import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import 'services/avatar_service.dart';

class AvatarUploadPage extends StatefulWidget {
  const AvatarUploadPage({super.key});

  @override
  State<AvatarUploadPage> createState() => _AvatarUploadPageState();
}

class _AvatarUploadPageState extends State<AvatarUploadPage> {
  final AvatarService _service = AvatarService();
  final ImagePicker _picker = ImagePicker();

  File? _selected;
  bool _saving = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 95,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer la imagen seleccionada')),
        );
      }
      return;
    }

    final pngBytes = img.encodePng(decoded);
    final tmpDir = await Directory.systemTemp.createTemp('avatar_upload_');
    final pngFile = File('${tmpDir.path}/avatar.png');
    await pngFile.writeAsBytes(pngBytes, flush: true);

    if (!mounted) return;
    setState(() => _selected = pngFile);
  }

  Future<void> _guardar() async {
    if (_selected == null) return;

    setState(() => _saving = true);
    try {
      final publicUrl = await _service.subirImagen(_selected!);
      await _service.guardarAvatarUrl(publicUrl);
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
      backgroundColor: AppColors.mintBg,
      appBar: AppBar(
        title: const Text('Subir foto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 18),
            if (_selected != null)
              CircleAvatar(
                radius: 80,
                backgroundImage: FileImage(_selected!),
              )
            else
              CircleAvatar(
                radius: 80,
                backgroundColor: AppColors.blueVeryLight,
                child: const Icon(Icons.image_outlined,
                    size: 44, color: AppColors.blue),
              ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir desde galería'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selected == null || _saving) ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

