-- Allow invite-code reclaim after a browser refresh: only block if BOTH
-- seats were heartbeating in the last 30 seconds (true simultaneous use).

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
  c public.couples%rowtype;
  code text := upper(trim(p_invite_code));
  name text := coalesce(nullif(trim(p_display_name), ''), 'You');
  seen_a timestamptz;
  seen_b timestamptz;
  replace_id uuid;
  reclaimed boolean := false;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  if code is null or length(code) = 0 then
    raise exception 'Invalid or full invite code';
  end if;

  insert into public.profiles (id, display_name, last_seen_at)
  values (uid, name, now())
  on conflict (id) do update
  set display_name = name,
      last_seen_at = now();

  if exists (
    select 1 from public.profiles
    where id = uid and couple_id is not null
  ) then
    raise exception 'Already in a couple';
  end if;

  select * into c from public.couples
  where invite_code = code
  for update;

  if not found then
    raise exception 'Invalid or full invite code';
  end if;

  if c.member_a = uid or c.member_b = uid then
    update public.profiles set couple_id = c.id, last_seen_at = now() where id = uid;
    return json_build_object(
      'couple_id', c.id,
      'invite_code', code,
      'reclaimed', false
    );
  end if;

  -- Open seat: normal join as B.
  if c.member_b is null then
    if c.member_a = uid then
      raise exception 'Cannot join your own couple';
    end if;
    update public.couples set member_b = uid where id = c.id;
    update public.profiles set couple_id = c.id, last_seen_at = now() where id = uid;
    return json_build_object(
      'couple_id', c.id,
      'invite_code', code,
      'reclaimed', false
    );
  end if;

  -- Full couple: reclaim the less recently active seat (refresh / reinstall ghost).
  select last_seen_at into seen_a from public.profiles where id = c.member_a;
  select last_seen_at into seen_b from public.profiles where id = c.member_b;

  seen_a := coalesce(seen_a, 'epoch'::timestamptz);
  seen_b := coalesce(seen_b, 'epoch'::timestamptz);

  -- Only block when both seats are actively heartbeating right now.
  if seen_a > now() - interval '30 seconds'
     and seen_b > now() - interval '30 seconds' then
    raise exception 'Couple is full — both partners are active';
  end if;

  if seen_a <= seen_b then
    replace_id := c.member_a;
  else
    replace_id := c.member_b;
  end if;

  update public.profiles
  set couple_id = null
  where id = replace_id;

  if replace_id = c.member_a then
    update public.couples set member_a = uid where id = c.id;
  else
    update public.couples set member_b = uid where id = c.id;
  end if;

  update public.profiles
  set couple_id = c.id, last_seen_at = now()
  where id = uid;

  reclaimed := true;

  return json_build_object(
    'couple_id', c.id,
    'invite_code', code,
    'reclaimed', reclaimed
  );
end;
$$;

grant execute on function public.join_couple(text, text) to authenticated;
