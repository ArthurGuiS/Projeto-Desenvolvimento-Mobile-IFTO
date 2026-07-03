import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../models/usuario_model.dart';
import '../../services/auth_service.dart';
import '../login_page.dart';
import 'cadastro_funcionario.dart';
import 'detalhe_funcionario.dart';

/// Painel administrativo para gerenciar funcionários.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  List<UsuarioModel> _funcionarios = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarFuncionarios();
  }

  Future<void> _carregarFuncionarios() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<dynamic> response = await supabase
          .from('usuarios')
          .select()
          .eq('role', 'employee');
      
      setState(() {
        _funcionarios = response
            .map((item) => UsuarioModel.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      print('Erro ao carregar funcionários: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _alterarSenhaAdmin() async {
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.password),
            tooltip: 'Alterar Minha Senha',
            onPressed: _alterarSenhaAdmin,
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
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CadastroFuncionario(),
                  ),
                );
                if (result == true) {
                  _carregarFuncionarios();
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Cadastrar Novo Funcionário'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lista de Colaboradores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _carregarFuncionarios,
                )
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _funcionarios.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum funcionário cadastrado.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _funcionarios.length,
                          itemBuilder: (context, index) {
                            final func = _funcionarios[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                  child: Text(
                                    func.nome.isNotEmpty ? func.nome[0].toUpperCase() : 'F',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  func.nome,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('CPF: ${func.cpf}\nE-mail: ${func.email}'),
                                isThreeLine: true,
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetalheFuncionario(usuario: func),
                                    ),
                                  );
                                },
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
