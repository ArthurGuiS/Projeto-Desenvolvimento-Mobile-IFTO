import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/usuario_model.dart';

/// Serviço de autenticação integrado ao Supabase.
class AuthService {
  // Singleton pattern para permitir mockagem/injeção nos testes
  static AuthService _instance = AuthService();
  static AuthService get instance => _instance;
  static set instance(AuthService newInstance) => _instance = newInstance;

  /// Realiza o login do usuário.
  Future<UsuarioModel> login(String email, String senha) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: senha,
      );
      final user = response.user;
      if (user == null) {
        throw Exception("Usuário não encontrado.");
      }

      final usuarioDados = await supabase
          .from('usuarios')
          .select()
          .eq('id', user.id)
          .single();

      return UsuarioModel.fromJson(usuarioDados);
    } catch (e) {
      // Registro de log para auditoria (Mitigação da Vulnerabilidade 5)
      print('AUDIT WARNING: Falha na autenticação para o e-mail: $email. Detalhes: $e');
      throw Exception("Credenciais inválidas");
    }
  }

  /// Altera a senha do usuário autenticado.
  Future<bool> alterarPropriaSenha(String novaSenha) async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: novaSenha),
      );
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('usuarios')
            .update({'precisa_alterar_senha': false})
            .eq('id', user.id);
      }
      return true;
    } catch (e) {
      print('AUDIT ERROR: Falha ao alterar senha. Detalhes: $e');
      throw Exception("Erro ao atualizar senha");
    }
  }

  /// Desloga o usuário atual.
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      print('AUDIT ERROR: Falha ao realizar logout. Detalhes: $e');
    }
  }

  /// Cadastra um novo funcionário (usado pelo Admin).
  Future<bool> cadastrarFuncionario({
    required String email,
    required String senha,
    required String nome,
    required String cpf,
  }) async {
    try {
      // Cadastra o usuário no Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: senha,
        data: {
          'nome': nome,
          'role': 'employee',
          'cpf': cpf,
        },
      );
      
      final user = response.user;
      if (user != null) {
        // Se o trigger no banco de dados não estiver configurado localmente, insere manualmente no perfil
        await supabase.from('usuarios').insert({
          'id': user.id,
          'email': email,
          'nome': nome,
          'role': 'employee',
          'cpf': cpf,
          'precisa_alterar_senha': true,
        });
      }
      return true;
    } catch (e) {
      print('AUDIT ERROR: Falha ao cadastrar funcionário $email. Detalhes: $e');
      throw Exception("Erro ao cadastrar funcionário");
    }
  }

  // Atalhos estáticos para manter compatibilidade com os pseudocódigos
  static Future<UsuarioModel> loginStatic(String email, String senha) => instance.login(email, senha);
  static Future<bool> alterarPropriaSenhaStatic(String novaSenha) => instance.alterarPropriaSenha(novaSenha);
  static Future<void> logoutStatic() => instance.logout();
}
