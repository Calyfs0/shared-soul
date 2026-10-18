import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../companion/daily_ritual.dart';
import '../companion/love_goal.dart';
import 'couple_models.dart';

class CoupleService {
  CoupleService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get userId => _client.auth.currentUser?.id;

  Future<Profile?> fetchMyProfile() async {
    final uid = userId;
    if (uid == null) return null;
    final row =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  /// Heartbeat so reinstall reclaim can tell a live partner from a ghost seat.
  Future<void> touchLastSeen() async {
    try {
      await _client.rpc('touch_last_seen');
    } catch (_) {}
  }

  Future<Profile?> fetchProfile(String id) async {
    final row =
        await _client.from('profiles').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  Future<Couple?> fetchMyCouple() async {
    final profile = await fetchMyProfile();
    final cid = profile?.coupleId;
    if (cid == null) return null;
    final row =
        await _client.from('couples').select().eq('id', cid).maybeSingle();
    if (row == null) return null;
    return Couple.fromJson(row);
  }

  Future<({String coupleId, String inviteCode})> createCouple({
    required String displayName,
    required int timezoneOffsetMinutes,
  }) async {
    final res = await _client.rpc(
      'create_couple',
      params: {
        'p_display_name': displayName,
        'p_timezone_offset_minutes': timezoneOffsetMinutes,
      },
    );
    final map = Map<String, dynamic>.from(res as Map);
    return (
      coupleId: map['couple_id'] as String,
      inviteCode: map['invite_code'] as String,
    );
  }

  Future<({String coupleId, String inviteCode})> joinCouple({
    required String inviteCode,
    required String displayName,
  }) async {
    final res = await _client.rpc(
      'join_couple',
      params: {
        'p_invite_code': inviteCode,
        'p_display_name': displayName,
      },
    );
    final map = Map<String, dynamic>.from(res as Map);
    return (
      coupleId: map['couple_id'] as String,
      inviteCode: map['invite_code'] as String,
    );
  }

  /// Couple-local "today" using stored timezone offset.
  DateTime coupleLocalNow(Couple couple, [DateTime? utcNow]) {
    final now = utcNow ?? DateTime.now().toUtc();
    return now.add(Duration(minutes: couple.timezoneOffsetMinutes));
  }

  String coupleDateKey(Couple couple, [DateTime? utcNow]) {
    return ritualDateKey(coupleLocalNow(couple, utcNow));
  }

  Future<CoupleDay> ensureTodayDay(Couple couple) async {
    final local = coupleLocalNow(couple);
    final dateKey = ritualDateKey(local);
    final prompt = promptForDate(local);

    final existing = await _client
        .from('couple_days')
        .select()
        .eq('couple_id', couple.id)
        .eq('date_key', dateKey)
        .maybeSingle();

    if (existing != null) {
      var day = CoupleDay.fromJson(existing);
      if (day.goalIds.isEmpty) {
        final goals = loveGoalsForConnectionCycle(dateKey, day.connectionCycle);
        day = await _seedGoalsIfEmpty(day, dateKey, goals);
      }
      day = await _carryIncompleteIfNeeded(couple, day, local);
      return day;
    }

    final goals = loveGoalsForConnectionCycle(dateKey, 0);
    try {
      final inserted = await _client
          .from('couple_days')
          .insert({
            'couple_id': couple.id,
            'date_key': dateKey,
            'prompt_id': prompt.id,
            'goals_slot_key': loveGoalsCycleSlotKey(dateKey, 0),
            'goal_round': 0,
            'goal_ids': goals.map((g) => g.id).toList(),
            'connection_cycle': 0,
          })
          .select()
          .single();
      var day = CoupleDay.fromJson(inserted);
      day = await _carryIncompleteIfNeeded(couple, day, local);
      return day;
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
      final row = await _client
          .from('couple_days')
          .select()
          .eq('couple_id', couple.id)
          .eq('date_key', dateKey)
          .single();
      var day = CoupleDay.fromJson(row);
      if (day.goalIds.isEmpty) {
        day = await _seedGoalsIfEmpty(
          day,
          dateKey,
          loveGoalsForConnectionCycle(dateKey, day.connectionCycle),
        );
      }
      day = await _carryIncompleteIfNeeded(couple, day, local);
      return day;
    }
  }

  Future<CoupleDay> _seedGoalsIfEmpty(
    CoupleDay day,
    String dateKey,
    List<LoveGoal> goals,
  ) async {
    final res = await _client.rpc(
      'ensure_day_goals',
      params: {
        'p_day_id': day.id,
        'p_slot_key': loveGoalsCycleSlotKey(dateKey, day.connectionCycle),
        'p_goal_ids': goals.map((g) => g.id).toList(),
      },
    );
    return CoupleDay.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<CoupleDay> submitMyAnswer({
    required CoupleDay day,
    required String answer,
  }) async {
    final res = await _client.rpc(
      'submit_day_answer',
      params: {
        'p_day_id': day.id,
        'p_answer': answer.trim(),
      },
    );
    return CoupleDay.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<CoupleDay> completeMyGoal({
    required CoupleDay day,
    required String goalId,
  }) async {
    final res = await _client.rpc(
      'complete_day_goal',
      params: {
        'p_day_id': day.id,
        'p_goal_id': goalId,
      },
    );
    return CoupleDay.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<CoupleDay> _carryIncompleteIfNeeded(
    Couple couple,
    CoupleDay day,
    DateTime local,
  ) async {
    if (day.bothAnswered) return day;
    final hasAny = (day.answerA?.trim().isNotEmpty ?? false) ||
        (day.answerB?.trim().isNotEmpty ?? false);
    if (hasAny) return day;
    if (couple.isCoolingDown) return day;

    final yesterday = local.subtract(const Duration(days: 1));
    final fromKey = ritualDateKey(yesterday);
    try {
      final res = await _client.rpc(
        'carry_incomplete_day_answers',
        params: {
          'p_couple_id': couple.id,
          'p_from_date_key': fromKey,
          'p_to_day_id': day.id,
        },
      );
      return CoupleDay.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      return day;
    }
  }

  /// After cooldown: clear notes and deal a fresh prompt + tasks (idempotent).
  Future<({CoupleDay? day, Couple couple})> beginNextConnection(
    Couple couple,
  ) async {
    final local = coupleLocalNow(couple);
    final dateKey = ritualDateKey(local);
    final existing = await _client
        .from('couple_days')
        .select('connection_cycle')
        .eq('couple_id', couple.id)
        .eq('date_key', dateKey)
        .maybeSingle();
    final nextCycle =
        ((existing?['connection_cycle'] as num?)?.toInt() ?? 0) + 1;
    final prompt = promptForDate(local.add(Duration(hours: nextCycle)));
    final goals = loveGoalsForConnectionCycle(dateKey, nextCycle);

    final res = await _client.rpc(
      'begin_next_connection',
      params: {
        'p_couple_id': couple.id,
        'p_prompt_id': prompt.id,
        'p_goal_ids': goals.map((g) => g.id).toList(),
      },
    );
    final map = Map<String, dynamic>.from(res as Map);
    final dayRaw = map['day'];
    return (
      day: dayRaw == null
          ? null
          : CoupleDay.fromJson(Map<String, dynamic>.from(dayRaw as Map)),
      couple: Couple.fromJson(Map<String, dynamic>.from(map['couple'] as Map)),
    );
  }

  /// Most recent day where both answered — for goals UI while cooling across midnight.
  Future<CoupleDay?> fetchLatestConnectedDay(String coupleId) async {
    final rows = await _client
        .from('couple_days')
        .select()
        .eq('couple_id', coupleId)
        .order('date_key', ascending: false)
        .limit(8);
    for (final row in rows as List) {
      final day = CoupleDay.fromJson(Map<String, dynamic>.from(row as Map));
      if (day.bothAnswered) return day;
    }
    return null;
  }

  Future<void> leaveCouple() async {
    await _client.rpc('leave_couple');
  }

  Future<Profile> setMyDisplayName(String displayName) async {
    final res = await _client.rpc(
      'set_my_display_name',
      params: {'p_display_name': displayName},
    );
    return Profile.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<Couple> setCosmetic({
    required Couple couple,
    required String cosmetic,
  }) async {
    final res = await _client.rpc(
      'set_couple_cosmetic',
      params: {
        'p_couple_id': couple.id,
        'p_cosmetic': cosmetic,
      },
    );
    return Couple.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Stream<Couple?> watchCouple(String coupleId) {
    return _client
        .from('couples')
        .stream(primaryKey: ['id'])
        .eq('id', coupleId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return Couple.fromJson(rows.first);
        });
  }

  Stream<CoupleDay?> watchDay(String coupleId, String dateKey) {
    return _client
        .from('couple_days')
        .stream(primaryKey: ['id'])
        .eq('couple_id', coupleId)
        .map((rows) {
          for (final row in rows) {
            if (row['date_key'] == dateKey) {
              return CoupleDay.fromJson(row);
            }
          }
          return null;
        });
  }
}
