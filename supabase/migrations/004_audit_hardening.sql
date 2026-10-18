-- Audit hardening: idempotent next-connection, leave couple, rename, carry incomplete notes

create or replace function public.begin_next_connection(
  p_couple_id uuid,
  p_prompt_id text,
  p_goal_ids text[]
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  c public.couples%rowtype;
  d public.couple_days%rowtype;
  date_key text;
  local_now timestamp;
  day_found boolean := false;
  both_done boolean := false;
  did_advance boolean := false;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  select * into c from public.couples where id = p_couple_id for update;
  if not found then
    raise exception 'Couple not found';
  end if;
  if c.member_a <> uid and c.member_b <> uid then
    raise exception 'Not a member';
  end if;

  if c.cooldown_until is not null and c.cooldown_until > now() then
    raise exception 'Cooldown active';
  end if;

  local_now := timezone('utc', now()) + make_interval(mins => c.timezone_offset_minutes);
  date_key := to_char(local_now, 'YYYY-MM-DD');

  select * into d
  from public.couple_days
  where couple_id = p_couple_id and date_key = date_key
  for update;
  day_found := found;

  if day_found then
    both_done := (
      d.answer_a is not null and length(trim(d.answer_a)) > 0
      and d.answer_b is not null and length(trim(d.answer_b)) > 0
    );
  end if;

  -- Idle / already advanced: cooldown cleared and today not a completed cycle.
  if c.cooldown_until is null and not both_done then
    if not day_found then
      raise exception 'Day not found';
    end if;
    return json_build_object(
      'day', to_json(d),
      'couple', (select to_json(cp) from public.couples cp where cp.id = p_couple_id),
      'advanced', false
    );
  end if;

  -- Reset a completed cycle on today's row (same-day second connection).
  if both_done then
    if p_prompt_id is null or length(trim(p_prompt_id)) = 0 then
      raise exception 'Missing prompt';
    end if;
    if p_goal_ids is null or cardinality(p_goal_ids) = 0 then
      raise exception 'Missing goals';
    end if;

    update public.couple_days
    set answer_a = null,
        answer_b = null,
        prompt_id = trim(p_prompt_id),
        goal_round = 0,
        goal_ids = p_goal_ids,
        completed_a = '{}',
        completed_b = '{}',
        goals_slot_key = date_key || '_c' || (connection_cycle + 1)::text,
        connection_cycle = connection_cycle + 1
    where id = d.id;

    did_advance := true;
  end if;

  -- Always clear expired cooldown (covers midnight: new empty day + leftover timer).
  update public.couples
  set cooldown_until = null
  where id = p_couple_id;

  -- No today row yet (midnight rollover before client ensureToday) — client creates it.
  if not day_found then
    return json_build_object(
      'day', null,
      'couple', (select to_json(cp) from public.couples cp where cp.id = p_couple_id),
      'advanced', false
    );
  end if;

  return json_build_object(
    'day', (select to_json(cd) from public.couple_days cd where cd.id = d.id),
    'couple', (select to_json(cp) from public.couples cp where cp.id = p_couple_id),
    'advanced', did_advance
  );
end;
$$;

create or replace function public.carry_incomplete_day_answers(
  p_couple_id uuid,
  p_from_date_key text,
  p_to_day_id uuid
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  c public.couples%rowtype;
  src public.couple_days%rowtype;
  dst public.couple_days%rowtype;
  a_ok boolean;
  b_ok boolean;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  select * into c from public.couples where id = p_couple_id;
  if c.member_a <> uid and c.member_b <> uid then
    raise exception 'Not a member';
  end if;

  if c.cooldown_until is not null and c.cooldown_until > now() then
    select * into dst from public.couple_days where id = p_to_day_id;
    return to_json(dst);
  end if;

  select * into src
  from public.couple_days
  where couple_id = p_couple_id and date_key = p_from_date_key;

  if not found then
    select * into dst from public.couple_days where id = p_to_day_id;
    return to_json(dst);
  end if;

  select * into dst from public.couple_days where id = p_to_day_id for update;
  if not found then
    raise exception 'Day not found';
  end if;

  if (dst.answer_a is not null and length(trim(dst.answer_a)) > 0)
     or (dst.answer_b is not null and length(trim(dst.answer_b)) > 0) then
    return to_json(dst);
  end if;

  a_ok := src.answer_a is not null and length(trim(src.answer_a)) > 0;
  b_ok := src.answer_b is not null and length(trim(src.answer_b)) > 0;
  if a_ok = b_ok then
    return to_json(dst);
  end if;

  if a_ok then
    update public.couple_days set answer_a = src.answer_a where id = p_to_day_id;
  else
    update public.couple_days set answer_b = src.answer_b where id = p_to_day_id;
  end if;

  update public.couple_days
  set answer_a = null, answer_b = null
  where id = src.id;

  return (select to_json(cd) from public.couple_days cd where cd.id = p_to_day_id);
end;
$$;

create or replace function public.leave_couple()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  c public.couples%rowtype;
  cid uuid;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  select couple_id into cid from public.profiles where id = uid;
  if cid is null then
    return json_build_object('left', false);
  end if;

  select * into c from public.couples where id = cid for update;
  if not found then
    update public.profiles set couple_id = null where id = uid;
    return json_build_object('left', true);
  end if;

  if c.member_a <> uid and c.member_b <> uid then
    update public.profiles set couple_id = null where id = uid;
    return json_build_object('left', true);
  end if;

  if c.member_b = uid then
    update public.couples set member_b = null where id = cid;
    update public.profiles set couple_id = null where id = uid;
  elsif c.member_a = uid then
    if c.member_b is not null then
      -- Promote B → A; swap day columns so ownership stays with the remaining person.
      update public.couple_days
      set
        answer_a = answer_b,
        answer_b = answer_a,
        completed_a = completed_b,
        completed_b = completed_a
      where couple_id = cid;

      update public.couples
      set member_a = c.member_b,
          member_b = null
      where id = cid;
      update public.profiles set couple_id = null where id = uid;
    else
      update public.profiles set couple_id = null where id = uid;
      delete from public.couples where id = cid;
    end if;
  end if;

  return json_build_object('left', true, 'couple_id', cid);
end;
$$;

create or replace function public.set_my_display_name(p_display_name text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  name text := coalesce(nullif(trim(p_display_name), ''), 'You');
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.profiles (id, display_name)
  values (uid, name)
  on conflict (id) do update set display_name = name;

  return (select to_json(p) from public.profiles p where p.id = uid);
end;
$$;

grant execute on function public.begin_next_connection(uuid, text, text[]) to authenticated;
grant execute on function public.carry_incomplete_day_answers(uuid, text, uuid) to authenticated;
grant execute on function public.leave_couple() to authenticated;
grant execute on function public.set_my_display_name(text) to authenticated;
