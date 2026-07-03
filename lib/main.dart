import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/login_page.dart';

Future<void> main() async {
  // Garantir que os bindings do Flutter estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente (.env)
  await dotenv.load(fileName: ".env");

  // Inicializar o Supabase antes de qualquer chamada ao SDK
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
    debug: true, // opcional, ajuda a depurar mensagens no console
  );

  // Só depois de tudo pronto iniciar a UI
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PontoApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          primary: Colors.blueAccent,
          secondary: Colors.blueAccent.shade700,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
