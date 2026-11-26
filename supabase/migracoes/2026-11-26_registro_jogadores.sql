-- perfis: liga uma conta do Auth a um papel
create table public.perfis (
  id uuid primary key references auth.users(id) on delete cascade,
  papel text not null check (papel in ('admin','staff_editor','staff_basico','sala_guerras')),
  nome text,
  criado_em timestamptz not null default now()
);
alter table public.perfis enable row level security;

-- o papel do usuário, para as policies lerem sem recursão (security definer)
create or replace function public.papel_do(uid uuid)
returns text language sql security definer stable as $$
  select papel from public.perfis where id = uid
$$;

create table public.jogadores (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  cla text, classe text, nivel int, despertares int, cultivo text, limite text,
  hp int, mp int,
  ataque_fisico text, ataque_magico text, acerto int, nivel_ataque int, furia text,
  def_fisica int, def_metal int, def_madeira int, def_agua int, def_fogo int, def_terra int,
  esquiva int, nivel_defesa int, critico text, canalizacao text,
  penetracao_fisica int, penetracao_magica int, espirito int,
  indice_dano bigint, sobrevivencia bigint,
  print_url text, recorte_runas_url text, recorte_gear_url text,
  status text not null default 'pendente' check (status in ('pendente','transcrito')),
  criado_por uuid references auth.users(id),
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
alter table public.jogadores enable row level security;

create policy perfis_self_select on public.perfis
  for select to authenticated using (id = auth.uid());
create policy perfis_admin_all on public.perfis
  for all to authenticated
  using (public.papel_do(auth.uid()) = 'admin')
  with check (public.papel_do(auth.uid()) = 'admin');

create policy jogadores_staff_select on public.jogadores
  for select to authenticated
  using (public.papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'));
create policy jogadores_staff_write on public.jogadores
  for all to authenticated
  using (public.papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'))
  with check (public.papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'));

insert into storage.buckets (id, name, public) values ('prints','prints',false)
  on conflict (id) do nothing;
create policy prints_staff_rw on storage.objects
  for all to authenticated
  using (bucket_id = 'prints' and public.papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'))
  with check (bucket_id = 'prints' and public.papel_do(auth.uid()) in ('admin','staff_editor','staff_basico'));
