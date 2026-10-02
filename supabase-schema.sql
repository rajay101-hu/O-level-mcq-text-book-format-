-- O Level Digital Textbook — V10 Supabase schema
-- Run this in Supabase SQL Editor before using the online mode.

create extension if not exists pgcrypto;

do $$ begin
  if not exists (select 1 from pg_type where typname = 'difficulty_level') then
    create type public.difficulty_level as enum ('Easy','Medium','Hard');
  end if;
end $$;

create table if not exists public.modules (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  sort_order integer not null default 0
);

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  module_slug text not null references public.modules(slug) on delete cascade,
  slug text not null,
  name text not null,
  description text,
  sort_order integer not null default 0,
  unique(module_slug, slug)
);

create table if not exists public.topics (
  id uuid primary key default gen_random_uuid(),
  chapter_slug text not null references public.chapters(slug) on delete cascade,
  slug text not null,
  name text not null,
  sort_order integer not null default 0,
  unique(chapter_slug, slug)
);

create table if not exists public.questions (
  id text primary key,
  module_slug text not null default 'm1',
  chapter_slug text not null default 'ch2',
  topic text not null,
  question text not null,
  option_a text not null,
  option_b text not null,
  option_c text not null,
  option_d text not null,
  correct_answer smallint not null check (correct_answer between 0 and 3),
  explanation text not null default '',
  source_page integer check (source_page is null or source_page > 0),
  difficulty public.difficulty_level not null default 'Medium',
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists questions_chapter_sort_idx on public.questions(chapter_slug, sort_order);
create index if not exists questions_topic_idx on public.questions(topic);
create index if not exists questions_active_idx on public.questions(active);

create or replace function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_questions_updated_at on public.questions;
create trigger trg_questions_updated_at before update on public.questions for each row execute function public.set_updated_at();

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.admin_users where user_id = auth.uid());
$$;

revoke execute on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- RLS: public can read active questions; only admins can modify the question bank.
alter table public.questions enable row level security;
alter table public.modules enable row level security;
alter table public.chapters enable row level security;
alter table public.topics enable row level security;
alter table public.admin_users enable row level security;

-- Drop/recreate only the policies created by this file.
drop policy if exists questions_public_read on public.questions;
drop policy if exists questions_admin_select on public.questions;
drop policy if exists questions_admin_insert on public.questions;
drop policy if exists questions_admin_update on public.questions;
drop policy if exists questions_admin_delete on public.questions;
create policy questions_public_read on public.questions for select to anon, authenticated using (active = true);
create policy questions_admin_select on public.questions for select to authenticated using (public.is_admin());
create policy questions_admin_insert on public.questions for insert to authenticated with check (public.is_admin());
create policy questions_admin_update on public.questions for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy questions_admin_delete on public.questions for delete to authenticated using (public.is_admin());

drop policy if exists modules_public_read on public.modules;
drop policy if exists chapters_public_read on public.chapters;
drop policy if exists topics_public_read on public.topics;
create policy modules_public_read on public.modules for select to anon, authenticated using (true);
create policy chapters_public_read on public.chapters for select to anon, authenticated using (true);
create policy topics_public_read on public.topics for select to anon, authenticated using (true);

-- Only authenticated admins can read the admin_users table.
drop policy if exists admin_users_self on public.admin_users;
create policy admin_users_self on public.admin_users for select to authenticated using (user_id = auth.uid() or public.is_admin());

-- Client roles: grant only what this browser app needs.
revoke all on table public.questions, public.modules, public.chapters, public.topics, public.admin_users from anon, authenticated;
grant select on public.questions, public.modules, public.chapters, public.topics to anon, authenticated;
grant insert, update, delete on public.questions to authenticated;
grant select on public.admin_users to authenticated;
