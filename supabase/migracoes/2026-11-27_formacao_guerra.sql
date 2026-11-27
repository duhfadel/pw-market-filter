create table if not exists public.formacao_guerra (
  id text primary key,
  pts jsonb not null default '[]'::jsonb,
  salvo_em timestamptz,
  salvo_por uuid references auth.users(id),
  salvo_por_email text
);
-- a formação é uma só: semeia a linha única.
insert into public.formacao_guerra (id, pts) values ('atual', '[]'::jsonb)
  on conflict (id) do nothing;

alter table public.formacao_guerra enable row level security;
create policy formacao_staff_select on public.formacao_guerra
  for select to authenticated using (papel_do(auth.uid()) is not null);
create policy formacao_staff_write on public.formacao_guerra
  for all to authenticated
  using (papel_do(auth.uid()) is not null)
  with check (papel_do(auth.uid()) is not null);
