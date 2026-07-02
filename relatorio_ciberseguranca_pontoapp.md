# Relatório de Cibersegurança - PontoApp

**Nível de Profundidade da Inspeção:** <PROFUNDA>

Este documento apresenta uma análise detalhada de cibersegurança do aplicativo PontoApp (arquitetura Serverless com Flutter e Supabase), baseada nas melhores práticas de desenvolvimento seguro e no OWASP Top 10 (2021). 

Devido à natureza *Serverless* da aplicação (onde o front-end se comunica diretamente com o banco de dados via SDK), a superfície de ataque concentra-se fortemente nas políticas de acesso do banco de dados, gestão de credenciais e fluxos de autenticação.

---

## 1. Vulnerabilidades Identificadas

### Vulnerabilidade 1: Falta de Políticas de Segurança em Nível de Linha (RLS)
1. **Localização Exata:** Configuração do Banco de Dados Supabase (PostgreSQL) e `/lib/services/ponto_service.dart` (linha da inserção: `supabase.from('pontos').insert({'user_id': userId})`).
2. **Descrição do Problema:** Como o aplicativo se comunica diretamente com o Supabase utilizando uma chave pública (`anon_key`), a falta de configuração de *Row Level Security* (RLS) nas tabelas `usuarios` e `pontos` permite que qualquer pessoa com a chave pública possa realizar operações não autorizadas de leitura, inserção ou exclusão.
3. **Evidência:** ```dart
   // O Flutter envia o userId. Se não houver RLS no backend, um atacante pode 
   // interceptar a requisição e enviar o userId de outro funcionário.
   await supabase.from('pontos').insert({'user_id': userId});
   ```
4. **Impacto Potencial:** Um funcionário mal-intencionado (ou atacante externo que extraia a `anon_key` do app) pode registrar o ponto em nome de qualquer outro colaborador, ou ler o histórico completo de toda a empresa, violando a confidencialidade e a integridade dos dados.
5. **Nível de Severidade:** **Crítica**
6. **Recomendação de Correção:** Habilitar RLS no Supabase e criar políticas rigorosas (SQL).
   ```sql
   -- Configuração no Supabase (PostgreSQL)
   ALTER TABLE pontos ENABLE ROW LEVEL SECURITY;

   -- Política para permitir que o usuário insira apenas o seu próprio ponto
   CREATE POLICY "Usuários inserem seus próprios pontos" ON pontos
   FOR INSERT WITH CHECK (auth.uid() = user_id);

   -- Política para leitura
   CREATE POLICY "Usuários leem seus próprios pontos" ON pontos
   FOR SELECT USING (auth.uid() = user_id);
   ```
7. **Referências:** OWASP A01:2021 (Broken Access Control); CWE-285 (Improper Authorization).

---

### Vulnerabilidade 2: Validação de Dados Apenas no Client-Side (Bypass de Validação)
1. **Localização Exata:** `/lib/views/admin/cadastro_funcionario.dart` e `/lib/core/validators.dart`.
2. **Descrição do Problema:** As validações de CPF e E-mail foram implementadas em Dart (Frontend). Em uma arquitetura Serverless, atacantes podem ignorar o aplicativo Flutter e enviar requisições HTTP POST diretas para a API REST do Supabase. Sem validação no *backend* (Banco de Dados), dados corrompidos, XSS Stored ou CPFs falsos serão inseridos com sucesso.
3. **Evidência:** ```dart
   // A validação ocorre apenas no celular do Admin
   if (!Validators.isCpfValido(cpf)) { return; }
   // Nenhuma restrição correspondente no schema do banco de dados foi definida.
   ```
4. **Impacto Potencial:** Poluição do banco de dados, injeção de dados anômalos e possível introdução de *Stored XSS* caso os nomes ou dados inseridos contenham payloads JavaScript e sejam posteriormente exibidos em um painel Web (se criado no futuro).
5. **Nível de Severidade:** **Alta**
6. **Recomendação de Correção:** Criar restrições (`CHECK`) ou funções de validação no próprio PostgreSQL (Supabase). Sanitizar entradas para evitar injeções.
   ```sql
   -- Exemplo de restrição de domínio de E-mail no Postgres
   ALTER TABLE usuarios 
   ADD CONSTRAINT email_valido CHECK (email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');
   ```
