class Medicamento {
  final String id;
  final String userId;
  final String nombre;
  final String presentacion;
  final String dosis;
  final int cantidadTotal;
  final int cantidadActual;
  final String color;
  final String? notas;
  final String? imagenUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos de la vista v_medicamentos_con_stock
  final double? tomasPorDia;
  final int? diasRestantesEstimados;
  final String? estadoStock;

  const Medicamento({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.presentacion,
    required this.dosis,
    required this.cantidadTotal,
    required this.cantidadActual,
    required this.color,
    this.notas,
    this.imagenUrl,
    this.createdAt,
    this.updatedAt,
    this.tomasPorDia,
    this.diasRestantesEstimados,
    this.estadoStock,
  });

  factory Medicamento.fromJson(Map<String, dynamic> json) {
    double? tomas;
    final rawTomas = json['tomas_por_dia'];
    if (rawTomas is num) tomas = rawTomas.toDouble();

    return Medicamento(
      id: json['id'] as String,
      userId: (json['user_id'] ?? '') as String,
      nombre: (json['nombre'] ?? '') as String,
      presentacion: (json['presentacion'] ?? '') as String,
      dosis: (json['dosis'] ?? '') as String,
      cantidadTotal: (json['cantidad_total'] ?? 0) as int,
      cantidadActual: (json['cantidad_actual'] ?? 0) as int,
      color: (json['color'] ?? '#4a9ede') as String,
      notas: json['notas'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      tomasPorDia: tomas,
      diasRestantesEstimados: json['dias_restantes_estimados'] as int?,
      estadoStock: json['estado_stock'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'nombre': nombre,
        'presentacion': presentacion,
        'dosis': dosis,
        'cantidad_total': cantidadTotal,
        'cantidad_actual': cantidadActual,
        'color': color,
        'notas': notas,
        'imagen_url': imagenUrl,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'tomas_por_dia': tomasPorDia,
        'dias_restantes_estimados': diasRestantesEstimados,
        'estado_stock': estadoStock,
      };
}

