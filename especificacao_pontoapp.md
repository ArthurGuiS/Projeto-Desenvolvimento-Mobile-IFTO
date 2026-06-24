# Especificações Técnicas - PontoApp

## 1. Configurações e Core

`/lib/core/supabase_client.dart`
- **ação:** criar
- **descrição:** Configurar e expor a instância global do cliente Supabase utilizando as variáveis de ambiente.
- **pseudocódigo:**
  ```text
  IMPORTAR 'package:supabase_flutter/supabase_flutter.dart'
  IMPORTAR 'package:flutter_dotenv/flutter_dotenv.dart'

  FUNCAO ASSINCRONA initSupabase():
      url = LER dotenv.env['SUPABASE_URL']
      anonKey = LER dotenv.env['SUPABASE_ANON_KEY']
      INICIALIZAR Supabase.initialize(url: url, anonKey: anonKey)
  FIM FUNCAO

  VARIAVEL GLOBAL supabase = Supabase.instance.client
  ```

## 2. Modelos de Dados

`/lib/models/usuario_model.dart`
- **ação:** criar
- **descrição:** Mapear a tabela de perfis de usuários retornada pelo banco de dados.
- **pseudocódigo:**
  ```text
  CLASSE UsuarioModel:
      ATRIBUTOS:
          String id
          String email
          String nome
          String role // 'admin' ou 'employee'
          String cpf
      
      METODO fromJson(Map json):
          RETORNAR novo UsuarioModel(
              id = json['id'],
              email = json['email'],
              nome = json['nome'],
              role = json['role'],
              cpf = json['cpf']
          )
  FIM CLASSE
  ```

`/lib/models/ponto_model.dart`
- **ação:** criar
- **descrição:** Mapear o histórico de registros de ponto.
- **pseudocódigo:**
  ```text
  CLASSE PontoModel:
      ATRIBUTOS:
          String id
          String userId
          DateTime dataHora
      
      METODO fromJson(Map json):
          RETORNAR novo PontoModel(
              id = json['id'],
              userId = json['user_id'],
              dataHora = PARSE_DATE(json['data_hora'])
          )
  FIM CLASSE
  ```

## 3. Serviços de Backend (Supabase)

`/lib/services/auth_service.dart`
- **ação:** criar
- **descrição:** Manipular o estado de autenticação e comunicação com Supabase Auth.
- **pseudocódigo:**
  ```text
  CLASSE AuthService:
      FUNCAO ASSINCRONA login(String email, String senha):
          TENTAR:
              resposta = supabase.auth.signInWithPassword(email: email, password: senha)
              usuarioDados = supabase.from('usuarios').select().eq('id', resposta.user.id).single()
              RETORNAR UsuarioModel.fromJson(usuarioDados)
          CAPTURAR ERRO e:
              LANCAR "Credenciais inválidas"
      FIM FUNCAO

      FUNCAO ASSINCRONA alterarPropriaSenha(String novaSenha):
          TENTAR:
              supabase.auth.updateUser(UserAttributes(password: novaSenha))
              RETORNAR verdadeiro
          CAPTURAR ERRO e:
              LANCAR "Erro ao atualizar senha"
      FIM FUNCAO

      FUNCAO ASSINCRONA logout():
          supabase.auth.signOut()
      FIM FUNCAO
  FIM CLASSE
  ```

`/lib/services/ponto_service.dart`
- **ação:** criar
- **descrição:** Realizar operações de inserção e leitura na tabela de pontos, baseando-se no ID do usuário.
- **pseudocódigo:**
  ```text
  CLASSE PontoService:
      FUNCAO ASSINCRONA registrarPonto(String userId):
          TENTAR:
              // Nota: A data_hora é inserida pelo banco usando DEFAULT now()
              supabase.from('pontos').insert({'user_id': userId})
              RETORNAR verdadeiro
          CAPTURAR ERRO e:
              LANCAR "Falha ao registrar ponto"
      FIM FUNCAO

      FUNCAO ASSINCRONA listarPontos(String userId):
          TENTAR:
              listaJson = supabase.from('pontos').select().eq('user_id', userId).order('data_hora', ascending: falso)
              RETORNAR listaJson.MAP(item => PontoModel.fromJson(item))
          CAPTURAR ERRO e:
              RETORNAR lista vazia
      FIM FUNCAO
  FIM CLASSE
  ```

