import '../core/supabase_client.dart';
import '../models/ponto_model.dart';

/// Serviço de registro de pontos utilizando Supabase.
class PontoService {
  // Singleton pattern para permitir mockagem/injeção nos testes
  static PontoService _instance = PontoService();
  static PontoService get instance => _instance;
  static set instance(PontoService newInstance) => _instance = newInstance;

  /// Registra o ponto de um funcionário.
  Future<bool> registrarPonto(String userId) async {
    try {
      await supabase.from('pontos').insert({'user_id': userId});
      return true;
    } catch (e) {
      print('AUDIT ERROR: Falha ao registrar ponto para $userId. Detalhes: $e');
      throw Exception("Falha ao registrar ponto");
    }
  }

  /// Lista o histórico de pontos de um funcionário.
  Future<List<PontoModel>> listarPontos(String userId) async {
    try {
      final List<dynamic> response = await supabase
          .from('pontos')
          .select()
          .eq('user_id', userId)
          .order('data_hora', ascending: false);
      
      return response
          .map((item) => PontoModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('AUDIT ERROR: Falha ao listar pontos para $userId. Detalhes: $e');
      return [];
    }
  }

  // Atalhos estáticos para manter compatibilidade com os pseudocódigos
  static Future<bool> registrarPontoStatic(String userId) => instance.registrarPonto(userId);
  static Future<List<PontoModel>> listarPontosStatic(String userId) => instance.listarPontos(userId);
}
