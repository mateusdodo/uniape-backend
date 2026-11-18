-- ==== 20260901183946_600e5ad6-efc6-4745-b4f4-64b79e0ac6bc.sql
-- ============ ENUMS ============
create type public.tipo_usuario as enum ('estudante', 'trabalhador', 'proprietario');
create type public.tipo_imovel as enum ('quarto', 'republica', 'kitnet', 'apartamento');
create type public.status_imovel as enum ('disponivel', 'esgotado', 'inativo');
create type public.tipo_solicitante as enum ('individual', 'grupo');
create type public.status_solicitacao as enum ('pendente', 'aceita', 'recusada', 'cancelada');
create type public.status_contrato as enum ('ativo', 'encerrado', 'cancelado');
create type public.status_pagamento as enum ('pago', 'pendente', 'atrasado');

-- ============ PROFILES (Usuario) ============
create table public.profiles (
  id uuid primary key,
  nome text not null,
  telefone text,
  tipo public.tipo_usuario not null default 'estudante',
  status_moradia text,
  media_estrelas numeric(3,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.imoveis (
  id uuid primary key default gen_random_uuid(),
  proprietario_id uuid not null references public.profiles(id) on delete cascade,
  titulo text not null,
  descricao text not null default '',
  tipo public.tipo_imovel not null default 'quarto',
  preco_mensal numeric(10,2) not null,
  vagas_disponiveis integer not null default 1,
  vagas_total integer not null default 1,
  bairro text not null,
  proximidade text,
  comodidades text[] not null default '{}',
  fotos text[] not null default '{}',
  status public.status_imovel not null default 'disponivel',
  media_estrelas numeric(3,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.grupos (
  id uuid primary key default gen_random_uuid(),
  nome_grupo text not null,
  lider_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.grupo_membros (
  grupo_id uuid not null references public.grupos(id) on delete cascade,
  usuario_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (grupo_id, usuario_id)
);

create table public.solicitacoes (
  id uuid primary key default gen_random_uuid(),
  imovel_id uuid not null references public.imoveis(id) on delete cascade,
  solicitante_id uuid not null references public.profiles(id) on delete cascade,
  tipo_solicitante public.tipo_solicitante not null default 'individual',
  grupo_id uuid references public.grupos(id) on delete set null,
  mensagem text not null default '',
  status public.status_solicitacao not null default 'pendente',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.contratos (
  id uuid primary key default gen_random_uuid(),
  imovel_id uuid not null references public.imoveis(id) on delete cascade,
  inquilino_id uuid not null references public.profiles(id) on delete cascade,
  grupo_id uuid references public.grupos(id) on delete set null,
  inicio date not null default current_date,
  fim date,
  valor_mensal numeric(10,2) not null,
  status public.status_contrato not null default 'ativo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.pagamentos (
  id uuid primary key default gen_random_uuid(),
  contrato_id uuid not null references public.contratos(id) on delete cascade,
  mes_referencia date not null,
  valor numeric(10,2) not null,
  status_pagamento public.status_pagamento not null default 'pendente',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.avaliacoes (
  id uuid primary key default gen_random_uuid(),
  imovel_id uuid not null references public.imoveis(id) on delete cascade,
  contrato_id uuid references public.contratos(id) on delete set null,
  avaliador_id uuid not null references public.profiles(id) on delete cascade,
  avaliado_id uuid not null references public.profiles(id) on delete cascade,
  estrelas integer not null check (estrelas between 1 and 5),
  comentario text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============ GRANTS ============
grant select on public.profiles to anon, authenticated;
grant update on public.profiles to authenticated;
grant select on public.imoveis to anon, authenticated;
grant insert, update, delete on public.imoveis to authenticated;
grant select on public.grupos to authenticated;
grant insert, update, delete on public.grupos to authenticated;
grant select, insert, delete on public.grupo_membros to authenticated;
grant select on public.solicitacoes to authenticated;
grant insert, update, delete on public.solicitacoes to authenticated;
grant select on public.contratos to authenticated;
grant insert, update, delete on public.contratos to authenticated;
grant select on public.pagamentos to authenticated;
grant insert, update, delete on public.pagamentos to authenticated;
grant select on public.avaliacoes to anon, authenticated;
grant insert on public.avaliacoes to authenticated;
grant all on public.profiles, public.imoveis, public.grupos, public.grupo_membros, public.solicitacoes, public.contratos, public.pagamentos, public.avaliacoes to service_role;

-- ============ RLS ============
alter table public.profiles enable row level security;
alter table public.imoveis enable row level security;
alter table public.grupos enable row level security;
alter table public.grupo_membros enable row level security;
alter table public.solicitacoes enable row level security;
alter table public.contratos enable row level security;
alter table public.pagamentos enable row level security;
alter table public.avaliacoes enable row level security;

-- profiles
create policy "Perfis visiveis para todos" on public.profiles for select to anon, authenticated using (true);
create policy "Usuario edita o proprio perfil" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- imoveis
create policy "Imoveis visiveis para todos" on public.imoveis for select to anon, authenticated using (true);
create policy "Proprietario cria imoveis" on public.imoveis for insert to authenticated with check (auth.uid() = proprietario_id);
create policy "Proprietario edita seus imoveis" on public.imoveis for update to authenticated using (auth.uid() = proprietario_id) with check (auth.uid() = proprietario_id);
create policy "Proprietario remove seus imoveis" on public.imoveis for delete to authenticated using (auth.uid() = proprietario_id);

-- grupos
create policy "Membros veem o grupo" on public.grupos for select to authenticated using (auth.uid() = lider_id or exists (select 1 from public.grupo_membros gm where gm.grupo_id = id and gm.usuario_id = auth.uid()));
create policy "Usuario cria grupo como lider" on public.grupos for insert to authenticated with check (auth.uid() = lider_id);
create policy "Lider edita o grupo" on public.grupos for update to authenticated using (auth.uid() = lider_id) with check (auth.uid() = lider_id);
create policy "Lider remove o grupo" on public.grupos for delete to authenticated using (auth.uid() = lider_id);

-- grupo_membros
create policy "Membros veem o grupo_membros" on public.grupo_membros for select to authenticated using (true);
create policy "Usuario entra em grupo" on public.grupo_membros for insert to authenticated with check (auth.uid() = usuario_id);
create policy "Usuario sai do grupo" on public.grupo_membros for delete to authenticated using (auth.uid() = usuario_id);

-- solicitacoes
create policy "Solicitante ve suas solicitacoes" on public.solicitacoes for select to authenticated using (auth.uid() = solicitante_id or auth.uid() in (select i.proprietario_id from public.imoveis i where i.id = imovel_id));
create policy "Usuario envia solicitacao" on public.solicitacoes for insert to authenticated with check (auth.uid() = solicitante_id);
create policy "Solicitante cancela" on public.solicitacoes for update to authenticated using (auth.uid() = solicitante_id) with check (auth.uid() = solicitante_id);
create policy "Solicitante remove" on public.solicitacoes for delete to authenticated using (auth.uid() = solicitante_id);

-- contratos
create policy "Partes veem o contrato" on public.contratos for select to authenticated using (auth.uid() = inquilino_id or auth.uid() in (select i.proprietario_id from public.imoveis i where i.id = imovel_id));
create policy "Proprietario cria contrato" on public.contratos for insert to authenticated with check (auth.uid() in (select i.proprietario_id from public.imoveis i where i.id = imovel_id));
create policy "Partes editam contrato" on public.contratos for update to authenticated using (auth.uid() = inquilino_id or auth.uid() in (select i.proprietario_id from public.imoveis i where i.id = imovel_id)) with check (auth.uid() = inquilino_id or auth.uid() in (select i.proprietario_id from public.imoveis i where i.id = imovel_id));

-- pagamentos
create policy "Partes veem o pagamento" on public.pagamentos for select to authenticated using (exists (select 1 from public.contratos c where c.id = contrato_id and (c.inquilino_id = auth.uid() or c.imovel_id in (select i.id from public.imoveis i where i.proprietario_id = auth.uid()))));
create policy "Proprietario registra pagamento" on public.pagamentos for insert to authenticated with check (exists (select 1 from public.contratos c join public.imoveis i on i.id = c.imovel_id where c.id = contrato_id and i.proprietario_id = auth.uid()));
create policy "Proprietario edita pagamento" on public.pagamentos for update to authenticated using (exists (select 1 from public.contratos c join public.imoveis i on i.id = c.imovel_id where c.id = contrato_id and i.proprietario_id = auth.uid())) with check (exists (select 1 from public.contratos c join public.imoveis i on i.id = c.imovel_id where c.id = contrato_id and i.proprietario_id = auth.uid()));

-- avaliacoes
create policy "Avaliacoes visiveis para todos" on public.avaliacoes for select to anon, authenticated using (true);
create policy "Usuario avalia" on public.avaliacoes for insert to authenticated with check (auth.uid() = avaliador_id);

-- ============ TRIGGERS ============
create or replace function public.set_updated_at() returns trigger
language plpgsql set search_path = public
as $$ begin new.updated_at = now(); return new; end $$;

create trigger set_profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger set_imoveis_updated_at before update on public.imoveis for each row execute function public.set_updated_at();
create trigger set_grupos_updated_at before update on public.grupos for each row execute function public.set_updated_at();
create trigger set_solicitacoes_updated_at before update on public.solicitacoes for each row execute function public.set_updated_at();
create trigger set_contratos_updated_at before update on public.contratos for each row execute function public.set_updated_at();
create trigger set_pagamentos_updated_at before update on public.pagamentos for each row execute function public.set_updated_at();
create trigger set_avaliacoes_updated_at before update on public.avaliacoes for each row execute function public.set_updated_at();

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, nome, telefone)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'nome', split_part(new.email, '@', 1)), new.phone)
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.recalc_imovel_media() returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  update public.imoveis
  set media_estrelas = coalesce((select round(avg(estrelas)::numeric, 1) from public.avaliacoes where imovel_id = new.imovel_id), 0)
  where id = new.imovel_id;
  return new;
end $$;

create trigger recalc_imovel_media_insert after insert on public.avaliacoes for each row execute function public.recalc_imovel_media();
create trigger recalc_imovel_media_delete after delete on public.avaliacoes for each row execute function public.recalc_imovel_media();

-- ============ SEED (dados de exemplo) ============
insert into public.profiles (id, nome, telefone, tipo) values
  ('11111111-1111-4111-8111-111111111101', 'Dona Cleide', '(88) 99999-1001', 'proprietario'),
  ('11111111-1111-4111-8111-111111111102', 'Seu Zé do Cedro', '(88) 99999-1002', 'proprietario'),
  ('11111111-1111-4111-8111-111111111103', 'Mariana Silva', '(88) 99999-1003', 'estudante'),
  ('11111111-1111-4111-8111-111111111104', 'Rafael Mendes', '(88) 99999-1004', 'estudante'),
  ('11111111-1111-4111-8111-111111111105', 'Camila Rocha', '(88) 99999-1005', 'estudante');

insert into public.imoveis (proprietario_id, titulo, descricao, tipo, preco_mensal, vagas_disponiveis, vagas_total, bairro, proximidade, comodidades, fotos, status, media_estrelas) values
  ('11111111-1111-4111-8111-111111111101', 'República Arretada', 'Casa ampla no Planalto com sala, cozinha compartilhada e área de churrasco. Ambiente focado em estudos, silêncio após as 22h.', 'republica', 550, 2, 4, 'Planalto Universitário', '400m do campus da UFC', ARRAY['Wifi 500mb','Ar-condicionado','Lavanderia','Área de churrasco'], ARRAY['/images/imovel-1.jpg'], 'disponivel', 4.9),
  ('11111111-1111-4111-8111-111111111102', 'Kitnet Solar do Cedro', 'Kitnet nova e mobiliada com cama, armário, mesa de estudos e banheiro privativo. Conta de água e internet inclusas.', 'kitnet', 720, 1, 1, 'Cedro', 'Próximo à Unicatólica', ARRAY['Mobiliado','Luz inclusa','Wifi'], ARRAY['/images/imovel-2.jpg'], 'disponivel', 4.7),
  ('11111111-1111-4111-8111-111111111101', 'Casa da Galera', 'Quarto individual em casa universitária no Centro, a uma quadra da praça principal. Ambiente misto e descontraído.', 'quarto', 480, 1, 3, 'Centro', 'Rua do Comércio', ARRAY['Wifi','Cozinha compartilhada','Lavanderia'], ARRAY['/images/imovel-3.jpg'], 'disponivel', 5.0),
  ('11111111-1111-4111-8111-111111111102', 'República Pedra da Galinha', 'República tradicional, vista para os monólitos, com rede no quintal e internet fibra. Duas vagas em quarto compartilhado.', 'republica', 450, 2, 2, 'Cedro', '10 min do campus da UFC', ARRAY['Wifi fibra','Rede no quintal','Cozinha'], ARRAY['/images/imovel-4.jpg'], 'disponivel', 4.8),
  ('11111111-1111-4111-8111-111111111101', 'Quarto Casa da Praça', 'Quarto simples e limpo em casa de família, ideal para quem busca tranquilidade para estudar.', 'quarto', 520, 1, 2, 'Centro', 'Perto da Unicatólica', ARRAY['Wifi','Água inclusa'], ARRAY['/images/imovel-5.jpg'], 'disponivel', 4.6),
  ('11111111-1111-4111-8111-111111111102', 'Kitnet Universitária II', 'Kitnet no coração do Planalto Universitário, 5 minutos a pé do IFCE. Vaga única, esgotada rapidamente!', 'kitnet', 680, 0, 1, 'Planalto Universitário', '5 min do IFCE', ARRAY['Mobiliado','Ar-condicionado'], ARRAY['/images/imovel-6.jpg'], 'esgotado', 4.5);

insert into public.avaliacoes (imovel_id, contrato_id, avaliador_id, avaliado_id, estrelas, comentario) values
  ((select id from public.imoveis where titulo = 'República Arretada'), null, '11111111-1111-4111-8111-111111111103', '11111111-1111-4111-8111-111111111101', 5, 'Morei dois anos e é a melhor república que já vi em Quixadá. Silêncio de verdade e internet ótima.'),
  ((select id from public.imoveis where titulo = 'República Arretada'), null, '11111111-1111-4111-8111-111111111104', '11111111-1111-4111-8111-111111111101', 5, 'Dona Cleide é super atenciosa, responde tudo rapidinho no WhatsApp.'),
  ((select id from public.imoveis where titulo = 'República Arretada'), null, '11111111-1111-4111-8111-111111111105', '11111111-1111-4111-8111-111111111101', 4, 'Ótimo lugar, só senti falta de uma chuveiro elétrico mais forte.'),
  ((select id from public.imoveis where titulo = 'Kitnet Solar do Cedro'), null, '11111111-1111-4111-8111-111111111103', '11111111-1111-4111-8111-111111111102', 5, 'Kitnet nova, tudo funcionando. Cheguei de Fortaleza e me instalei no mesmo dia.'),
  ((select id from public.imoveis where titulo = 'República Pedra da Galinha'), null, '11111111-1111-4111-8111-111111111104', '11111111-1111-4111-8111-111111111102', 5, 'A vista dos monólitos da janela não tem preço. Melhor custo-benefício do Cedro.'),
  ((select id from public.imoveis where titulo = 'Casa da Galera'), null, '11111111-1111-4111-8111-111111111105', '11111111-1111-4111-8111-111111111101', 5, 'Galera animada e respeitosa, localização imbatível no Centro.');

update public.imoveis i set media_estrelas = coalesce((select round(avg(a.estrelas)::numeric, 1) from public.avaliacoes a where a.imovel_id = i.id), 0);

alter publication supabase_realtime add table public.solicitacoes;
-- ==== 20260901184103_2c982c48-22c2-48e5-97dd-df82518a04fa.sql
revoke execute on function public.handle_new_user() from anon, authenticated, public;
revoke execute on function public.recalc_imovel_media() from anon, authenticated, public;
-- ==== 20260910135157_0ca2e17e-d28c-4b6d-85cd-4420b83d83ad.sql
CREATE TYPE public.sentido_parada AS ENUM ('ida','volta');

CREATE TABLE public.paradas_onibus (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  endereco text NOT NULL,
  sentido public.sentido_parada NOT NULL,
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  ordem integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT ON public.paradas_onibus TO anon;
GRANT SELECT ON public.paradas_onibus TO authenticated;
GRANT ALL ON public.paradas_onibus TO service_role;

ALTER TABLE public.paradas_onibus ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Paradas visiveis para todos" ON public.paradas_onibus
FOR SELECT TO anon, authenticated USING (true);

CREATE TRIGGER set_paradas_onibus_updated_at
BEFORE UPDATE ON public.paradas_onibus
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.imoveis
  ADD COLUMN endereco text NOT NULL DEFAULT '',
  ADD COLUMN latitude numeric,
  ADD COLUMN longitude numeric,
  ADD COLUMN parada_ida_nome text,
  ADD COLUMN parada_ida_minutos integer,
  ADD COLUMN parada_volta_nome text,
  ADD COLUMN parada_volta_minutos integer,
  ADD COLUMN transporte_fonte text;

INSERT INTO public.paradas_onibus (nome, endereco, sentido, latitude, longitude, ordem) VALUES
  ('Combate', 'Rua Basílio Emiliano Pinto, 1290 — Combate', 'ida', -4.9717401, -39.0283695, 1),
  ('Planalto Universitário', 'Rua Basílio Emiliano Pinto, 958 — Planalto Universitário', 'ida', -4.9705978, -39.0252110, 2),
  ('Centro', 'Rua Basílio Emiliano Pinto, 420 — Centro', 'ida', -4.9711000, -39.0221000, 3),
  ('Rodoviária de Quixadá', 'Av. José Caetano Almeida — Terminal Rodoviário', 'ida', -4.9729219, -39.0164591, 4),
  ('Combate', 'Rua José de Freitas Queiroz — Combate', 'volta', -4.9750000, -39.0330000, 1),
  ('Cúria Diocesana', 'Cúria Diocesana de Quixadá', 'volta', -4.9725000, -39.0285000, 2),
  ('Av. José Caetano Almeida, 861', 'Av. José Caetano Almeida, 861', 'volta', -4.9725797, -39.0242439, 3),
  ('Av. José Caetano Almeida, 503', 'Av. José Caetano Almeida, 503', 'volta', -4.9725523, -39.0200454, 4),
  ('Rodoviária de Quixadá', 'Av. José Caetano Almeida — Terminal Rodoviário', 'volta', -4.9729219, -39.0164591, 5);
-- ==== 20260911011453_7ba0de90-8e5e-4557-8ea2-66559ceebfba.sql
CREATE OR REPLACE FUNCTION public.pode_ver_conversa(_contrato_id uuid, _user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.contratos c
    JOIN public.imoveis i ON i.id = c.imovel_id
    WHERE c.id = _contrato_id
      AND (
        i.proprietario_id = _user_id
        OR c.inquilino_id = _user_id
        OR EXISTS (
          SELECT 1 FROM public.grupo_membros gm
          WHERE gm.grupo_id = c.grupo_id AND gm.usuario_id = _user_id
        )
      )
  )
$$;

CREATE OR REPLACE FUNCTION public.pode_falar_conversa(_contrato_id uuid, _user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.contratos c
    JOIN public.imoveis i ON i.id = c.imovel_id
    WHERE c.id = _contrato_id
      AND (
        i.proprietario_id = _user_id
        OR c.inquilino_id = _user_id
        OR EXISTS (
          SELECT 1 FROM public.grupos g
          WHERE g.id = c.grupo_id AND g.lider_id = _user_id
        )
      )
  )
$$;

CREATE TABLE public.mensagens_contrato (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contrato_id uuid NOT NULL REFERENCES public.contratos(id) ON DELETE CASCADE,
  autor_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  conteudo text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX mensagens_contrato_contrato_idx ON public.mensagens_contrato (contrato_id, created_at);

GRANT SELECT, INSERT ON public.mensagens_contrato TO authenticated;
GRANT ALL ON public.mensagens_contrato TO service_role;

ALTER TABLE public.mensagens_contrato ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participantes leem a conversa"
ON public.mensagens_contrato FOR SELECT TO authenticated
USING (public.pode_ver_conversa(contrato_id, auth.uid()));

CREATE POLICY "Somente admins escrevem"
ON public.mensagens_contrato FOR INSERT TO authenticated
WITH CHECK (auth.uid() = autor_id AND public.pode_falar_conversa(contrato_id, auth.uid()));

CREATE TRIGGER set_mensagens_contrato_updated_at
BEFORE UPDATE ON public.mensagens_contrato
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER PUBLICATION supabase_realtime ADD TABLE public.mensagens_contrato;
-- ==== 20260911011548_93b06d67-4ab0-4880-b18d-86e6f11e4cc8.sql
REVOKE EXECUTE ON FUNCTION public.pode_ver_conversa(uuid, uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.pode_falar_conversa(uuid, uuid) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.pode_ver_conversa(uuid, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.pode_falar_conversa(uuid, uuid) TO authenticated, service_role;
-- ==== 20260911011633_9646d1fb-49ed-4223-ab83-a6b57d32fec7.sql
CREATE POLICY "Membros do grupo veem o contrato"
ON public.contratos FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.grupo_membros gm
    WHERE gm.grupo_id = contratos.grupo_id AND gm.usuario_id = auth.uid()
  )
);
-- ==== 20260914134724_dad88d6c-656c-4e5b-87d6-037cf1992e4e.sql
-- ============ Limpeza do escopo antigo ============
DROP TABLE IF EXISTS public.mensagens_contrato CASCADE;
DROP TABLE IF EXISTS public.pagamentos CASCADE;
DROP FUNCTION IF EXISTS public.pode_ver_conversa(uuid, uuid);
DROP FUNCTION IF EXISTS public.pode_falar_conversa(uuid, uuid);

ALTER TABLE public.avaliacoes DROP COLUMN IF EXISTS contrato_id;
DROP TABLE IF EXISTS public.contratos CASCADE;

-- ============ Tipos ============
DO $$ BEGIN
  CREATE TYPE public.tipo_conta AS ENUM ('comum','proprietario');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.status_moradia_reg AS ENUM ('ativa','encerramento_solicitado','encerrada');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============ Perfis ============
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS tipo_conta public.tipo_conta NOT NULL DEFAULT 'comum',
  ADD COLUMN IF NOT EXISTS verificado boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS proprietario_declarado_em timestamptz,
  ADD COLUMN IF NOT EXISTS documento_url text,
  ADD COLUMN IF NOT EXISTS total_avaliacoes integer NOT NULL DEFAULT 0;

-- ============ Imóveis ============
ALTER TABLE public.imoveis
  ADD COLUMN IF NOT EXISTS quartos integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS aceita_solicitacoes boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS moradores_podem_recrutar boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS whatsapp_grupo_url text,
  ADD COLUMN IF NOT EXISTS contato_whatsapp text,
  ADD COLUMN IF NOT EXISTS ocupado boolean NOT NULL DEFAULT false;

UPDATE public.imoveis SET quartos = GREATEST(1, vagas_total);

-- ============ Moradias ============
CREATE TABLE IF NOT EXISTS public.moradias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  imovel_id uuid NOT NULL REFERENCES public.imoveis(id) ON DELETE CASCADE,
  grupo_id uuid REFERENCES public.grupos(id) ON DELETE SET NULL,
  responsavel_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  proprietario_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  inicio date NOT NULL DEFAULT CURRENT_DATE,
  fim date,
  status public.status_moradia_reg NOT NULL DEFAULT 'ativa',
  encerramento_pedido_por uuid REFERENCES public.profiles(id),
  encerramento_pedido_em timestamptz,
  avaliacao_janela_fim timestamptz,
  whatsapp_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.moradia_moradores (
  moradia_id uuid NOT NULL REFERENCES public.moradias(id) ON DELETE CASCADE,
  morador_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (moradia_id, morador_id)
);

GRANT SELECT ON public.moradias TO authenticated;
GRANT ALL ON public.moradias TO service_role;
GRANT SELECT ON public.moradia_moradores TO authenticated;
GRANT ALL ON public.moradia_moradores TO service_role;

ALTER TABLE public.moradias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moradia_moradores ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.pode_ver_moradia(_moradia_id uuid, _user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.moradias m
    WHERE m.id = _moradia_id
      AND (m.proprietario_id = _user_id
           OR m.responsavel_id = _user_id
           OR EXISTS (SELECT 1 FROM public.moradia_moradores mm
                      WHERE mm.moradia_id = m.id AND mm.morador_id = _user_id))
  )
$$;

CREATE POLICY "Participantes veem a moradia" ON public.moradias
  FOR SELECT TO authenticated USING (public.pode_ver_moradia(id, auth.uid()));

CREATE POLICY "Participantes veem os moradores" ON public.moradia_moradores
  FOR SELECT TO authenticated USING (public.pode_ver_moradia(moradia_id, auth.uid()));

CREATE TRIGGER set_moradias_updated_at BEFORE UPDATE ON public.moradias
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============ Chamados de moradores ============
CREATE TABLE IF NOT EXISTS public.chamados_moradores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  imovel_id uuid NOT NULL REFERENCES public.imoveis(id) ON DELETE CASCADE,
  moradia_id uuid NOT NULL REFERENCES public.moradias(id) ON DELETE CASCADE,
  autor_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  mensagem text NOT NULL DEFAULT '',
  vagas_procuradas integer NOT NULL DEFAULT 1,
  ativo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT ON public.chamados_moradores TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chamados_moradores TO authenticated;
GRANT ALL ON public.chamados_moradores TO service_role;

ALTER TABLE public.chamados_moradores ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.pode_recrutar(_moradia_id uuid, _user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.moradias m
    JOIN public.imoveis i ON i.id = m.imovel_id
    WHERE m.id = _moradia_id
      AND m.status <> 'encerrada'
      AND i.moradores_podem_recrutar
      AND (m.responsavel_id = _user_id
           OR EXISTS (SELECT 1 FROM public.moradia_moradores mm
                      WHERE mm.moradia_id = m.id AND mm.morador_id = _user_id))
  )
$$;

CREATE POLICY "Chamados visiveis para todos" ON public.chamados_moradores
  FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Morador autorizado publica chamado" ON public.chamados_moradores
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = autor_id AND public.pode_recrutar(moradia_id, auth.uid()));
CREATE POLICY "Autor edita chamado" ON public.chamados_moradores
  FOR UPDATE TO authenticated USING (auth.uid() = autor_id) WITH CHECK (auth.uid() = autor_id);
CREATE POLICY "Autor remove chamado" ON public.chamados_moradores
  FOR DELETE TO authenticated USING (auth.uid() = autor_id);

CREATE TRIGGER set_chamados_updated_at BEFORE UPDATE ON public.chamados_moradores
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============ Avaliações às cegas ============
ALTER TABLE public.avaliacoes
  ADD COLUMN IF NOT EXISTS moradia_id uuid REFERENCES public.moradias(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS revelada boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS janela_fim timestamptz;

CREATE UNIQUE INDEX IF NOT EXISTS avaliacoes_unica_por_moradia
  ON public.avaliacoes (moradia_id, avaliador_id, avaliado_id)
  WHERE moradia_id IS NOT NULL;

DROP POLICY IF EXISTS "Avaliacoes visiveis para todos" ON public.avaliacoes;
DROP POLICY IF EXISTS "Usuario avalia" ON public.avaliacoes;

CREATE POLICY "Avaliacoes reveladas sao publicas" ON public.avaliacoes
  FOR SELECT TO anon, authenticated USING (revelada);
CREATE POLICY "Autor ve a propria avaliacao" ON public.avaliacoes
  FOR SELECT TO authenticated USING (auth.uid() = avaliador_id);
CREATE POLICY "Usuario avalia" ON public.avaliacoes
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = avaliador_id);

-- médias só contam avaliações reveladas
CREATE OR REPLACE FUNCTION public.recalc_medias()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  _imovel uuid := COALESCE(NEW.imovel_id, OLD.imovel_id);
  _avaliado uuid := COALESCE(NEW.avaliado_id, OLD.avaliado_id);
BEGIN
  UPDATE public.imoveis SET media_estrelas = COALESCE((
    SELECT ROUND(AVG(estrelas)::numeric, 1) FROM public.avaliacoes
    WHERE imovel_id = _imovel AND revelada
  ), 0) WHERE id = _imovel;

  UPDATE public.profiles p SET
    media_estrelas = COALESCE((
      SELECT ROUND(AVG(a.estrelas)::numeric, 1) FROM public.avaliacoes a
      WHERE a.avaliado_id = _avaliado AND a.revelada), 0),
    total_avaliacoes = (
      SELECT COUNT(*) FROM public.avaliacoes a
      WHERE a.avaliado_id = _avaliado AND a.revelada)
  WHERE p.id = _avaliado;

  RETURN COALESCE(NEW, OLD);
END $$;

DROP TRIGGER IF EXISTS recalc_imovel_media_insert ON public.avaliacoes;
DROP TRIGGER IF EXISTS recalc_imovel_media_delete ON public.avaliacoes;
DROP FUNCTION IF EXISTS public.recalc_imovel_media();

CREATE TRIGGER recalc_medias_aiud
  AFTER INSERT OR UPDATE OR DELETE ON public.avaliacoes
  FOR EACH ROW EXECUTE FUNCTION public.recalc_medias();

-- revela avaliações de uma moradia (reciprocidade ou fim da janela)
CREATE OR REPLACE FUNCTION public.revelar_avaliacoes(_moradia_id uuid)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  UPDATE public.avaliacoes a
  SET revelada = true
  WHERE a.moradia_id = _moradia_id
    AND NOT a.revelada
    AND (
      a.janela_fim IS NOT NULL AND a.janela_fim < now()
      OR EXISTS (
        SELECT 1 FROM public.avaliacoes b
        WHERE b.moradia_id = a.moradia_id
          AND b.avaliador_id = a.avaliado_id
          AND b.avaliado_id = a.avaliador_id
      )
    );
$$;

-- encerra automaticamente pedidos sem resposta há mais de 7 dias e revela janelas vencidas
CREATE OR REPLACE FUNCTION public.processar_moradias()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r record;
BEGIN
  UPDATE public.moradias
  SET status = 'encerrada',
      fim = CURRENT_DATE,
      avaliacao_janela_fim = now() + interval '14 days'
  WHERE status = 'encerramento_solicitado'
    AND encerramento_pedido_em < now() - interval '7 days';

  UPDATE public.imoveis i SET ocupado = false
  WHERE i.ocupado AND NOT EXISTS (
    SELECT 1 FROM public.moradias m WHERE m.imovel_id = i.id AND m.status <> 'encerrada');

  UPDATE public.profiles p SET status_moradia = 'procurando'
  WHERE p.status_moradia = 'morando' AND NOT EXISTS (
    SELECT 1 FROM public.moradia_moradores mm
    JOIN public.moradias m ON m.id = mm.moradia_id
    WHERE mm.morador_id = p.id AND m.status <> 'encerrada');

  FOR r IN SELECT DISTINCT moradia_id FROM public.avaliacoes
           WHERE NOT revelada AND moradia_id IS NOT NULL LOOP
    PERFORM public.revelar_avaliacoes(r.moradia_id);
  END LOOP;
END $$;

-- ==== 20260914134827_a6e076b2-549a-4fb8-b162-c5959f023d7a.sql
REVOKE ALL ON FUNCTION public.handle_new_user() FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.recalc_medias() FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.set_updated_at() FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.revelar_avaliacoes(uuid) FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.processar_moradias() FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.pode_ver_moradia(uuid, uuid) FROM public, anon;
REVOKE ALL ON FUNCTION public.pode_recrutar(uuid, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.pode_ver_moradia(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pode_recrutar(uuid, uuid) TO authenticated;
-- ==== 20261006165853_f1f9d15e-8397-4815-9ae6-97a1a5aae536.sql
GRANT EXECUTE ON FUNCTION public.processar_moradias() TO service_role;
GRANT EXECUTE ON FUNCTION public.revelar_avaliacoes(uuid) TO service_role;
-- ==== 20261007011436_1c1d0ef7-3dac-4657-b883-543769f4e421.sql
CREATE OR REPLACE FUNCTION public.proteger_campos_perfil()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF current_setting('request.jwt.claim.role', true) = 'authenticated' OR auth.role() = 'authenticated' THEN
    NEW.verificado := OLD.verificado;
    NEW.media_estrelas := OLD.media_estrelas;
    NEW.total_avaliacoes := OLD.total_avaliacoes;
    NEW.tipo_conta := OLD.tipo_conta;
    NEW.proprietario_declarado_em := OLD.proprietario_declarado_em;
  END IF;
  RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.proteger_campos_perfil() FROM public, anon, authenticated;
CREATE TRIGGER proteger_campos_perfil BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.proteger_campos_perfil();
-- ==== 20261007013905_c888f85c-c676-4ba3-941f-6518caa2209a.sql
CREATE OR REPLACE FUNCTION public.proteger_campos_perfil()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') THEN
    NEW.verificado := OLD.verificado;
    NEW.media_estrelas := OLD.media_estrelas;
    NEW.total_avaliacoes := OLD.total_avaliacoes;
    NEW.tipo_conta := OLD.tipo_conta;
    NEW.proprietario_declarado_em := OLD.proprietario_declarado_em;
  END IF;
  RETURN NEW;
END $$;
-- ==== 20261029191745_703921ed-62a1-458c-ae07-a6709544244d.sql
ALTER TABLE public.chamados_moradores ADD COLUMN IF NOT EXISTS aprovado boolean NOT NULL DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;

CREATE OR REPLACE FUNCTION public.proteger_aprovacao_chamado()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF TG_OP = 'INSERT' THEN
      NEW.aprovado := false;
    ELSIF NEW.aprovado IS DISTINCT FROM OLD.aprovado
      AND NOT EXISTS (SELECT 1 FROM imoveis i WHERE i.id = NEW.imovel_id AND i.proprietario_id = auth.uid()) THEN
      NEW.aprovado := OLD.aprovado;
    END IF;
  END IF;
  RETURN NEW;
END $$;
REVOKE EXECUTE ON FUNCTION public.proteger_aprovacao_chamado() FROM anon, authenticated, public;
DROP TRIGGER IF EXISTS trg_proteger_aprovacao_chamado ON public.chamados_moradores;
CREATE TRIGGER trg_proteger_aprovacao_chamado BEFORE INSERT OR UPDATE ON public.chamados_moradores
FOR EACH ROW EXECUTE FUNCTION public.proteger_aprovacao_chamado();

DROP POLICY IF EXISTS "Chamados visiveis para todos" ON public.chamados_moradores;
CREATE POLICY "Chamados aprovados sao publicos" ON public.chamados_moradores FOR SELECT TO anon, authenticated USING (aprovado AND ativo);
CREATE POLICY "Autor e dono veem chamados" ON public.chamados_moradores FOR SELECT TO authenticated
USING (auth.uid() = autor_id OR EXISTS (SELECT 1 FROM public.imoveis i WHERE i.id = imovel_id AND i.proprietario_id = auth.uid()));
CREATE POLICY "Dono aprova chamados" ON public.chamados_moradores FOR UPDATE TO authenticated
USING (EXISTS (SELECT 1 FROM public.imoveis i WHERE i.id = imovel_id AND i.proprietario_id = auth.uid()))
WITH CHECK (EXISTS (SELECT 1 FROM public.imoveis i WHERE i.id = imovel_id AND i.proprietario_id = auth.uid()));

CREATE POLICY "Usuario envia o proprio documento" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'documentos' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Usuario ve o proprio documento" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'documentos' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Usuario troca o proprio documento" ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'documentos' AND (storage.foldername(name))[1] = auth.uid()::text);
-- ==== 20261029200956_77a7603b-8dad-45a8-a4e4-a0f06c409c37.sql
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  _tipo public.tipo_conta := CASE WHEN new.raw_user_meta_data ->> 'tipo_conta' = 'proprietario' THEN 'proprietario'::public.tipo_conta ELSE 'comum'::public.tipo_conta END;
BEGIN
  INSERT INTO public.profiles (id, nome, telefone, tipo_conta, proprietario_declarado_em)
  VALUES (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nome', split_part(new.email, '@', 1)),
    coalesce(nullif(new.raw_user_meta_data ->> 'telefone', ''), new.phone),
    _tipo,
    CASE WHEN _tipo = 'proprietario' THEN now() ELSE NULL END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END $$;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM public, anon, authenticated;

-- Só o morador principal (responsável) divulga a casa
CREATE OR REPLACE FUNCTION public.pode_recrutar(_moradia_id uuid, _user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.moradias m
    JOIN public.imoveis i ON i.id = m.imovel_id
    WHERE m.id = _moradia_id AND m.status <> 'encerrada'
      AND i.moradores_podem_recrutar AND m.responsavel_id = _user_id
  )
$$;

-- Uma divulgação ativa por imóvel
UPDATE public.chamados_moradores c SET ativo = false
WHERE ativo AND EXISTS (SELECT 1 FROM public.chamados_moradores c2 WHERE c2.imovel_id = c.imovel_id AND c2.ativo AND c2.created_at > c.created_at);
CREATE UNIQUE INDEX IF NOT EXISTS chamados_um_ativo_por_imovel ON public.chamados_moradores (imovel_id) WHERE ativo;

-- Fotos de perfil (bucket público "avatars")
CREATE POLICY "Avatares publicos" ON storage.objects FOR SELECT TO anon, authenticated USING (bucket_id = 'avatars');
CREATE POLICY "Usuario envia avatar" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Usuario troca avatar" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Usuario remove avatar" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
