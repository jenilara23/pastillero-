import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsOn = true;
  bool _darkModeOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                _buildSectionCard(
                  title: 'General',
                  children: [
                    _buildToggleItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notificaciones',
                      subtitle: 'Recordatorios de medicamentos',
                      value: _notificationsOn,
                      onChanged: (v) => setState(() => _notificationsOn = v),
                    ),
                    _buildDivider(),
                    _buildToggleItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'Modo oscuro',
                      subtitle: 'Tema de la aplicación',
                      value: _darkModeOn,
                      onChanged: (v) => setState(() => _darkModeOn = v),
                    ),
                    _buildDivider(),
                    _buildArrowItem(
                      icon: Icons.language_outlined,
                      title: 'Idioma',
                      subtitle: 'Español',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Seguridad y Privacidad',
                  children: [
                    _buildArrowItem(
                      icon: Icons.shield_outlined,
                      title: 'Cambiar contraseña',
                      onTap: _cambiarContrasena,
                    ),
                    _buildDivider(),
                    _buildArrowItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Ayuda y soporte',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildVersionCard(),
              ],
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              Text(
                'Personaliza tu experiencia',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.navy),
        ],
      ),
    );
  }

  Widget _buildArrowItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(
        height: 1,
        indent: 54,
        color: AppColors.inputBorder,
      );

  Widget _buildVersionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Text(
            'Pastillero Smart',
            style: TextStyle(
                color: AppColors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Versión 2.0.1',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _cambiarContrasena() async {
    final email = currentUser?.email;
    if (email == null) return;
    try {
      await supabase.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Se envió un correo para cambiar tu contraseña'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
