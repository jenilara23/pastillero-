class RegistroToma {
  final int id;
  final String userId;
  final int alarmaId;
  final String medicamentoId;
  final int pastillasTomadas;
  final String estado;
  final DateTime? tomadaAt;

  const RegistroToma({
    required this.id,
    required this.userId,
    required this.alarmaId,
    required this.medicamentoId,
    required this.pastillasTomadas,
    required this.estado,
    this.tomadaAt,
  });

  factory RegistroToma.fromJson(Map<String, dynamic> json) => RegistroToma(
        id: (json['id'] ?? 0) as int,
        userId: (json['user_id'] ?? '') as String,
        alarmaId: (json['alarma_id'] ?? 0) as int,
        medicamentoId: (json['medicamento_id'] ?? '') as String,
        pastillasTomadas: (json['pastillas_tomadas'] ?? 0) as int,
        estado: (json['estado'] ?? '') as String,
        tomadaAt: json['tomada_at'] != null
            ? DateTime.tryParse(json['tomada_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'alarma_id': alarmaId,
        'medicamento_id': medicamentoId,
        'pastillas_tomadas': pastillasTomadas,
        'estado': estado,
        'tomada_at': tomadaAt?.toIso8601String(),
      };
}

