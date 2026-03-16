class Perfil {
  final String id;
  final String nombre;
  final String? avatarUrl;
  final Map<String, dynamic>? avatarConfig;
  final DateTime? fechaNacimiento;
  final DateTime createdAt;

  Perfil({
    required this.id,
    required this.nombre,
    this.avatarUrl,
    this.avatarConfig,
    this.fechaNacimiento,
    required this.createdAt,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        avatarUrl: json['avatar_url'] as String?,
        avatarConfig: json['avatar_config'] != null
            ? Map<String, dynamic>.from(json['avatar_config'] as Map)
            : null,
        fechaNacimiento: json['fecha_nacimiento'] != null
            ? DateTime.parse(json['fecha_nacimiento'].toString())
            : null,
        createdAt: DateTime.parse(json['created_at'].toString()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'avatar_url': avatarUrl,
        'avatar_config': avatarConfig,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

