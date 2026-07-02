# Refatoração e Otimização - PontoApp

Este documento contém os passos granulares e isolados para aplicar as validações e melhorias solicitadas no projeto Flutter/Supabase. A arquitetura e a modularização foram preservadas.

## Etapa 1: Criação dos Validadores (E-mail e CPF)

Para mantermos o código modular e testável, vamos isolar as lógicas de validação em um arquivo central dentro da pasta `core`.

**Arquivo:** `/lib/core/validators.dart`
**Ação:** Criar
**Descrição:** Implementa as funções determinísticas para validar formato de e-mail e regras matemáticas de CPF.

```dart
// /lib/core/validators.dart

class Validators {
  /// Valida o formato padrão de um e-mail.
  static bool isEmailValido(String email) {
    if (email.isEmpty) return false;
    final RegExp regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  /// Valida o CPF através do cálculo de dígitos verificadores.
  static bool isCpfValido(String cpf) {
    // Remove qualquer caractere que não seja número
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Verifica tamanho ou se todos os números são iguais (ex: 00000000000)
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)*$').hasMatch(cpf)) return false;

    // Cálculo do primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int digit1 = 11 - (sum % 11);
    if (digit1 >= 10) digit1 = 0;

    // Cálculo do segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int digit2 = 11 - (sum % 11);
    if (digit2 >= 10) digit2 = 0;

    // Verifica se os dígitos calculados conferem com os do CPF
    return cpf[9] == digit1.toString() && cpf[10] == digit2.toString();
  }
}
```

---

## Etapa 2: Implementar Validações no Cadastro de Funcionário

Agora, integraremos os validadores na tela onde o administrador cadastra os novos colaboradores. O cadastro só avançará se os dados estiverem consistentes.

**Arquivo:** `/lib/views/admin/cadastro_funcionario.dart` (ou onde estiver sua lógica de formulário)
**Ação:** Modificar
**Descrição:** Adicionar as chamadas de validação antes de realizar a requisição ao Supabase.

```dart
// Importar o validador
// import '../../core/validators.dart';

// Dentro do Estado do seu Widget (ex: submeterFormulario()):

Future<void> submeterCadastro() async {
  String email = emailController.text.trim();
  String cpf = cpfController.text.trim();
  String nome = nomeController.text.trim();

  // 1. Validação de E-mail
  if (!Validators.isEmailValido(email)) {
    mostrarAlerta('O e-mail informado é inválido.');
    return;
  }

  // 2. Validação de CPF
  if (!Validators.isCpfValido(cpf)) {
    mostrarAlerta('O CPF informado é inválido. Verifique os dígitos.');
    return;
  }

  // 3. Validação de campos vazios
  if (nome.isEmpty) {
    mostrarAlerta('O nome é obrigatório.');
    return;
  }

  // Se tudo estiver correto, segue para criação (código existente)
  try {
    // Lógica para chamar o AuthService ou Supabase direto criando o usuário
    // ...
    mostrarAlerta('Funcionário cadastrado com sucesso!');
  } catch (e) {
    mostrarAlerta('Erro ao cadastrar funcionário.');
  }
}
```

---

## Etapa 3: Adicionar a Opção de Alterar Senha para o Admin

Na especificação original, o `AuthService` já possuía o método `alterarPropriaSenha()`. O que precisamos agora é adicionar o ponto de interação na interface do Administrador.

**Arquivo:** `/lib/views/admin/admin_home.dart`
**Ação:** Modificar
**Descrição:** Adicionar um botão no `AppBar` (ou menu) para o Admin chamar a função de redefinir sua própria senha.

```dart
// Adicione esta função na classe de Estado da AdminHome:
Future<void> alterarSenhaAdmin() async {
  // Para simplificar no nível de refatoração, abrimos um Dialog para pegar a nova senha.
  String novaSenha = "";
  
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Alterar Minha Senha'),
        content: TextField(
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Digite a nova senha'),
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
                // Alerta genérico de segurança básica
                return; 
              }
              try {
                // Chamada ao serviço já especificado na fase anterior
                await AuthService().alterarPropriaSenha(novaSenha);
                Navigator.pop(context);
                // Opcional: mostrar mensagem de sucesso via SnackBar
              } catch (e) {
                // Tratar erro
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    }
  );
}

// Modifique o método build() para incluir a ação na AppBar:
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Painel Admin'),
      actions: [
        IconButton(
          icon: const Icon(Icons.password),
          tooltip: 'Alterar Minha Senha',
          onPressed: alterarSenhaAdmin,
        ),
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          tooltip: 'Sair',
          onPressed: () {
            // Lógica de logout
          },
        ),
      ],
    ),
    body: // Código da lista de funcionários existente...
  );
}
```
