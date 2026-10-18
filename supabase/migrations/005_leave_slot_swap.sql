-- When member_a leaves, promote member_b and swap day columns so ownership stays correct.

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
      -- Promote B → A and swap day ownership so answers/goals stay with the remaining person.
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

grant execute on function public.leave_couple() to authenticated;
