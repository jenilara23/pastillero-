import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../models/medicamento.dart';
import '../repositories/medicamento_repository.dart';

class MedicamentosScreen extends StatefulWidget {
  const MedicamentosScreen({super.key});

  @override
  State<MedicamentosScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends State<MedicamentosScreen> {
  final MedicamentoRepository _repo = MedicamentoRepository();

  List<Medicamento> _medicamentos = [];
  bool _loading = true;
  StreamSubscription<List<Medicamento>>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _sub = _repo.suscribirMedicamentosTiempoReal().listen(
      (meds) {
        if (!mounted) return;
        setState(() {
          _medicamentos = meds;
          _loading = false;
        });
      },
      onError: (_) {
        if (!mounted) return;
        _loadOnce();
      },
    );
  }

  Future<void> _loadOnce() async {
    try {
      final meds = await _repo.obtenerMedicamentosConStock();
      if (!mounted) return;
      setState(() {
        _medicamentos = meds;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (mounted) _showSnack(e.message);
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ─────────────────────────────────── BUILD ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mis Medicamentos',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              Text('${_medicamentos.length} registrados',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_medicamentos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medication_outlined,
                  color: Colors.white24, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Sin medicamentos aún',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toca el botón + para añadir\ntu primer medicamento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _medicamentos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildCard(_medicamentos[i]),
    );
  }

  Widget _buildCard(Medicamento med) {
    final color = hexToColor(med.color);
    final stockPct =
        med.cantidadTotal > 0 ? med.cantidadActual / med.cantidadTotal : 0.0;
    final estado = med.estadoStock ?? 'ok';
    final estadoColor = estado == 'agotado'
        ? AppColors.red
        : estado == 'bajo'
            ? AppColors.amber
            : AppColors.green;
    final estadoLabel = estado == 'agotado'
        ? 'Agotado'
        : estado == 'bajo'
            ? 'Stock bajo'
            : 'OK';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Cuerpo principal ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícono de color
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.medication_rounded, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(med.nombre,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: estadoColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(estadoLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: estadoColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('${med.presentacion} · ${med.dosis}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      if (med.notas != null && med.notas!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(med.notas!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Barra de stock ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stock: ${med.cantidadActual} / ${med.cantidadTotal}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted)),
                    if (med.diasRestantesEstimados != null)
                      Text('~${med.diasRestantesEstimados} días',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: estadoColor)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: stockPct.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.bgColor,
                    valueColor: AlwaysStoppedAnimation<Color>(estadoColor),
                  ),
                ),
              ],
            ),
          ),
          // ── Acciones ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                _actionBtn(
                  Icons.edit_outlined,
                  'Editar',
                  AppColors.blue,
                  () => _openForm(context, med: med),
                ),
                _actionBtn(
                  Icons.add_circle_outline_rounded,
                  'Reabastecer',
                  AppColors.green,
                  () => _openRestockDialog(context, med),
                ),
                _actionBtn(
                  Icons.delete_outline_rounded,
                  'Eliminar',
                  AppColors.red,
                  () => _confirmDelete(context, med),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ─────────────────────────────── FORMULARIO ──
  Future<void> _openForm(BuildContext context, {Medicamento? med}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicamentoFormSheet(
        existing: med,
        onSave: (nombre, presentacion, dosis, cantidad, color, notas) async {
          try {
            if (med == null) {
              await _repo.insertarMedicamento(
                nombre: nombre,
                presentacion: presentacion,
                dosis: dosis,
                cantidadTotal: cantidad,
                color: color,
                notas: notas,
              );
              if (mounted) _showSnack('Medicamento añadido ✓');
            } else {
              await _repo.actualizarMedicamento(
                medicamentoId: med.id,
                nuevoNombre: nombre,
                nuevaDosis: dosis,
                nuevaPresentacion: presentacion,
                nuevasNotas: notas,
              );
              if (mounted) _showSnack('Medicamento actualizado ✓');
            }
          } on PostgrestException catch (e) {
            if (mounted) _showSnack('Error: ${e.message}');
          }
        },
      ),
    );
  }

