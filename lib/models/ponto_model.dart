/// Modelo de dados que representa um registro de ponto.
class PontoModel {
  final String id;
  final String userId;
  final DateTime dataHora;

  PontoModel({
    required this.id,
    required this.userId,
    required this.dataHora,
  });

  /// Converte um JSON do banco de dados (Supabase) para o modelo.
  factory PontoModel.fromJson(Map<String, dynamic> json) {
    return PontoModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      dataHora: json['data_hora'] != null
          ? DateTime.parse(json['data_hora'] as String)
          : DateTime.now(),
    );
  }

  /// Converte o modelo para JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'data_hora': dataHora.toIso8601String(),
    };
  }
}
