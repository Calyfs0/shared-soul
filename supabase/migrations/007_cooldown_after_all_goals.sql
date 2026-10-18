-- Start the 4h rest timer only when BOTH partners finish all three tasks.

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
  end if;

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
  a_done int;
  b_done int;
  total int;
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

  select * into c from public.couples where id = d.couple_id for update;
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

  select * into d from public.couple_days where id = p_day_id;

  total := coalesce(cardinality(d.goal_ids), 0);
  if total > 0 then
    select count(*)::int into a_done
    from unnest(d.goal_ids) g
    where g = any (d.completed_a);

    select count(*)::int into b_done
    from unnest(d.goal_ids) g
    where g = any (d.completed_b);

    -- Both finished every task for this connection → start 4h rest.
    if a_done = total and b_done = total then
      if c.cooldown_until is null or c.cooldown_until <= now() then
        update public.couples
        set cooldown_until = now() + interval '4 hours'
        where id = d.couple_id;
      end if;
    end if;
  end if;

  return (select to_json(cd) from public.couple_days cd where cd.id = p_day_id);
end;
$$;

grant execute on function public.submit_day_answer(uuid, text) to authenticated;
grant execute on function public.complete_day_goal(uuid, text) to authenticated;
