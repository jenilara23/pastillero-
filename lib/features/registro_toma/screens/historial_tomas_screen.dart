import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../models/registro_toma.dart';
import '../repositories/registro_toma_repository.dart';

class HistorialTomasScreen extends StatefulWidget {
  const HistorialTomasScreen({super.key});

  @override
  State<HistorialTomasScreen> createState() => _HistorialTomasScreenState();
}

class _HistorialTomasScreenState extends State<HistorialTomasScreen> {
  final RegistroTomaRepository _repo = RegistroTomaRepository();

  List<RegistroToma> _registros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.obtenerHistorial(limite: 100);
      if (mounted) setState(() => _registros = data);
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _formatFecha(DateTime? dt) {
    if (dt == null) return '--';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month  $hour:$min';
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'tomada':
        return AppColors.green;
      case 'omitida':
        return AppColors.red;
      case 'pospuesta':
        return AppColors.amber;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _estadoIcon(String estado) {
    switch (estado) {
      case 'tomada':
        return Icons.check_circle_rounded;
      case 'omitida':
        return Icons.cancel_rounded;
      case 'pospuesta':
        return Icons.schedule_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'tomada':
        return 'Tomada';
      case 'omitida':
        return 'Omitida';
      case 'pospuesta':
        return 'Pospuesta';
      default:
        return estado;
    }
  }

  // ─── Estadísticas rápidas ──────────────────────────────────────────────────
  int get _tomadas => _registros.where((r) => r.estado == 'tomada').length;
  int get _omitidas => _registros.where((r) => r.estado == 'omitida').length;
  int get _pospuestas => _registros.where((r) => r.estado == 'pospuesta').length;
  double get _cumplimiento =>
      _registros.isEmpty ? 0 : _tomadas / _registros.length;

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.mint,
        backgroundColor: AppColors.navy,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.mint))
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      child: Column(
        children: [
          Row(
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
                  Text('Historial de tomas',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  Text('Seguimiento de medicamentos',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 12)),
                ],
              ),
            ],
          ),
          if (!_loading && _registros.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildStatsRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statChip(
          Icons.check_circle_rounded,
          '$_tomadas',
          'Tomadas',
          AppColors.green,
        ),
        const SizedBox(width: 8),
        _statChip(
          Icons.cancel_rounded,
          '$_omitidas',
          'Omitidas',
          AppColors.red,
        ),
        const SizedBox(width: 8),
        _statChip(
          Icons.schedule_rounded,
          '$_pospuestas',
          'Pospuestas',
          AppColors.amber,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 16),
                const SizedBox(height: 4),
                Text(
                  '${(_cumplimiento * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    'cumplim.',
                    style: TextStyle(fontSize: 10, color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_registros.isEmpty) {
      return ListView(
        // Para que el RefreshIndicator funcione
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 60),
          Column(
            children: [
              Icon(Icons.history_rounded, color: Colors.white24, size: 64),
              SizedBox(height: 16),
              Text('Sin registros aún',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text(
                'Cuando tomes tu medicamento\naparecerá aquí el registro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ],
      );
    }

    // Agrupar por fecha
    final grouped = <String, List<RegistroToma>>{};
    for (final r in _registros) {
      final key = _dayKey(r.tomadaAt);
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final keys = grouped.keys.toList();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final key = keys[i];
        final items = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                key,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ),
            ...items.map(_buildRegistroCard),
          ],
        );
      },
    );
  }

  String _dayKey(DateTime? dt) {
    if (dt == null) return 'Sin fecha';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'HOY';
    if (diff == 1) return 'AYER';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$d/$m/$y';
  }

  Widget _buildRegistroCard(RegistroToma r) {
    final color = _estadoColor(r.estado);
    final icon = _estadoIcon(r.estado);
    final label = _estadoLabel(r.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.medicamentoId,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.pastillasTomadas} pastilla${r.pastillasTomadas != 1 ? 's' : ''}  ·  ${_formatFecha(r.tomadaAt)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