7. **Referências:** OWASP A05:2021 (Injection) / A08:2021 (Software and Data Integrity Failures); CWE-602 (Client-Side Enforcement of Server-Side Security).

---

### Vulnerabilidade 3: Senhas Padrão Previsíveis sem Forçar Alteração
1. **Localização Exata:** `/lib/views/admin/cadastro_funcionario.dart` (Fluxo Lógico) e `/lib/views/login_page.dart`.
2. **Descrição do Problema:** O administrador cadastra usuários atribuindo-lhes uma senha padrão (`mudar123`). O aplicativo não obriga o funcionário a alterar essa senha no seu primeiro login, criando uma janela indefinida de vulnerabilidade.
3. **Evidência:** O sistema define que a conta criada recebe a senha `mudar123`, mas o `LoginPage` apenas redireciona para o `FuncionarioHome()` mediante sucesso, sem verificar o status da senha.
4. **Impacto Potencial:** Ataque de *Credential Stuffing* ou advinhação. Qualquer funcionário pode tentar logar na conta de recém-contratados usando e-mails previsíveis e a senha padrão, comprometendo as contas.
5. **Nível de Severidade:** **Alta**
6. **Recomendação de Correção:** Adicionar um campo booleano `precisa_alterar_senha` no banco. No Flutter, interceptar o login.
   ```dart
   // No AuthService.dart após o login:
   if (usuarioDados['precisa_alterar_senha'] == true) {
       // Disparar exceção específica ou retornar flag para o UI forçar a navegação
       // para a tela de 'Atualização Obrigatória de Senha' antes de acessar a Home.
   }
   ```
7. **Referências:** OWASP A07:2021 (Authentication Failures); CWE-521 (Weak Password Requirements).

---

### Vulnerabilidade 4: Exposição Potencial de Variáveis de Ambiente
1. **Localização Exata:** `/pubspec.yaml` e arquivo `.env` na raiz do projeto.
2. **Descrição do Problema:** Embora as credenciais do Supabase (`SUPABASE_URL` e `SUPABASE_ANON_KEY`) tenham sido isoladas em um arquivo `.env`, o documento de especificações carece da garantia técnica de exclusão desse arquivo no controle de versão (Git).
3. **Evidência:** Inexistência explícita de criação ou verificação do arquivo `.gitignore` para o `.env`.
4. **Impacto Potencial:** Exposição das chaves da infraestrutura em repositórios públicos (ex: GitHub). Se combinado com a Vulnerabilidade 1 (Falta de RLS), o atacante assume o controle total do banco de dados.
5. **Nível de Severidade:** **Média** (Torna-se *Crítica* se RLS estiver desativado).
6. **Recomendação de Correção:** Certificar-se de que o arquivo `.gitignore` na raiz do projeto do Flutter contenha a seguinte diretiva:
   ```text
   # .gitignore
   .env
   .env*
   ```
7. **Referências:** OWASP A02:2021 (Security Misconfiguration); CWE-200 (Exposure of Sensitive Information to an Unauthorized Actor).

---

### Vulnerabilidade 5: Falta de Registro de Logs e Alertas em Ações Sensíveis (Audit Trail)
1. **Localização Exata:** `/lib/services/auth_service.dart` e banco de dados Supabase.
2. **Descrição do Problema:** Exceções do tipo *catch* capturam falhas de autenticação (`"Credenciais inválidas"`), mas não há registro da anomalia. Se um atacante tentar realizar um ataque de força bruta contra uma conta, o sistema não irá alertar o administrador.
3. **Evidência:** ```dart
   catch (e) {
       // Nenhuma geração de log, apenas retorno para a UI
       throw "Credenciais inválidas";
   }
   ```
4. **Impacto Potencial:** Impossibilidade de realizar análise forense (Investigação de Incidentes) após um ataque. Falha em detectar ataques em andamento e em impor bloqueios temporários de IP (Rate Limiting).
5. **Nível de Severidade:** **Média**
6. **Recomendação de Correção:** Configurar o *Logflare* ou ativar as extensões de auditoria (`pgaudit`) no painel de administração do Supabase. No Flutter, implementar lógica para registrar múltiplas falhas de login.
7. **Referências:** OWASP A09:2021 (Security Logging and Alerting Failures); CWE-778 (Insufficient Logging).
