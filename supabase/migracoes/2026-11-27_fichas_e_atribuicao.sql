-- jogadores: atribuição da última foto + nota de revisão
alter table public.jogadores
  add column if not exists nota text,
  add column if not exists atualizado_por uuid references auth.users(id),
  add column if not exists atualizado_em timestamptz;

-- histórico: uma foto por transcrição. dados/runas em jsonb (flexível, barato).
create table if not exists public.fichas (
  id uuid primary key default gen_random_uuid(),
  jogador_id uuid not null references public.jogadores(id) on delete cascade,
  criada_em timestamptz not null default now(),
  criado_por uuid references auth.users(id) default auth.uid(),
  dados jsonb not null default '{}'::jsonb,
  runas jsonb not null default '[]'::jsonb
);
create index if not exists fichas_jogador_idx on public.fichas(jogador_id, criada_em desc);

alter table public.fichas enable row level security;
-- leitura para staff autenticado (mesma função de papel do resto)
create policy fichas_staff_select on public.fichas
  for select to authenticated using (papel_do(auth.uid()) is not null);
create policy fichas_staff_write on public.fichas
  for all to authenticated
  using (papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'))
  with check (papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'));
