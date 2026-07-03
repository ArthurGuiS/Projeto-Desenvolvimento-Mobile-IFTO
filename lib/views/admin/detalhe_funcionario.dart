import 'package:flutter/material.dart';
import '../../models/usuario_model.dart';
import '../../models/ponto_model.dart';
import '../../services/ponto_service.dart';

/// Tela de visualização detalhada do histórico de ponto de um funcionário (exclusiva do admin).
class DetalheFuncionario extends StatefulWidget {
  final UsuarioModel usuario;

  const DetalheFuncionario({super.key, required this.usuario});

  @override
  State<DetalheFuncionario> createState() => _DetalheFuncionarioState();
}

class _DetalheFuncionarioState extends State<DetalheFuncionario> {
  List<PontoModel> _historico = [];
  bool _isLoading = false;

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.usuario.nome),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados do Colaborador',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('E-mail: ${widget.usuario.email}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.badge, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('CPF: ${widget.usuario.cpf}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.security, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Status: ${widget.usuario.precisaAlterarSenha ? "Senha Padrão (Pendente)" : "Senha Atualizada"}'),
                      ],
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
                  'Histórico de Registros',
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
                            'Nenhum ponto registrado por este funcionário.',
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
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[500]?.withOpacity(0.15),
                                  child: const Icon(Icons.access_time, color: Colors.blue),
                                ),
                                title: Text(
                                  _formatarDataHora(ponto.dataHora),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text('Registro de Ponto Eletrônico'),
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
