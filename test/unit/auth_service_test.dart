import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pontoapp/core/supabase_client.dart';
import 'package:pontoapp/services/auth_service.dart';
import 'package:pontoapp/models/usuario_model.dart';

// Mocks com tipos de assinaturas corretos
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilderList extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}
class MockUser extends Mock implements User {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockUserResponse extends Mock implements UserResponse {}

// Classes Fakes para simular Futures de forma totalmente segura e tipada
class FakePostgrestTransformBuilderMap extends Fake implements PostgrestTransformBuilder<Map<String, dynamic>> {
  final Map<String, dynamic> _value;
  FakePostgrestTransformBuilderMap(this._value);

  @override
  Future<R> then<R>(FutureOr<R> Function(Map<String, dynamic> value) onValue, {Function? onError}) {
    return Future.value(_value).then(onValue, onError: onError);
  }
}

class FakePostgrestFilterBuilderList extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> _value;
  FakePostgrestFilterBuilderList(this._value);

  @override
  Future<R> then<R>(FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {Function? onError}) {
    return Future.value(_value).then(onValue, onError: onError);
  }
}

class UserAttributesFallback extends Fake implements UserAttributes {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockGoTrue;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilderList mockFilterBuilderList;
  late MockUser mockUser;
  late MockAuthResponse mockAuthResponse;
  late MockUserResponse mockUserResponse;

  setUpAll(() {
    registerFallbackValue(UserAttributesFallback());
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockGoTrue = MockGoTrueClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilderList = MockPostgrestFilterBuilderList();
    mockUser = MockUser();
    mockAuthResponse = MockAuthResponse();
    mockUserResponse = MockUserResponse();

    // Configura o Mock global do SupabaseClient
    setMockSupabaseClient(mockSupabase);
  });

  group('AuthService Tests', () {
    test('Login de Funcionário com Sucesso', () async {
      // Pré-condição: Configurar o Mock do SupabaseClient
      when(() => mockSupabase.auth).thenReturn(mockGoTrue);
      
      when(() => mockGoTrue.signInWithPassword(
        email: 'func@empresa.com',
        password: 'mudar123',
      )).thenAnswer((_) async => mockAuthResponse);
      
      when(() => mockAuthResponse.user).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user_123');

      final userData = {
        'id': 'user_123',
        'email': 'func@empresa.com',
        'nome': 'Funcionario Teste',
        'role': 'employee',
        'cpf': '111.111.111-11',
        'precisa_alterar_senha': false
      };

      when(() => mockSupabase.from('usuarios')).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilterBuilderList);
      when(() => mockFilterBuilderList.eq('id', 'user_123')).thenAnswer((_) => mockFilterBuilderList);
      // Retorna o Fake que implementa Future de forma limpa
      when(() => mockFilterBuilderList.single()).thenAnswer((_) => FakePostgrestTransformBuilderMap(userData));

      // Ação: Chamar AuthService.login
      final service = AuthService();
      final resultado = await service.login('func@empresa.com', 'mudar123');

      // Resultado Esperado (Assert)
      expect(resultado, isA<UsuarioModel>());
      expect(resultado.role, 'employee');
      expect(resultado.nome, 'Funcionario Teste');
    });

    test('Login com Senha Incorreta', () async {
      // Pré-condição: Mock do Supabase lança uma AuthException
      when(() => mockSupabase.auth).thenReturn(mockGoTrue);
      
      when(() => mockGoTrue.signInWithPassword(
        email: 'teste@teste.com',
        password: 'senhaerrada',
      )).thenThrow(const AuthException('Credenciais inválidas'));

      // Ação e Assert
      final service = AuthService();
      
      expect(
        () async => await service.login('teste@teste.com', 'senhaerrada'),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'mensagem', contains('Credenciais inválidas')),
        ),
      );
    });

    test('Alteração de Senha do Usuário', () async {
      when(() => mockSupabase.auth).thenReturn(mockGoTrue);
      
      // Mock para a atualização do auth
      when(() => mockGoTrue.updateUser(any())).thenAnswer((_) async => mockUserResponse);
      when(() => mockUserResponse.user).thenReturn(mockUser);
      
      // Mock para a atualização da tabela de perfis
      when(() => mockGoTrue.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user_123');
      
      when(() => mockSupabase.from('usuarios')).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.update({'precisa_alterar_senha': false})).thenAnswer((_) => mockFilterBuilderList);
      // O final da cadeia retorna o Fake do tipo FilterBuilder
      when(() => mockFilterBuilderList.eq('id', 'user_123')).thenAnswer((_) => FakePostgrestFilterBuilderList([]));

      final service = AuthService();
      final resultado = await service.alterarPropriaSenha('novaSenha123');

      expect(resultado, isTrue);
    });
  });
}
