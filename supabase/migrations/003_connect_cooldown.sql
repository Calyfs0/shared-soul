-- Connect anytime: 4-hour cooldown after both partners leave a note

alter table public.couples
  add column if not exists cooldown_until timestamptz;

alter table public.couple_days
  add column if not exists connection_cycle int not null default 0;

-- When both have answered, start a 4h cooldown (once per connection cycle).
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
  a text;
  b text;
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

  -- After both connected, cooldown blocks starting another note until it ends + begin_next.
  if c.cooldown_until is not null and c.cooldown_until > now() then
    raise exception 'Cooldown active';
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

  select answer_a, answer_b into a, b
  from public.couple_days where id = p_day_id;

  if a is not null and length(trim(a)) > 0
     and b is not null and length(trim(b)) > 0 then
    perform public.ensure_bond_day(d.couple_id, d.date_key);

    -- Start cooldown when this connection first completes.
    if c.cooldown_until is null or c.cooldown_until <= now() then
      update public.couples
      set cooldown_until = now() + interval '4 hours'
      where id = d.couple_id;
    end if;
  end if;

  return (select to_json(cd) from public.couple_days cd where cd.id = p_day_id);
end;
$$;

-- After cooldown expires: fresh notes + goals for another connection (same calendar day ok).
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

  if p_prompt_id is null or length(trim(p_prompt_id)) = 0 then
    raise exception 'Missing prompt';
  end if;
  if p_goal_ids is null or cardinality(p_goal_ids) = 0 then
    raise exception 'Missing goals';
  end if;

  -- Couple-local date key (same formula as the app).
  local_now := timezone('utc', now()) + make_interval(mins => c.timezone_offset_minutes);
  date_key := to_char(local_now, 'YYYY-MM-DD');

  select * into d
  from public.couple_days
  where couple_id = p_couple_id and date_key = date_key
  for update;

  if not found then
    raise exception 'Day not found';
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

  update public.couples
  set cooldown_until = null
  where id = p_couple_id;

  return json_build_object(
    'day', (select to_json(cd) from public.couple_days cd where cd.id = d.id),
    'couple', (select to_json(cp) from public.couples cp where cp.id = p_couple_id)
  );
end;
$$;

grant execute on function public.begin_next_connection(uuid, text, text[]) to authenticated;
