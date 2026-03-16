class StockAlertaMedicamentoInfo {
  final String nombre;
  final String? color;
  final String? presentacion;

  const StockAlertaMedicamentoInfo({
    required this.nombre,
    this.color,
    this.presentacion,
  });

  factory StockAlertaMedicamentoInfo.fromJson(Map<String, dynamic> json) {
    return StockAlertaMedicamentoInfo(
      nombre: (json['nombre'] ?? '') as String,
      color: json['color'] as String?,
      presentacion: json['presentacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'color': color,
        'presentacion': presentacion,
      };
}

class StockAlerta {
  final String id;
  final String userId;
  final String medicamentoId;
  final String tipo;
  final int? diasRestantes;
  final bool leida;
  final DateTime? createdAt;
  final StockAlertaMedicamentoInfo? medicamento;

  const StockAlerta({
    required this.id,
    required this.userId,
    required this.medicamentoId,
    required this.tipo,
    this.diasRestantes,
    required this.leida,
    this.createdAt,
    this.medicamento,
  });

  factory StockAlerta.fromJson(Map<String, dynamic> json) {
    final nested = json['medicamentos'];
    return StockAlerta(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      medicamentoId: (json['medicamento_id'] ?? '') as String,
      tipo: (json['tipo'] ?? '') as String,
      diasRestantes: json['dias_restantes'] as int?,
      leida: (json['leida'] ?? false) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      medicamento: nested is Map<String, dynamic>
          ? StockAlertaMedicamentoInfo.fromJson(nested)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'medicamento_id': medicamentoId,
        'tipo': tipo,
        'dias_restantes': diasRestantes,
        'leida': leida,
        'created_at': createdAt?.toIso8601String(),
        'medicamentos': medicamento?.toJson(),
      };
}

