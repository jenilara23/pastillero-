import 'dart:convert';

class Alarm {
  final int id;
  String title;
  String description;
  int hour;
  int minute;
  List<bool> days; // [L, M, Mi, J, V, S, D]
  bool enabled;
  String color;
  int? intervalHours; // null = manual, number = repeat every X hours
  List<String> calculatedTimes; // for interval mode

  Alarm({
    required this.id,
    required this.title,
    required this.description,
    required this.hour,
    required this.minute,
    required this.days,
    this.enabled = true,
    this.color = '#4a9ede',
    this.intervalHours,
    this.calculatedTimes = const [],
  });

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'hour': hour,
        'minute': minute,
        'days': days,
        'enabled': enabled,
        'color': color,
        'intervalHours': intervalHours,
        'calculatedTimes': calculatedTimes,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        hour: json['hour'],
        minute: json['minute'],
        days: List<bool>.from(json['days']),
        enabled: json['enabled'],
        color: json['color'],
        intervalHours: json['intervalHours'],
        calculatedTimes: List<String>.from(json['calculatedTimes'] ?? []),
      );

  static List<Alarm> listFromJson(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => Alarm.fromJson(e)).toList();
  }

  static String listToJson(List<Alarm> alarms) {
    return jsonEncode(alarms.map((a) => a.toJson()).toList());
  }
}
