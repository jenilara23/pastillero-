import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../models/app_theme.dart';

class AlarmFormScreen extends StatefulWidget {
  final Alarm? alarm;
  const AlarmFormScreen({super.key, this.alarm});

  @override
  State<AlarmFormScreen> createState() => _AlarmFormScreenState();
}

class _AlarmFormScreenState extends State<AlarmFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _intervalMode = false;
  int _hour = 8;
  int _minute = 0;
  bool _isAM = true;
  int _intervalHours = 8;
  TimeOfDay _firstDose = TimeOfDay.now();
  List<bool> _days = [true, true, true, true, true, false, false];
  String _selectedColor = '#4a9ede';
  List<String> _calculatedTimes = [];

  bool get _isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (_isEditing) {
      final a = widget.alarm!;
      _titleCtrl.text = a.title;
      _descCtrl.text = a.description;
      final h = a.hour;
      _isAM = h < 12;
      _hour = h % 12 == 0 ? 12 : h % 12;
      _minute = a.minute;
      _days = List.from(a.days);
      _selectedColor = a.color;
      _intervalMode = a.intervalHours != null;
      _intervalHours = a.intervalHours ?? 8;
      _firstDose = TimeOfDay(hour: a.hour, minute: a.minute);
    } else {
      _isAM = now.hour < 12;
      _hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
      _minute = now.minute;
      _firstDose = TimeOfDay(hour: now.hour, minute: now.minute);
    }
    _calcIntervalTimes();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _calcIntervalTimes() {
    final times = <String>[];
    int totalMin = _firstDose.hour * 60 + _firstDose.minute;
    final count = (24 / _intervalHours).floor();
    for (int i = 0; i < count; i++) {
      final t = totalMin % (24 * 60);
      final h = (t ~/ 60) % 24;
      final m = t % 60;
      final ampm = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      times.add('$h12:${m.toString().padLeft(2, '0')} $ampm');
      totalMin += _intervalHours * 60;
    }
    setState(() => _calculatedTimes = times);
  }

  int get _hour24 {
    if (_isAM && _hour == 12) return 0;
    if (!_isAM && _hour != 12) return _hour + 12;
    return _hour;
  }

  void _saveAlarm() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor ingresa el nombre del medicamento')),
      );
      return;
    }

    final int finalHour;
    final int finalMinute;
    final int? finalInterval;
    final List<String> finalCalcTimes;

    if (_intervalMode) {
      finalHour = _firstDose.hour;
      finalMinute = _firstDose.minute;
      finalInterval = _intervalHours;
      finalCalcTimes = _calculatedTimes;
    } else {
      finalHour = _hour24;
      finalMinute = _minute;
      finalInterval = null;
      finalCalcTimes = [];
    }

    final alarm = Alarm(
      id: _isEditing ? widget.alarm!.id : DateTime.now().millisecondsSinceEpoch,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      hour: finalHour,
      minute: finalMinute,
      days: _days,
      enabled: _isEditing ? widget.alarm!.enabled : true,
      color: _selectedColor,
      intervalHours: finalInterval,
      calculatedTimes: finalCalcTimes,
    );

    Navigator.pop(context, alarm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _formCard(
                  '💊  Medicamento',
                  _buildTextField(_titleCtrl, 'Ej: Ibuprofeno 400mg',
                      Icons.medication_outlined),
                ),
                const SizedBox(height: 14),
                _formCard(
                  '📋  Descripción / Dosis',
                  _buildTextField(_descCtrl, 'Ej: 1 comprimido con comida',
                      Icons.notes_rounded),
                ),
                const SizedBox(height: 14),
                _buildTimeSection(),
                const SizedBox(height: 14),
                _formCard('📅  Días de la semana', _buildDaysSelector()),
                const SizedBox(height: 14),
                _formCard('🎨  Color de identificación', _buildColorPicker()),
                const SizedBox(height: 28),
                _buildSaveButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────── HEADER ──
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyLight],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 17),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Editar alarma' : 'Nueva alarma',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isEditing
                        ? 'Modifica los datos del recordatorio'
                        : 'Configura tu recordatorio de medicamento',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── CARD WRAPPER PARA SECCIONES ──
  Widget _formCard(String label, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
          TextEditingController ctrl, String hint, IconData icon) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 15, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.blue, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );

  // ──────────────────────────────────── SECCIÓN HORA ──
  Widget _buildTimeSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⏰  Hora de la alarma',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          // Mode toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.mintBg,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _modeTab('Hora específica', !_intervalMode,
                    () => setState(() => _intervalMode = false)),
                _modeTab('Cada X horas', _intervalMode,
                    () => setState(() => _intervalMode = true)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!_intervalMode) _buildManualPicker() else _buildIntervalPicker(),
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8)
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: active ? AppColors.navy : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildManualPicker() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _timeColumn(
            value: _hour,
            onUp: () => setState(() => _hour = (_hour % 12) + 1),
            onDown: () => setState(() => _hour = (_hour - 2 + 12) % 12 + 1),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              ':',
              style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy),
            ),
          ),
          _timeColumn(
            value: _minute,
            onUp: () => setState(() => _minute = (_minute + 1) % 60),
            onDown: () => setState(() => _minute = (_minute - 1 + 60) % 60),
            isMinute: true,
          ),
          const SizedBox(width: 20),
          Column(
            children: [
              _ampmBtn('AM', _isAM, () => setState(() => _isAM = true)),
              const SizedBox(height: 8),
              _ampmBtn('PM', !_isAM, () => setState(() => _isAM = false)),
            ],
          ),
        ],
      );

  Widget _timeColumn(
      {required int value,
      required VoidCallback onUp,
      required VoidCallback onDown,
      bool isMinute = false}) {
    final display = value.toString().padLeft(2, '0');
    return Column(
      children: [
        GestureDetector(
          onTap: onUp,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.mintBg, AppColors.mintDark],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.keyboard_arrow_up_rounded,
                color: AppColors.navy, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          display,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onDown,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.mintBg, AppColors.mintDark],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.navy, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _ampmBtn(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.navy : AppColors.bgColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: active ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      );

  Widget _buildIntervalPicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Repetir cada',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
              const Spacer(),
              Row(
                children: [
                  _intervalBtn(Icons.remove_rounded, () {
                    if (_intervalHours > 1) {
                      setState(() => _intervalHours--);
                      _calcIntervalTimes();
                    }
                  }),
                  Container(
                    width: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        '$_intervalHours',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.navy),
                      ),
                    ),
                  ),
                  _intervalBtn(Icons.add_rounded, () {
                    if (_intervalHours < 24) {
                      setState(() => _intervalHours++);
                      _calcIntervalTimes();
                    }
                  }),
                ],
              ),
              const SizedBox(width: 8),
              const Text('horas',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Primera toma',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _firstDose,
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme:
                            const ColorScheme.light(primary: AppColors.blue),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => _firstDose = picked);
                    _calcIntervalTimes();
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blueVeryLight, AppColors.blueLightBg],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blue, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 16, color: AppColors.blue),
                      const SizedBox(width: 6),
                      Text(
                        _firstDose.format(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_calculatedTimes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.mint.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Horarios calculados:',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _calculatedTimes
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );

  Widget _intervalBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
              color: AppColors.bgColor, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: AppColors.navy),
        ),
      );

  // ────────────────────────────────── SELECTOR DE DÍAS ──
  Widget _buildDaysSelector() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          return GestureDetector(
            onTap: () => setState(() => _days[i] = !_days[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _days[i]
                    ? const LinearGradient(
                        colors: [AppColors.navy, AppColors.navyLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _days[i] ? null : AppColors.bgColor,
                border: Border.all(
                  color: _days[i] ? AppColors.navy : AppColors.inputBorder,
                  width: 2,
                ),
                boxShadow: _days[i]
                    ? [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  dayNames[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _days[i] ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      );

  // ────────────────────────────────── COLOR PICKER ──
  Widget _buildColorPicker() => Row(
        children: AppColors.alarmColors.map((color) {
          final argb = color.toARGB32();
          final hex = '#${argb.toRadixString(16).substring(2)}';
          final isSelected = _selectedColor == hex;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = hex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.textDark : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.55),
                            blurRadius: 10,
                            spreadRadius: 2)
                      ]
                    : [],
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20)
                  : null,
            ),
          );
        }).toList(),
      );

  // ────────────────────────────────── BOTÓN GUARDAR ──
  Widget _buildSaveButton() => SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: _saveAlarm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            elevation: 10,
            shadowColor: AppColors.green.withValues(alpha: 0.4),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 22),
              SizedBox(width: 10),
              Text(
                'Guardar alarma',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      );
}
