create table if not exists public.lancamentos (
  id uuid primary key default gen_random_uuid(),
  tipo text not null check (tipo in ('entrada','despesa','pagamento_staff','transferencia')),
  pote text not null check (pote in ('caixa','reserva')),
  pote_destino text check (pote_destino in ('caixa','reserva')),
  valor bigint not null check (valor > 0),
  categoria text check (categoria in ('guild_ativa','territorio','cashback','outro')),
  descricao text,
  membro uuid references public.jogadores(id) on delete set null,
  fixo boolean not null default false,
  data date not null default (now() at time zone 'America/Sao_Paulo')::date,
  criado_em timestamptz not null default now(),
  lancado_por uuid references auth.users(id) default auth.uid(),
  lancado_por_email text
);
create index if not exists lancamentos_data_idx on public.lancamentos(data desc);

alter table public.lancamentos enable row level security;
create policy lancamentos_fin_select on public.lancamentos
  for select to authenticated using (papel_do(auth.uid()) in ('admin','staff_editor'));
create policy lancamentos_fin_write on public.lancamentos
  for all to authenticated
  using (papel_do(auth.uid()) in ('admin','staff_editor'))
  with check (papel_do(auth.uid()) in ('admin','staff_editor'));
