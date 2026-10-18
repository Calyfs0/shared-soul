# Shared Soul

A couple companion app: leave notes anytime, do real affection tasks together, rest for 4 hours, then connect again — and grow a shared celestial companion.

## Setup

1. **Supabase Auth** → enable **Anonymous sign-ins**.
2. **Migrations** → from the project root (linked CLI), apply all SQL migrations:

```bash
supabase db push
```

Or run these in order in the SQL Editor:

- [`supabase/migrations/001_init.sql`](supabase/migrations/001_init.sql)
- [`supabase/migrations/002_v1_hardening.sql`](supabase/migrations/002_v1_hardening.sql)
- [`supabase/migrations/003_connect_cooldown.sql`](supabase/migrations/003_connect_cooldown.sql)
- [`supabase/migrations/004_audit_hardening.sql`](supabase/migrations/004_audit_hardening.sql)
- [`supabase/migrations/005_leave_slot_swap.sql`](supabase/migrations/005_leave_slot_swap.sql)
- [`supabase/migrations/006_reclaim_by_invite.sql`](supabase/migrations/006_reclaim_by_invite.sql)

3. Config is already in [`lib/config/supabase_config.dart`](lib/config/supabase_config.dart) (public anon key).

```bash
flutter pub get
flutter run
```

## Couple connect (two phones / simulators)

1. Phone A: open app → enter a name → **Create a couple code** → share/copy the 6-letter code (waiting lobby until they join).
2. Phone B: enter a name → type the code → **Join**.
3. Both leave a note → tasks unlock when both have answered.
4. After both notes, a **4-hour cooldown** starts (countdown on home). Tasks stay available during the rest.
5. When the timer ends, a new check-in opens automatically.
6. Completing a task on one phone syncs to the other (Realtime).

**Note:** The shared calendar day uses the **creator’s timezone**. Reinstalling clears anonymous auth — enter the **same invite code** again to reclaim your seat (the app replaces the inactive member slot).

## V1 checklist

- [ ] Anonymous Auth enabled
- [ ] Migrations 001–006 applied
- [ ] Create + wait lobby + join with invite code
- [ ] Notes sync both ways
- [ ] Tasks appear after both notes
- [ ] 4h cooldown countdown on both phones
- [ ] Next connection after cooldown
- [ ] Task check-offs sync
- [ ] Bond days increment once per calendar day when both answered
- [ ] Leave couple works; can re-pair
