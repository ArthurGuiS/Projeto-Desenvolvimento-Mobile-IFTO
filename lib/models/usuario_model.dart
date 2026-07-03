/// Modelo de dados que representa um Usuário (Perfil).
class UsuarioModel {
  final String id;
  final String email;
  final String nome;
  final String role; // 'admin' ou 'employee'
  final String cpf;
  final bool precisaAlterarSenha;

  UsuarioModel({
    required this.id,
    required this.email,
    required this.nome,
    required this.role,
    required this.cpf,
    required this.precisaAlterarSenha,
  });

  /// Converte um JSON do banco de dados (Supabase) para o modelo.
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
      cpf: json['cpf'] as String? ?? '',
      precisaAlterarSenha: json['precisa_alterar_senha'] as bool? ?? false,
    );
  }

  /// Converte o modelo para JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'role': role,
      'cpf': cpf,
      'precisa_alterar_senha': precisaAlterarSenha,
    };
  }
}
