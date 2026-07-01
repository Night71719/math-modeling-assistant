-- 数学建模训练记录助手：Supabase 数据库初始化脚本
-- 在 Supabase Dashboard → SQL Editor 中完整运行一次。

create extension if not exists pgcrypto;

create table if not exists public.training_projects (
  id uuid primary key default gen_random_uuid(),
  share_code text not null unique
    default upper(substr(encode(gen_random_bytes(8), 'hex'), 1, 10)),
  name text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

create table if not exists public.training_project_members (
  project_id uuid not null references public.training_projects(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (project_id, user_id)
);

create index if not exists training_project_members_user_idx
  on public.training_project_members(user_id);

create or replace function public.touch_training_project()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists training_projects_touch_updated_at
  on public.training_projects;

create trigger training_projects_touch_updated_at
before update on public.training_projects
for each row execute function public.touch_training_project();

alter table public.training_projects enable row level security;
alter table public.training_project_members enable row level security;

grant select, update on public.training_projects to authenticated;
grant select on public.training_project_members to authenticated;

drop policy if exists "members can read joined projects"
  on public.training_projects;
create policy "members can read joined projects"
on public.training_projects for select
to authenticated
using (
  exists (
    select 1
    from public.training_project_members m
    where m.project_id = training_projects.id
      and m.user_id = auth.uid()
  )
);

drop policy if exists "members can update joined projects"
  on public.training_projects;
create policy "members can update joined projects"
on public.training_projects for update
to authenticated
using (
  exists (
    select 1
    from public.training_project_members m
    where m.project_id = training_projects.id
      and m.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.training_project_members m
    where m.project_id = training_projects.id
      and m.user_id = auth.uid()
  )
);

drop policy if exists "users can read own memberships"
  on public.training_project_members;
create policy "users can read own memberships"
on public.training_project_members for select
to authenticated
using (user_id = auth.uid());

create or replace function public.create_training_project(
  p_name text,
  p_data jsonb
)
returns table (
  id uuid,
  share_code text,
  name text,
  data jsonb,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_project public.training_projects%rowtype;
begin
  if v_user is null then
    raise exception '需要有效的匿名用户会话';
  end if;

  insert into public.training_projects(name, data, updated_by)
  values (coalesce(nullif(trim(p_name), ''), '未命名训练项目'), coalesce(p_data, '{}'::jsonb), v_user)
  returning * into v_project;

  insert into public.training_project_members(project_id, user_id)
  values (v_project.id, v_user)
  on conflict do nothing;

  return query
  select v_project.id, v_project.share_code, v_project.name,
         v_project.data, v_project.updated_at;
end;
$$;

create or replace function public.join_training_project(
  p_share_code text
)
returns table (
  id uuid,
  share_code text,
  name text,
  data jsonb,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_project public.training_projects%rowtype;
begin
  if v_user is null then
    raise exception '需要有效的匿名用户会话';
  end if;

  select *
  into v_project
  from public.training_projects p
  where p.share_code = upper(trim(p_share_code));

  if v_project.id is null then
    raise exception '分享码不存在';
  end if;

  insert into public.training_project_members(project_id, user_id)
  values (v_project.id, v_user)
  on conflict do nothing;

  return query
  select v_project.id, v_project.share_code, v_project.name,
         v_project.data, v_project.updated_at;
end;
$$;

revoke all on function public.create_training_project(text, jsonb) from public;
revoke all on function public.join_training_project(text) from public;
grant execute on function public.create_training_project(text, jsonb) to authenticated;
grant execute on function public.join_training_project(text) to authenticated;

-- 将项目表加入 Supabase Realtime 发布（重复运行不会报错）。
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'training_projects'
  ) then
    alter publication supabase_realtime add table public.training_projects;
  end if;
end
$$;
