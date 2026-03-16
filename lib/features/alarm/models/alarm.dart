import 'dart:convert';

class Alarm {
  final int id;
  String? userId;
  String? medicamentoId;
  int pastillasPorToma;
  String title;
  String description;
  int hour;
  int minute;
  List<bool> days; // [L, M, Mi, J, V, S, D]
  bool enabled;
  String color;
  int? intervalHours; // null = manual, number = repeat every X hours
  List<String> calculatedTimes; // for interval mode
  DateTime? createdAt;

  Alarm({
    required this.id,
    this.userId,
    this.medicamentoId,
    this.pastillasPorToma = 1,
    required this.title,
    required this.description,
    required this.hour,
    required this.minute,
    required this.days,
    this.enabled = true,
    this.color = '#4a9ede',
    this.intervalHours,
    this.calculatedTimes = const [],
    this.createdAt,
  });

  static const _dayCodes = ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];

  String get timeString {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  String get daysString {
    const names = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
    final active = <String>[];
    for (int i = 0; i < days.length; i++) {
      if (days[i]) active.add(names[i]);
    }
    return active.join(' · ');
  }

  List<String> get supabaseDayCodes {
    final result = <String>[];
    for (int i = 0; i < days.length && i < _dayCodes.length; i++) {
      if (days[i]) result.add(_dayCodes[i]);
    }
    return result;
  }

  static List<bool> daysFromSupabaseCodes(dynamic value) {
    final mapped = List<bool>.filled(7, false);
    if (value is! List) return mapped;

    for (final entry in value) {
      final code = entry.toString().toLowerCase();
      final idx = _dayCodes.indexOf(code);
      if (idx >= 0) mapped[idx] = true;
    }
    return mapped;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'medicamentoId': medicamentoId,
        'pastillasPorToma': pastillasPorToma,
        'title': title,
        'description': description,
        'hour': hour,
        'minute': minute,
        'days': days,
        'enabled': enabled,
        'color': color,
        'intervalHours': intervalHours,
        'calculatedTimes': calculatedTimes,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'],
        userId: json['userId'],
        medicamentoId: json['medicamentoId'],
        pastillasPorToma: json['pastillasPorToma'] ?? 1,
        title: json['title'],
        description: json['description'],
        hour: json['hour'],
        minute: json['minute'],
        days: List<bool>.from(json['days']),
        enabled: json['enabled'],
        color: json['color'],
        intervalHours: json['intervalHours'],
        calculatedTimes: List<String>.from(json['calculatedTimes'] ?? []),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
      );

  factory Alarm.fromSupabase(Map<String, dynamic> row) => Alarm(
        id: row['id'] as int,
        userId: row['user_id'] as String?,
        medicamentoId: row['medicamento_id'] as String?,
        pastillasPorToma: row['pastillas_por_toma'] as int? ?? 1,
        title: row['title'] as String? ?? '',
        description: row['description'] as String? ?? '',
        hour: row['hour'] as int? ?? 8,
        minute: row['minute'] as int? ?? 0,
        days: daysFromSupabaseCodes(row['days']),
        enabled: row['enabled'] as bool? ?? true,
        color: row['color'] as String? ?? '#4a9ede',
        intervalHours: row['interval_hours'] as int?,
        calculatedTimes: List<String>.from(row['calculated_times'] ?? const []),
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toSupabaseInsert(String currentUserId) => {
        'id': id,
        'user_id': currentUserId,
        'medicamento_id': medicamentoId,
        'pastillas_por_toma': pastillasPorToma,
        'title': title,
        'color': color,
        'hour': hour,
        'minute': minute,
        'days': supabaseDayCodes,
        'interval_hours': intervalHours,
        'enabled': enabled,
        'calculated_times': calculatedTimes,
      };

  static List<Alarm> listFromJson(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => Alarm.fromJson(e)).toList();
  }

  static String listToJson(List<Alarm> alarms) {
    return jsonEncode(alarms.map((a) => a.toJson()).toList());
  }
}
