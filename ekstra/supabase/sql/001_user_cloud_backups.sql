create table if not exists public.user_cloud_backups (
  user_id uuid primary key references auth.users(id) on delete cascade,
  backup jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.user_cloud_backups enable row level security;

drop policy if exists "Users can read their own cloud backup" on public.user_cloud_backups;
create policy "Users can read their own cloud backup"
on public.user_cloud_backups
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can insert their own cloud backup" on public.user_cloud_backups;
create policy "Users can insert their own cloud backup"
on public.user_cloud_backups
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Users can update their own cloud backup" on public.user_cloud_backups;
create policy "Users can update their own cloud backup"
on public.user_cloud_backups
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_cloud_backups_updated_at on public.user_cloud_backups;
create trigger set_user_cloud_backups_updated_at
before update on public.user_cloud_backups
for each row
execute function public.set_updated_at();
