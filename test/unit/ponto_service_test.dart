import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pontoapp/core/supabase_client.dart';
import 'package:pontoapp/services/ponto_service.dart';
import 'package:pontoapp/models/ponto_model.dart';

// Mocks com tipos de assinaturas corretos
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilderList extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

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
  late MockSupabaseClient mockSupabase;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilderList mockFilterBuilderList;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilderList = MockPostgrestFilterBuilderList();

    // Configura o Mock global do SupabaseClient
    setMockSupabaseClient(mockSupabase);
  });

  group('PontoService Tests', () {
    test('Registro de Ponto Bem-Sucedido', () async {
      // Pré-condição: Mock do Supabase configurado para retornar sucesso (sem erros)
      when(() => mockSupabase.from('pontos')).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert({'user_id': 'user_123'})).thenAnswer((_) => FakePostgrestFilterBuilderList([]));

      // Ação: Chamar PontoService.registrarPonto
      final service = PontoService();
      final resultado = await service.registrarPonto('user_123');

      // Resultado Esperado (Assert): A função deve retornar true.
      expect(resultado, isTrue);
      verify(() => mockQueryBuilder.insert({'user_id': 'user_123'})).called(1);
    });

    test('Listar Pontos do Usuário com Sucesso', () async {
      when(() => mockSupabase.from('pontos')).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select()).thenAnswer((_) => mockFilterBuilderList);
      when(() => mockFilterBuilderList.eq('user_id', 'user_123')).thenAnswer((_) => mockFilterBuilderList);
      
      final mockData = [
        {'id': 'p1', 'user_id': 'user_123', 'data_hora': '2026-07-02T10:00:00Z'},
        {'id': 'p2', 'user_id': 'user_123', 'data_hora': '2026-07-02T18:00:00Z'},
      ];
      
      when(() => mockFilterBuilderList.order('data_hora', ascending: false)).thenAnswer((_) => FakePostgrestFilterBuilderList(mockData));

      final service = PontoService();
      final resultado = await service.listarPontos('user_123');

      expect(resultado, isA<List<PontoModel>>());
      expect(resultado.length, 2);
      expect(resultado.first.id, 'p1');
      expect(resultado.last.id, 'p2');
    });
  });
}
