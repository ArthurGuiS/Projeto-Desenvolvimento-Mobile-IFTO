import 'package:flutter_test/flutter_test.dart';
import 'package:pontoapp/models/usuario_model.dart';

void main() {
  group('UsuarioModel Tests', () {
    test('Desserialização de UsuarioModel a partir de JSON', () {
      // Pré-condição: Um mapa estático simulando o JSON retornado pelo Supabase
      final json = {
        'id': '123',
        'email': 'admin@empresa.com',
        'nome': 'Admin',
        'role': 'admin',
        'cpf': '00000000000',
        'precisa_alterar_senha': false
      };

      // Ação: Instanciar UsuarioModel.fromJson(json)
      final usuario = UsuarioModel.fromJson(json);

      // Resultado Esperado (Assert): O objeto criado deve ter a propriedade role igual a 'admin' e o nome igual a 'Admin'
      expect(usuario.role, 'admin');
      expect(usuario.nome, 'Admin');
      expect(usuario.id, '123');
      expect(usuario.email, 'admin@empresa.com');
      expect(usuario.cpf, '00000000000');
      expect(usuario.precisaAlterarSenha, false);
    });
  });
}
