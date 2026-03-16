import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AvatarPreview extends StatelessWidget {
  final String? avatarUrl;
  final String nombre;
  final double size;
  final VoidCallback? onTap;

  const AvatarPreview({
    super.key,
    required this.avatarUrl,
    required this.nombre,
    this.size = 40,
    this.onTap,
  });

  String get _initial {
    final trimmed = nombre.trim();
    return trimmed.isEmpty ? 'U' : trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    Widget initialFallback() => CircleAvatar(
          radius: size / 2,
          backgroundColor: AppColors.blue,
          child: Text(
            _initial,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size >= 56 ? 24 : size >= 40 ? 16 : 13,
            ),
          ),
        );

    final avatar = hasAvatar
        ? ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => initialFallback(),
              ),
            ),
          )
        : initialFallback();

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}