## 4. Interfaces de Usuário (Views)

`/lib/views/login_page.dart`
- **ação:** criar
- **descrição:** Exibir formulário de acesso e direcionar de acordo com a `role` do usuário.
- **pseudocódigo:**
  ```text
  WIDGET LoginPage:
      ESTADO:
          String email = ""
          String senha = ""
          Booleano isLoading = falso

      METODO submeterFormulario():
          SE email vazio OU senha vazia:
              MOSTRAR ALERTA "Preencha os campos"
              RETORNAR
          
          isLoading = verdadeiro
          TENTAR:
              usuario = AuthService.login(email, senha)
              SE usuario.role == 'admin':
                  NAVEGAR PARA AdminHome()
              SENAO:
                  NAVEGAR PARA FuncionarioHome(usuario)
          CAPTURAR ERRO e:
              MOSTRAR ALERTA e.mensagem
          FINALMENTE:
              isLoading = falso
      FIM METODO

      METODO build():
          RETORNAR Tela contendo:
              - CampoTexto(onChange: setEmail)
              - CampoTextoOculto(onChange: setSenha)
              - Botao(texto: "Entrar", onPressed: submeterFormulario)
  FIM WIDGET
  ```

`/lib/views/funcionario/funcionario_home.dart`
- **ação:** criar
- **descrição:** Interface principal para o funcionário bater o ponto e ver seu histórico.
- **pseudocódigo:**
  ```text
  WIDGET FuncionarioHome(UsuarioModel usuario):
      ESTADO:
          Lista<PontoModel> historico = []

      METODO onInit():
          CARREGAR carregarHistorico()
      
      METODO carregarHistorico():
          historico = ASSINCRONO PontoService.listarPontos(usuario.id)
          ATUALIZAR TELA

      METODO baterPonto():
          sucesso = ASSINCRONO PontoService.registrarPonto(usuario.id)
          SE sucesso:
              MOSTRAR MENSAGEM "Ponto registrado com sucesso"
              carregarHistorico()
          SENAO:
              MOSTRAR MENSAGEM "Erro ao registrar"

      METODO build():
          RETORNAR Tela contendo:
              - Appbar com titulo "Olá, {usuario.nome}" e botao "Sair" e botao "Alterar Senha"
              - BotaoGrande(texto: "Bater Ponto", onPressed: baterPonto)
              - ListView(items: historico, render: item => Text(item.dataHora formatada))
  FIM WIDGET
  ```

`/lib/views/admin/admin_home.dart`
- **ação:** criar
- **descrição:** Painel administrativo contendo a listagem de todos os funcionários.
- **pseudocódigo:**
  ```text
  WIDGET AdminHome:
      ESTADO:
          Lista<UsuarioModel> funcionarios = []

      METODO onInit():
          funcionarios = ASSINCRONO supabase.from('usuarios').select().eq('role', 'employee')
          ATUALIZAR TELA

      METODO build():
          RETORNAR Tela contendo:
              - Appbar com titulo "Painel Admin" e botao "Sair"
              - Botao(texto: "Cadastrar Novo Funcionário", onPressed: NAVEGAR PARA CadastroFuncionario)
              - ListView(
                  items: funcionarios, 
                  render: func => ListTile(
                      texto: func.nome, 
                      onTap: NAVEGAR PARA DetalheFuncionario(func)
                  )
                )
  FIM WIDGET
  ```
