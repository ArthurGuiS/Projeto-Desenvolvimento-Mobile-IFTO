import 'package:flutter/material.dart';
import '../../models/usuario_model.dart';
import '../../models/ponto_model.dart';
import '../../services/ponto_service.dart';
import '../../services/auth_service.dart';
import '../login_page.dart';

/// Tela principal para o Funcionário registrar ponto e ver histórico.
class FuncionarioHome extends StatefulWidget {
  final UsuarioModel usuario;

  const FuncionarioHome({super.key, required this.usuario});

  @override
  State<FuncionarioHome> createState() => _FuncionarioHomeState();
}

class _FuncionarioHomeState extends State<FuncionarioHome> {
  List<PontoModel> _historico = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final pontos = await PontoService.instance.listarPontos(widget.usuario.id);
      setState(() {
        _historico = pontos;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _baterPonto() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final sucesso = await PontoService.instance.registrarPonto(widget.usuario.id);
      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ponto registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarHistorico();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', 'Erro ao registrar')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _alterarSenha() async {
    String novaSenha = "";
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alterar Minha Senha'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Digite a nova senha (mínimo 6 caracteres)',
              border: OutlineInputBorder(),
            ),
            onChanged: (valor) => novaSenha = valor,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (novaSenha.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('A senha deve ter no mínimo 6 caracteres.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                try {
                  await AuthService.instance.alterarPropriaSenha(novaSenha);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Senha alterada com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sair() async {
    await AuthService.instance.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  String _formatarDataHora(DateTime dateTime) {
    final dia = dateTime.day.toString().padLeft(2, '0');
    final mes = dateTime.month.toString().padLeft(2, '0');
    final ano = dateTime.year;
    final hora = dateTime.hour.toString().padLeft(2, '0');
    final minuto = dateTime.minute.toString().padLeft(2, '0');
    final segundo = dateTime.second.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$minuto:$segundo';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${widget.usuario.nome}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset_outlined),
            tooltip: 'Alterar Senha',
            onPressed: _alterarSenha,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Sair',
            onPressed: _sair,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: primaryColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Registro Eletrônico de Ponto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clique no botão abaixo para marcar seu ponto agora.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 80,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _baterPonto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.alarm_add, size: 28),
                                  SizedBox(width: 12),
                                  Text(
                                    'Bater Ponto',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Histórico de Marcações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _carregarHistorico,
                )
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _historico.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum ponto registrado ainda.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _historico.length,
                          itemBuilder: (context, index) {
                            final ponto = _historico[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: const Icon(Icons.access_time, color: Colors.blue),
                                ),
                                title: Text(
                                  _formatarDataHora(ponto.dataHora),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text('Registro realizado com sucesso'),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