  // ─────────────────────────── REABASTECIMIENTO ──
  Future<void> _openRestockDialog(BuildContext context, Medicamento med) async {
    int nuevaCantidad = med.cantidadTotal;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Reabastecer',
                style: TextStyle(fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ajusta la cantidad total de "${med.nombre}"',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: nuevaCantidad > 1
                          ? () => setState(() => nuevaCantidad--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.navy,
                    ),
                    Container(
                      width: 72,
                      alignment: Alignment.center,
                      child: Text('$nuevaCantidad',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.navy)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => nuevaCantidad++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.navy,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _repo.reabastecerStock(
                      medicamentoId: med.id,
                      nuevaCantidadTotal: nuevaCantidad,
                      nuevaCantidadActual: nuevaCantidad,
                    );
                    if (mounted) _showSnack('Stock actualizado ✓');
                  } on PostgrestException catch (e) {
                    if (mounted) _showSnack('Error: ${e.message}');
                  }
                },
                child: const Text('Guardar',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        });
      },
    );
  }

  // ─────────────────────────────── ELIMINAR ──
  Future<void> _confirmDelete(BuildContext context, Medicamento med) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar medicamento',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            '¿Deseas eliminar "${med.nombre}"?\nEsta acción no se puede deshacer.',
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _repo.eliminarMedicamento(med.id);
        if (mounted) _showSnack('Medicamento eliminado');
      } on PostgrestException catch (e) {
        if (mounted) _showSnack('Error: ${e.message}');
      }
    }
  }
}

// ══════════════════════════════════════════════════════════
//  Hoja de formulario (crear / editar medicamento)
// ══════════════════════════════════════════════════════════
class _MedicamentoFormSheet extends StatefulWidget {
  final Medicamento? existing;
  final Future<void> Function(
    String nombre,
    String presentacion,
    String dosis,
    int cantidad,
    String color,
    String? notas,
  ) onSave;

  const _MedicamentoFormSheet({this.existing, required this.onSave});

  @override
  State<_MedicamentoFormSheet> createState() => _MedicamentoFormSheetState();
}

class _MedicamentoFormSheetState extends State<_MedicamentoFormSheet> {
  final _nombreCtrl = TextEditingController();
  final _presentacionCtrl = TextEditingController();
  final _dosisCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  int _cantidad = 30;
  String _color = '#4a9ede';
  bool _saving = false;

  static const _presentaciones = [
    'Comprimido',
    'Cápsula',
    'Jarabe',
    'Ampolleta',
    'Parche',
    'Otro',
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final m = widget.existing!;
      _nombreCtrl.text = m.nombre;
      _presentacionCtrl.text = m.presentacion;
      _dosisCtrl.text = m.dosis;
      _notasCtrl.text = m.notas ?? '';
      _cantidad = m.cantidadTotal;
      _color = m.color;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _presentacionCtrl.dispose();
    _dosisCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nombre = _nombreCtrl.text.trim();
    final presentacion = _presentacionCtrl.text.trim();
    final dosis = _dosisCtrl.text.trim();

    if (nombre.isEmpty || presentacion.isEmpty || dosis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos obligatorios')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(
        nombre,
        presentacion,
        dosis,
        _cantidad,
        _color,
        _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? '✏️  Editar medicamento' : '💊  Nuevo medicamento',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 20),
            _field(_nombreCtrl, 'Nombre del medicamento *',
                Icons.medication_outlined),
            const SizedBox(height: 12),
            // Presentación con sugerencias
            _presentacionField(),
            const SizedBox(height: 12),
            _field(_dosisCtrl, 'Dosis (ej: 500 mg) *', Icons.straighten_rounded),
            const SizedBox(height: 12),
            _field(_notasCtrl, 'Notas adicionales', Icons.notes_rounded,
                maxLines: 2),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              _sectionLabel('Cantidad inicial'),
              const SizedBox(height: 8),
              _cantidadRow(),
              const SizedBox(height: 16),
            ],
            _sectionLabel('Color de identificación'),
            const SizedBox(height: 8),
            _colorPicker(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  elevation: 6,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        _isEditing ? 'Actualizar' : 'Guardar medicamento',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.inputBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  Widget _presentacionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _presentacionCtrl,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Presentación *',
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.category_outlined,
                size: 18, color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.inputBorder, width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.inputBorder, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.blue, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _presentaciones.map((p) {
            final selected = _presentacionCtrl.text == p;
            return GestureDetector(
              onTap: () => setState(() => _presentacionCtrl.text = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.navy
                        : AppColors.inputBorder,
                    width: 1.5,
                  ),
                ),
                child: Text(p,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textMuted)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _cantidadRow() {
    return Row(
      children: [
        IconButton(
          onPressed:
              _cantidad > 1 ? () => setState(() => _cantidad--) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.navy,
        ),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text('$_cantidad',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy)),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _cantidad++),
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.navy,
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted));

  Widget _colorPicker() {
    return Row(
      children: AppColors.alarmColors.map((c) {
        final argb = c.toARGB32();
        final hex = '#${argb.toRadixString(16).substring(2)}';
        final selected = _color == hex;
        return GestureDetector(
          onTap: () => setState(() => _color = hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.textDark : Colors.transparent,
                width: 3,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: c.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2)
                    ]
                  : [],
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

