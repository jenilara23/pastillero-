import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF1E3A5F);
  static const navyLight = Color(0xFF2D5282);
  static const blue = Color(0xFF4A9EDE);
  static const blueLight = Color(0xFF72B8F0);
  static const mint = Color(0xFFB2E8E4);
  static const mintBg = Color(0xFFE8F8F7);
  static const mintDark = Color(0xFFD4F0ED);
  static const green = Color(0xFF48C774);
  static const red = Color(0xFFFF5A5F);
  static const amber = Color(0xFFFFB347);
  static const purple = Color(0xFFA29BFE);
  static const pink = Color(0xFFFD79A8);
  static const bgColor = Color(0xFFF0F4F8);
  static const white = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFF718096);
  static const textDark = Color(0xFF1A202C);

  // Colores reutilizables de UI
  static const blueGradientEnd = Color(0xFF3A6BA5);
  static const inputFill = Color(0xFFF8FAFC);
  static const inputBorder = Color(0xFFE2E8F0);
  static const blueVeryLight = Color(0xFFEDF7FF);
  static const blueLightBg = Color(0xFFD6EEFF);

  static const alarmColors = [
    Color(0xFF4A9EDE),
    Color(0xFF48C774),
    Color(0xFFFF5A5F),
    Color(0xFFFFB347),
    Color(0xFFA29BFE),
    Color(0xFFFD79A8),
  ];
}

Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

const List<String> dayNames = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
const List<String> dayNamesLong = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
];
const List<String> weekDaysShort = ['Lun', 'Mar', 'Mier', 'Jue', 'Vie', 'Sáb', 'Dom'];

// ── Constantes globales de la app ────────────────────────────────────────────
const kTimezone = 'America/Mexico_City';
const kNotifChannelId = 'pillcare_alarms_v3';
const kNotifChannelName = 'Alarmas Críticas PillCare';
