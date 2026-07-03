import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pontoapp/core/supabase_client.dart';
import 'package:pontoapp/models/usuario_model.dart';
import 'package:pontoapp/services/auth_service.dart';
import 'package:pontoapp/views/login_page.dart';
import 'package:pontoapp/views/admin/admin_home.dart';

// Mocks para o AuthService e Supabase
class MockAuthService extends Mock implements AuthService {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

// Classes Fakes para simular Futures de forma totalmente segura e tipada
class FakePostgrestFilterBuilderList extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> _value;
  FakePostgrestFilterBuilderList(this._value);

  @override
  Future<R> then<R>(FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {Function? onError}) {
    return Future.value(_value).then(onValue, onError: onError);
  }
}

void main() {
  late MockAuthService mockAuthService;
  late MockSupabaseClient mockSupabase;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;

  setUp(() {
    mockAuthService = MockAuthService();
    mockSupabase = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();

    // Injeta o mock do serviço de autenticação
    AuthService.instance = mockAuthService;
    // Injeta o mock do Supabase client
    setMockSupabaseClient(mockSupabase);

    // Mocks do Supabase para evitar crash ao carregar a AdminHome
    when(() => mockSupabase.from('usuarios')).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilterBuilder);
    when(() => mockFilterBuilder.eq('role', 'employee')).thenAnswer((_) => FakePostgrestFilterBuilderList([]));
  });

  testWidgets('Interação na Tela de Login (LoginPage) com Sucesso de Redirecionamento', (WidgetTester tester) async {
    // Pré-condição: Injetar um Mock do AuthService
    when(() => mockAuthService.login('admin@empresa.com', '12345')).thenAnswer(
      (_) async => UsuarioModel(
        id: 'admin_123',
        email: 'admin@empresa.com',
        nome: 'Admin Teste',
        role: 'admin',
        cpf: '00000000000',
        precisaAlterarSenha: false,
      ),
    );

    // Renderiza o LoginPage no ambiente de testes
    await tester.pumpWidget(const MaterialApp(
      home: LoginPage(),
    ));

    // Ação: 1. Inserir texto "admin@empresa.com" no campo de e-mail
    final emailField = find.byKey(const Key('emailField'));
    expect(emailField, findsOneWidget);
    await tester.enterText(emailField, 'admin@empresa.com');

    // Ação: 2. Inserir "12345" no campo de senha
    final senhaField = find.byKey(const Key('senhaField'));
    expect(senhaField, findsOneWidget);
    await tester.enterText(senhaField, '12345');

    // Ação: 3. Simular o toque no botão "Entrar"
    final botaoEntrar = find.byKey(const Key('loginButton'));
    expect(botaoEntrar, findsOneWidget);
    await tester.tap(botaoEntrar);

    // Processa a micro-tarefa assíncrona de login e navegação
    await tester.pumpAndSettle();

    // Resultado Esperado (Assert): O mock do AuthService deve ser acionado com parâmetros corretos
    verify(() => mockAuthService.login('admin@empresa.com', '12345')).called(1);

    // Verificar se a navegação redirecionou para a tela AdminHome
    expect(find.byType(AdminHome), findsOneWidget);
  });
}
