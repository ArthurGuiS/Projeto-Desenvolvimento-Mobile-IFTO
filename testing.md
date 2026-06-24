# Plano de Testes Automatizados - PontoApp (Abordagem TDD First)

## 1. Visão Geral e Estratégia
Este documento estabelece o plano de testes para o aplicativo **PontoApp**, adotando a metodologia **TDD (Test-Driven Development)**. A premissa central é que a escrita dos testes guie a implementação das lógicas de negócio e interfaces, funcionando como documentação viva e rede de segurança contra regressões.

Como estamos lidando com um aplicativo que se comunica ativamente com um serviço de nuvem (Supabase), a estratégia baseia-se em **Isolamento e Mocking**. O banco de dados real não será acionado durante a esteira de testes; em vez disso, simularemos as respostas da API do Supabase para garantir testes rápidos e determinísticos.

---

## 2. Gerenciamento de Dependências (Ecossistema Flutter)

*Nota de Adaptação: Diferente de projetos em Python que utilizam o `requirements.txt`, no desenvolvimento com o framework Flutter e linguagem Dart, o gerenciamento de dependências é feito através do arquivo `pubspec.yaml`.*

Para viabilizar os testes automatizados e a criação de Mocks (objetos simulados), você deve adicionar as seguintes bibliotecas na seção `dev_dependencies` do seu `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0  # Biblioteca moderna e amigável para criação de Mocks em Dart
  build_runner: ^2.4.0 # Utilizado para gerar códigos de cobertura e mocks complexos se necessário
```

---

## 3. Especificação dos Casos de Teste (Cenários Críticos)

### 3.1. Modelos de Dados (`/lib/models/`)
O cenário crítico é garantir que o aplicativo saiba converter o JSON recebido do banco de dados para os objetos Dart corretamente.

* **Teste 1: Desserialização de `UsuarioModel`**
  * **Pré-condição:** Um mapa estático simulando o JSON retornado pelo Supabase `{'id': '123', 'email': 'admin@empresa.com', 'nome': 'Admin', 'role': 'admin', 'cpf': '00000000000'}`.
  * **Ação:** Instanciar `UsuarioModel.fromJson(json)`.
  * **Resultado Esperado (Assert):** O objeto criado deve ter a propriedade `role` igual a `'admin'` e o `nome` igual a `'Admin'`.

### 3.2. Serviços de Autenticação (`/lib/services/auth_service.dart`)
O cenário crítico é validar as respostas de acesso e o tratamento de credenciais inválidas.

* **Teste 1: Login de Funcionário com Sucesso**
  * **Pré-condição:** Configurar o Mock do `SupabaseClient` para retornar um usuário válido com a role `employee` quando `signInWithPassword` for chamado.
  * **Ação:** Chamar `AuthService.login('func@empresa.com', 'mudar123')`.
  * **Resultado Esperado (Assert):** O método não deve lançar exceções e deve retornar uma instância de `UsuarioModel` com `role == 'employee'`.

* **Teste 2: Login com Senha Incorreta**
  * **Pré-condição:** Mock do Supabase lança uma `AuthException` simulando credenciais inválidas.
  * **Ação:** Chamar `AuthService.login('teste@teste.com', 'senhaerrada')`.
  * **Resultado Esperado (Assert):** O teste deve capturar (expect throws) uma exceção contendo a mensagem `"Credenciais inválidas"`.

### 3.3. Serviços de Ponto (`/lib/services/ponto_service.dart`)
O cenário crítico é garantir que o aplicativo tente inserir os dados enviando exatamente o ID do usuário, sem injetar horários manipulados localmente.

* **Teste 1: Registro de Ponto Bem-Sucedido**
  * **Pré-condição:** Mock do Supabase (`supabase.from('pontos').insert(...)`) configurado para retornar sucesso (sem erros).
  * **Ação:** Chamar `PontoService.registrarPonto('user_123')`.
  * **Resultado Esperado (Assert):** A função deve retornar `true`. O método `verify` do `mocktail` deve confirmar que `.insert({'user_id': 'user_123'})` foi chamado exatamente 1 vez.

### 3.4. Testes de Interface de Usuário (Widget Tests)
O cenário crítico é verificar se o preenchimento de campos e o clique de botões aciona as funções esperadas do sistema.

* **Teste 1: Interação na Tela de Login (`LoginPage`)**
  * **Pré-condição:** Injetar um Mock do `AuthService` no aplicativo e renderizar o `LoginPage` no ambiente de testes usando `testWidgets`.
  * **Ação:** 1. Inserir texto "admin@empresa.com" no campo de e-mail (`tester.enterText`).
    2. Inserir "12345" no campo de senha.
    3. Simular o toque no botão "Entrar" (`tester.tap`).
  * **Resultado Esperado (Assert):** O mock do `AuthService.login` deve ser acionado com os parâmetros corretos. Após o "sucesso" simulado pelo mock, verificar se a navegação (`Navigator`) tentou redirecionar para a tela `AdminHome`.

---

## 4. Estratégia de Automação e Anti-Regressão

Para garantir que futuras modificações no aplicativo não quebrem as regras estabelecidas:

1. **Comando de Teste Contínuo:** Durante o TDD, o desenvolvedor utilizará o comando `flutter test` no terminal para rodar toda a suíte de testes.
2. **Cobertura de Código (Coverage):** O projeto exigirá relatórios de cobertura. O comando `flutter test --coverage` será executado e o arquivo gerado `coverage/lcov.info` será analisado. A meta inicial é **80% de cobertura** das camadas `models` e `services`.
3. **CI/CD Integrado:** A esteira de integração contínua (ex: GitHub Actions) será configurada para rodar `flutter test` automaticamente em cada *Pull Request* (PR). Se algum teste unitário ou de widget falhar, o PR será bloqueado, impedindo que regressões cheguem à branch principal.
