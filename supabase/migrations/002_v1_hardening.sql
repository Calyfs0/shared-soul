-- V1 hardening: cosmetics, partner profiles, atomic day RPCs

alter table public.couples
  add column if not exists cosmetic text not null default 'none';

alter table public.couples
  add column if not exists discovered_memories text[] not null default '{}';

-- Partners can read each other's display names.
drop policy if exists profiles_select_own on public.profiles;
drop policy if exists profiles_select_member on public.profiles;
create policy profiles_select_member on public.profiles
  for select using (
    auth.uid() = id
    or exists (
      select 1 from public.couples c
      where (c.member_a = auth.uid() and c.member_b = profiles.id)
         or (c.member_b = auth.uid() and c.member_a = profiles.id)
    )
  );

create or replace function public.submit_day_answer(
  p_day_id uuid,
  p_answer text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  d public.couple_days%rowtype;
  c public.couples%rowtype;
  trimmed text := trim(coalesce(p_answer, ''));
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;
  if length(trimmed) = 0 then
    raise exception 'Empty answer';
  end if;

  select * into d from public.couple_days where id = p_day_id for update;
  if not found then
    raise exception 'Day not found';
  end if;

  select * into c from public.couples where id = d.couple_id for update;
  if c.member_a <> uid and c.member_b <> uid then
    raise exception 'Not a member';
  end if;

  if c.member_a = uid then
    if d.answer_a is not null and length(trim(d.answer_a)) > 0 then
      raise exception 'Already answered';
    end if;
    update public.couple_days set answer_a = trimmed where id = p_day_id;
  else
    if d.answer_b is not null and length(trim(d.answer_b)) > 0 then
      raise exception 'Already answered';
    end if;
    update public.couple_days set answer_b = trimmed where id = p_day_id;
  end if;

  perform public.ensure_bond_day(d.couple_id, d.date_key);

  return (select to_json(cd) from public.couple_days cd where cd.id = p_day_id);
end;
$$;

create or replace function public.complete_day_goal(
  p_day_id uuid,
  p_goal_id text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  d public.couple_days%rowtype;
  c public.couples%rowtype;
  gid text := trim(coalesce(p_goal_id, ''));
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;
  if length(gid) = 0 then
    raise exception 'Missing goal';
  end if;

  select * into d from public.couple_days where id = p_day_id for update;
  if not found then
    raise exception 'Day not found';
  end if;

  select * into c from public.couples where id = d.couple_id;
  if c.member_a <> uid and c.member_b <> uid then
    raise exception 'Not a member';
  end if;

  if not (gid = any (d.goal_ids)) then
    raise exception 'Goal not in current round';
  end if;

  if c.member_a = uid then
    if not (gid = any (d.completed_a)) then
      update public.couple_days
      set completed_a = array_append(completed_a, gid)
      where id = p_day_id;
    end if;
  else
    if not (gid = any (d.completed_b)) then
      update public.couple_days
      set completed_b = array_append(completed_b, gid)
      where id = p_day_id;
    end if;
  end if;

  return (select to_json(cd) from public.couple_days cd where cd.id = p_day_id);
end;
$$;

-- Rotate goals when the day-part slot changes. Does not touch answers.
-- Completions only reset when the slot actually changes (new task set).
create or replace function public.ensure_day_goals(
  p_day_id uuid,
  p_slot_key text,
  p_goal_ids text[]
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  d public.couple_days%rowtype;
  c public.couples%rowtype;
  slot text := trim(coalesce(p_slot_key, ''));
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;
  if length(slot) = 0 or p_goal_ids is null or cardinality(p_goal_ids) = 0 then
    raise exception 'Invalid goals payload';
  end if;

  select * into d from public.couple_days where id = p_day_id for update;
  if not found then
    raise exception 'Day not found';
  end if;

  select * into c from public.couples where id = d.couple_id;
  if c.member_a <> uid and c.member_b <> uid then
    raise exception 'Not a member';
  end if;

  if d.goals_slot_key is not distinct from slot
     and cardinality(d.goal_ids) > 0 then
    return to_json(d);
  end if;

  update public.couple_days
  set goals_slot_key = slot,
      goal_round = 0,
      goal_ids = p_goal_ids,
      completed_a = '{}',
      completed_b = '{}'
  where id = p_day_id;

  return (select to_json(cd) from public.couple_days cd where cd.id = p_day_id);
end;
$$;

create or replace function public.set_couple_cosmetic(
  p_couple_id uuid,
  p_cosmetic text
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cos text := coalesce(nullif(trim(p_cosmetic), ''), 'none');
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1 from public.couples c
    where c.id = p_couple_id and (c.member_a = uid or c.member_b = uid)
  ) then
    raise exception 'Not a member';
  end if;

  update public.couples
  set cosmetic = cos
  where id = p_couple_id;

  return (select to_json(c) from public.couples c where c.id = p_couple_id);
end;
$$;

grant execute on function public.submit_day_answer(uuid, text) to authenticated;
grant execute on function public.complete_day_goal(uuid, text) to authenticated;
grant execute on function public.ensure_day_goals(uuid, text, text[]) to authenticated;
grant execute on function public.set_couple_cosmetic(uuid, text) to authenticated;
