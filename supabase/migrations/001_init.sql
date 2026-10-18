-- Shared Soul V1 — schema, RLS, couple RPCs
-- Run in Supabase SQL Editor (Dashboard → SQL)

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  couple_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.couples (
  id uuid primary key default gen_random_uuid(),
  invite_code text not null unique,
  member_a uuid not null references auth.users (id),
  member_b uuid references auth.users (id),
  timezone_offset_minutes int not null default 0,
  whole_bond_days int not null default 0,
  counted_day_keys text[] not null default '{}',
  created_at timestamptz not null default now(),
  constraint couples_two_members check (member_b is null or member_a <> member_b)
);

alter table public.profiles
  drop constraint if exists profiles_couple_id_fkey;
alter table public.profiles
  add constraint profiles_couple_id_fkey
  foreign key (couple_id) references public.couples (id) on delete set null;

create table if not exists public.couple_days (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples (id) on delete cascade,
  date_key text not null,
  prompt_id text not null,
  answer_a text,
  answer_b text,
  goals_slot_key text,
  goal_round int not null default 0,
  goal_ids text[] not null default '{}',
  completed_a text[] not null default '{}',
  completed_b text[] not null default '{}',
  unique (couple_id, date_key)
);

create index if not exists couples_invite_code_idx on public.couples (invite_code);
create index if not exists couple_days_couple_date_idx on public.couple_days (couple_id, date_key);

alter table public.profiles enable row level security;
alter table public.couples enable row level security;
alter table public.couple_days enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select using (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists couples_select_member on public.couples;
create policy couples_select_member on public.couples
  for select using (auth.uid() = member_a or auth.uid() = member_b);

drop policy if exists couples_update_member on public.couples;
create policy couples_update_member on public.couples
  for update using (auth.uid() = member_a or auth.uid() = member_b);

drop policy if exists couple_days_select_member on public.couple_days;
create policy couple_days_select_member on public.couple_days
  for select using (
    exists (
      select 1 from public.couples c
      where c.id = couple_id and (c.member_a = auth.uid() or c.member_b = auth.uid())
    )
  );

drop policy if exists couple_days_insert_member on public.couple_days;
create policy couple_days_insert_member on public.couple_days
  for insert with check (
    exists (
      select 1 from public.couples c
      where c.id = couple_id and (c.member_a = auth.uid() or c.member_b = auth.uid())
    )
  );

drop policy if exists couple_days_update_member on public.couple_days;
create policy couple_days_update_member on public.couple_days
  for update using (
    exists (
      select 1 from public.couples c
      where c.id = couple_id and (c.member_a = auth.uid() or c.member_b = auth.uid())
    )
  );

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public._random_invite_code()
returns text
language plpgsql
as $$
declare
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := '';
  i int;
begin
  for i in 1..6 loop
    result := result || substr(chars, 1 + floor(random() * length(chars))::int, 1);
  end loop;
  return result;
end;
$$;

create or replace function public.create_couple(
  p_display_name text,
  p_timezone_offset_minutes int default 0
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  code text;
  cid uuid;
  tries int := 0;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.profiles (id, display_name)
  values (uid, coalesce(nullif(trim(p_display_name), ''), ''))
  on conflict (id) do update
  set display_name = coalesce(nullif(trim(p_display_name), ''), public.profiles.display_name);

  if exists (select 1 from public.profiles where id = uid and couple_id is not null) then
    raise exception 'Already in a couple';
  end if;

  loop
    code := public._random_invite_code();
    begin
      insert into public.couples (invite_code, member_a, timezone_offset_minutes)
      values (code, uid, p_timezone_offset_minutes)
      returning id into cid;
      exit;
    exception when unique_violation then
      tries := tries + 1;
      if tries > 8 then
        raise exception 'Could not allocate invite code';
      end if;
    end;
  end loop;

  update public.profiles set couple_id = cid where id = uid;

  return json_build_object('couple_id', cid, 'invite_code', code);
end;
$$;

create or replace function public.join_couple(
  p_invite_code text,
  p_display_name text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cid uuid;
  code text := upper(trim(p_invite_code));
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.profiles (id, display_name)
  values (uid, coalesce(nullif(trim(p_display_name), ''), ''))
  on conflict (id) do update
  set display_name = coalesce(nullif(trim(p_display_name), ''), public.profiles.display_name);

  if exists (select 1 from public.profiles where id = uid and couple_id is not null) then
    raise exception 'Already in a couple';
  end if;

  select id into cid from public.couples
  where invite_code = code and member_b is null
  for update;

  if cid is null then
    raise exception 'Invalid or full invite code';
  end if;

  if exists (select 1 from public.couples where id = cid and member_a = uid) then
    raise exception 'Cannot join your own couple';
  end if;

  update public.couples set member_b = uid where id = cid;
  update public.profiles set couple_id = cid where id = uid;

  return json_build_object('couple_id', cid, 'invite_code', code);
end;
$$;

create or replace function public.ensure_bond_day(p_couple_id uuid, p_date_key text)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  days int;
  a text;
  b text;
  counted text[];
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1 from public.couples c
    where c.id = p_couple_id and (c.member_a = auth.uid() or c.member_b = auth.uid())
  ) then
    raise exception 'Not a member';
  end if;

  select answer_a, answer_b into a, b
  from public.couple_days
  where couple_id = p_couple_id and date_key = p_date_key;

  if a is null or b is null or length(trim(a)) = 0 or length(trim(b)) = 0 then
    select whole_bond_days into days from public.couples where id = p_couple_id;
    return days;
  end if;

  select counted_day_keys, whole_bond_days into counted, days
  from public.couples where id = p_couple_id for update;

  if p_date_key = any (counted) then
    return days;
  end if;

  update public.couples
  set counted_day_keys = array_append(counted_day_keys, p_date_key),
      whole_bond_days = whole_bond_days + 1
  where id = p_couple_id
  returning whole_bond_days into days;

  return days;
end;
$$;

grant usage on schema public to anon, authenticated;
grant select, update, insert on public.profiles to authenticated;
grant select, update on public.couples to authenticated;
grant select, insert, update on public.couple_days to authenticated;
grant execute on function public.create_couple(text, int) to authenticated;
grant execute on function public.join_couple(text, text) to authenticated;
grant execute on function public.ensure_bond_day(uuid, text) to authenticated;

do $$
begin
  begin
    alter publication supabase_realtime add table public.couples;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.couple_days;
  exception when duplicate_object then null;
  end;
end $$;
