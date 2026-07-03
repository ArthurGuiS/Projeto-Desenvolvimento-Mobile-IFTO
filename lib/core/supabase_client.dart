import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

SupabaseClient? _mockSupabaseClient;

/// Permite definir um cliente Supabase mockado para fins de teste.
void setMockSupabaseClient(SupabaseClient client) {
  _mockSupabaseClient = client;
}

/// Inicializa a instância do Supabase usando as variáveis de ambiente.
Future<void> initSupabase() async {
  if (_mockSupabaseClient != null) return;
  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );
}

/// Expõe o cliente global do Supabase.
SupabaseClient get supabase => _mockSupabaseClient ?? Supabase.instance.client;
