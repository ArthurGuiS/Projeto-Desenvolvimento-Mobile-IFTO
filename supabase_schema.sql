-- Schema do Banco de Dados para o PontoApp
-- Este script pode ser executado no editor SQL do console do Supabase.

-- =========================================================================
-- 1. TABELA DE USUÁRIOS (Perfis)
-- =========================================================================

CREATE TABLE IF NOT EXISTS public.usuarios (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    nome VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'employee')),
    cpf VARCHAR(14) NOT NULL UNIQUE,
    precisa_alterar_senha BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Restrições de Validação no Banco de Dados (Mitigação da Vulnerabilidade 2)
    CONSTRAINT email_valido CHECK (email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
    CONSTRAINT cpf_valido CHECK (length(regexp_replace(cpf, '[^0-9]', '', 'g')) = 11)
);

-- =========================================================================
-- 2. TABELA DE PONTOS (Histórico de Registros)
-- =========================================================================

CREATE TABLE IF NOT EXISTS public.pontos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    data_hora TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- =========================================================================
-- 3. POLÍTICAS DE SEGURANÇA (Row Level Security - Mitigação da Vulnerabilidade 1)
-- =========================================================================

-- Habilitando RLS nas tabelas
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pontos ENABLE ROW LEVEL SECURITY;

-- Políticas para a tabela 'usuarios'
CREATE POLICY "Usuários leem seus próprios perfis" ON public.usuarios
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins gerenciam todos os perfis" ON public.usuarios
    FOR ALL USING (auth.jwt()->>'role' = 'admin');

-- Políticas para a tabela 'pontos'
CREATE POLICY "Usuários inserem seus próprios pontos" ON public.pontos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários leem seus próprios pontos" ON public.pontos
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins leem todos os pontos" ON public.pontos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.usuarios
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- =========================================================================
-- 4. GATILHO (Trigger) PARA CRIAÇÃO AUTOMÁTICA DE PERFIL
-- =========================================================================
-- Esse trigger ajuda a criar automaticamente uma entrada na tabela public.usuarios
-- quando um novo usuário se cadastrar via Auth. Para o administrador cadastrar,
-- ele cria o usuário no Auth e o perfil é populado.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.usuarios (id, email, nome, role, cpf, precisa_alterar_senha)
    VALUES (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'nome', 'Novo Funcionário'),
        coalesce(new.raw_user_meta_data->>'role', 'employee'),
        coalesce(new.raw_user_meta_data->>'cpf', '00000000000'),
        true
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- CREATE TRIGGER on_auth_user_created
--     AFTER INSERT ON auth.users
--     FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
