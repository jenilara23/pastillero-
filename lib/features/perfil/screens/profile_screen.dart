import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/perfil.dart';
import '../services/perfil_store.dart';
import '../../../core/config/supabase_service.dart';
import '../../avatar/avatar_page.dart';
import '../../avatar/widgets/avatar_preview.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (PerfilStore.instance.current == null && isLoggedIn) {
      _loadPerfil();
    }
  }

  Future<void> _loadPerfil() async {
    setState(() => _loading = true);
    await PerfilStore.instance.loadCurrentPerfil();
    if (mounted) setState(() => _loading = false);
  }

  String _perfilNombre(Perfil? perfil) {
    final nombre = perfil?.nombre.trim();
    return (nombre != null && nombre.isNotEmpty) ? nombre : 'Usuario';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ValueListenableBuilder<Perfil?>(
              valueListenable: PerfilStore.instance,
              builder: (context, perfil, _) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    _buildProfileCard(perfil),
                    _buildInfoSection(perfil),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfil',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Consulta tu información personal',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loading ? null : _loadPerfil,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Perfil? perfil) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          AvatarPreview(
            avatarUrl: perfil?.avatarUrl,
            nombre: _perfilNombre(perfil),
            size: 84,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AvatarPage()),
              );
              await _loadPerfil();
            },
          ),
          const SizedBox(height: 14),
          Text(
            _perfilNombre(perfil),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentUser?.email ?? 'Correo no disponible',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.blueVeryLight,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'Perfil del usuario',
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Perfil? perfil) {
    return _buildSectionCard(
      title: 'Información personal',
      children: [
        _buildInfoRow(
          icon: Icons.person_outline_rounded,
          title: 'Nombre completo',
          value: _perfilNombre(perfil),
        ),
        _buildDivider(),
        _buildInfoRow(
          icon: Icons.email_outlined,
          title: 'Correo electrónico',
          value: currentUser?.email ?? 'No disponible',
        ),
        _buildDivider(),
        _buildInfoRow(
          icon: Icons.image_outlined,
          title: 'Avatar',
          value: (perfil?.avatarUrl != null && perfil!.avatarUrl!.trim().isNotEmpty)
              ? 'Configurado'
              : 'Sin avatar personalizado',
        ),
      ],
    );
  }


  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(
        height: 1,
        indent: 54,
        color: AppColors.inputBorder,
      );
}

