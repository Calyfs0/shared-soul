import 'dart:async';

import 'package:flutter/foundation.dart';

import '../couple/couple_models.dart';
import '../couple/couple_service.dart';
import '../couple/session_cache.dart';
import 'cosmetic.dart';
import 'daily_ritual.dart';
import 'evolution.dart';
import 'love_goal.dart';
import 'soul_state.dart';

/// Companion state backed by Supabase couple + day rows.
class SyncedCompanionController extends ChangeNotifier {
  SyncedCompanionController._({
    required this.coupleService,
    required Couple initialCouple,
    this.onCoupleIncomplete,
  }) : _couple = initialCouple;

  static Future<SyncedCompanionController> create({
    required CoupleService coupleService,
    required Couple initialCouple,
    VoidCallback? onCoupleIncomplete,
  }) async {
    final controller = SyncedCompanionController._(
      coupleService: coupleService,
      initialCouple: initialCouple,
      onCoupleIncomplete: onCoupleIncomplete,
    );
    await controller._bootstrap();
    return controller;
  }

  final CoupleService coupleService;
  final VoidCallback? onCoupleIncomplete;

  Couple _couple;
  CoupleDay? _day;
  CoupleDay? _goalsSourceDay;
  StreamSubscription<Couple?>? _coupleSub;
  StreamSubscription<CoupleDay?>? _daySub;
  String? _watchingDateKey;
  Timer? _cooldownTicker;

  bool _ready = false;
  bool _bootstrapping = true;
  bool _advancingCycle = false;

  SoulState _state = SoulState.lonely;
  CompanionCosmetic _cosmetic = CompanionCosmetic.none;
  CompanionEvolution? _evolutionOverride;

  String _myName = 'You';
  String _partnerName = 'Them';

  Couple get couple => _couple;
  CoupleDay? get day => _day;

  bool get isReady => _ready;

  String? get userId => coupleService.userId;
  bool get iAmMemberA => userId != null && _couple.isMemberA(userId!);

  String get myDisplayName => _myName;
  String get partnerDisplayName => _partnerName;

  SoulState get state => _state;
  CompanionCosmetic get cosmetic => _cosmetic;
  int get wholeBondDays => _couple.wholeBondDays;

  CompanionEvolution get evolution =>
      _evolutionOverride ?? CompanionEvolutionX.fromWholeDays(wholeBondDays);

  DateTime get _localNow => coupleService.coupleLocalNow(_couple);

  DateTime? get cooldownUntil => _couple.cooldownUntil;
  bool get isCoolingDown => _couple.isCoolingDown;
  Duration get cooldownRemaining =>
      _couple.cooldownRemaining ?? Duration.zero;

  /// Countdown owns the home chrome whenever the couple timer is live.
  bool get showCooldown => isCoolingDown;

  String get togetherWindowLabel => 'This connection';

  DailyRitual get ritual {
    final d = _day;
    final local = _localNow;
    RitualPrompt prompt = promptForDate(local);
    if (d != null) {
      for (final p in ritualPromptCatalog) {
        if (p.id == d.promptId) {
          prompt = p;
          break;
        }
      }
    }

    if (d == null) {
      return DailyRitual(dateKey: ritualDateKey(local), prompt: prompt);
    }

    return DailyRitual(
      dateKey: d.dateKey,
      prompt: prompt,
      myAnswer: d.myAnswer(iAmMemberA),
      partnerAnswer: d.theirAnswer(iAmMemberA),
    );
  }

  bool get iAnsweredToday => ritual.iAnswered;
  bool get partnerAnsweredToday => ritual.partnerAnswered;
  bool get bothAnsweredToday => ritual.bothComplete;

  /// Expired cooldown still on the couple row — next cycle should open.
  bool get _cooldownExpired {
    final until = _couple.cooldownUntil;
    if (until == null) return false;
    return !until.isAfter(DateTime.now().toUtc());
  }

  /// True when the rest timer finished and a fresh note cycle should open.
  bool get awaitingNextConnection => !isCoolingDown && _cooldownExpired;

  bool get needsCheckIn =>
      !iAnsweredToday && !isCoolingDown && !awaitingNextConnection;
  bool get waitingOnPartner =>
      iAnsweredToday && !partnerAnsweredToday && !isCoolingDown;

  /// Tasks unlock after both notes; timer starts only when both finish all three.
  bool get loveGoalsUnlocked =>
      bothAnsweredToday || (isCoolingDown && _goalsDay != null);

  CoupleDay? get _goalsDay {
    if (_day?.bothAnswered == true) return _day;
    if (isCoolingDown) return _goalsSourceDay;
    return null;
  }

  List<LoveGoal> get todaysLoveGoals {
    final source = _goalsDay;
    final ids = source?.goalIds ?? const <String>[];
    if (ids.isEmpty) {
      final key = ritualDateKey(_localNow);
      return loveGoalsForConnectionCycle(key, source?.connectionCycle ?? 0);
    }
    final byId = {for (final g in loveGoalCatalog) g.id: g};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  int get loveGoalsDoneCount {
    final source = _goalsDay;
    final mine = source?.myCompleted(iAmMemberA) ?? const [];
    return todaysLoveGoals.where((g) => mine.contains(g.id)).length;
  }

  int get partnerLoveGoalsDoneCount {
    final source = _goalsDay;
    final theirs = source?.theirCompleted(iAmMemberA) ?? const [];
    return todaysLoveGoals.where((g) => theirs.contains(g.id)).length;
  }

  int get loveGoalsTotal => todaysLoveGoals.length;

  bool get allLoveGoalsDone {
    final source = _goalsDay;
    if (source == null || !loveGoalsUnlocked) return false;
    return source.bothCompletedAllGoals();
  }

  bool isLoveGoalDone(String id) {
    final mine = _goalsDay?.myCompleted(iAmMemberA) ?? const [];
    return mine.contains(id);
  }

  bool isPartnerLoveGoalDone(String id) {
    final theirs = _goalsDay?.theirCompleted(iAmMemberA) ?? const [];
    return theirs.contains(id);
  }

  void setState(SoulState next) {
    if (_state == next) return;
    _state = next;
    _notify();
  }

  Future<void> setCosmetic(CompanionCosmetic next) async {
    if (_cosmetic == next) return;
    _cosmetic = next;
    _notify();
    try {
      final updated = await coupleService.setCosmetic(
        couple: _couple,
        cosmetic: next.name,
      );
      _couple = updated;
      _cosmetic = _parseCosmetic(updated.cosmetic);
      await _persistCache();
      _notify();
    } catch (_) {}
  }

  Future<void> setMyDisplayName(String name) async {
    final profile = await coupleService.setMyDisplayName(name);
    _myName = _prettyName(profile.displayName, fallback: 'You');
    await _persistCache();
    _notify();
  }

  Future<void> leaveCouple() async {
    await _coupleSub?.cancel();
    _coupleSub = null;
    await coupleService.leaveCouple();
    await SessionCache.clear();
  }

  void previewEvolution(CompanionEvolution stage) {
    _evolutionOverride = stage;
    _notify();
  }

  void clearEvolutionPreview() {
    _evolutionOverride = null;
    _notify();
  }

  void setWholeBondDays(int days) {
    _couple = _couple.copyWith(wholeBondDays: days.clamp(0, 999));
    _notify();
  }

  Future<void> ensureToday() async {
    final day = await coupleService.ensureTodayDay(_couple);
    _applyDay(day);
    await _ensureDaySubscription(day.dateKey);
    await _refreshCouple();
    await _refreshGoalsSource();
    await _maybeBeginNextConnection();
    _syncCooldownTicker();
  }

  Future<bool> submitMyAnswer(String answer) async {
    final d = _day;
    if (d == null) return false;
    if (isCoolingDown) return false;
    final trimmed = answer.trim();
    if (trimmed.isEmpty || iAnsweredToday) return false;
    final updated = await coupleService.submitMyAnswer(
      day: d,
      answer: trimmed,
    );
    _applyDay(updated);
    await _refreshCouple();
    await _refreshGoalsSource();
    _syncCooldownTicker();
    return true;
  }

  Future<bool> completeRealGoal(String goalId) async {
    final source = _goalsDay;
    if (source == null || !loveGoalsUnlocked) return false;
    LoveGoal? goal;
    for (final g in todaysLoveGoals) {
      if (g.id == goalId) {
        goal = g;
        break;
      }
    }
    if (goal == null) return false;
    if (isLoveGoalDone(goalId)) return false;

    final updated = await coupleService.completeMyGoal(
      day: source,
      goalId: goalId,
    );
    if (_day?.id == updated.id) {
      _applyDay(updated);
    } else {
      _goalsSourceDay = updated;
    }
    // Timer may have just started when both finished all three.
    await _refreshCouple();
    await _refreshGoalsSource();
    _syncCooldownTicker();
    _notify();
    return true;
  }

  Future<void> _bootstrap() async {
    _bootstrapping = true;
    _cosmetic = _parseCosmetic(_couple.cosmetic);

    final cached = await SessionCache.read(_couple.id);
    if (cached != null) {
      _myName = cached.myName;
      _partnerName = cached.partnerName;
      if (_couple.cosmetic == 'none') {
        _cosmetic = _parseCosmetic(cached.cosmetic);
      }
    }

    await Future.wait([
      _loadNames(),
      ensureToday(),
    ]);

    _coupleSub = coupleService.watchCouple(_couple.id).listen((c) {
      if (c == null) return;
      if (!c.isFull || !c.isMember(userId ?? '')) {
        onCoupleIncomplete?.call();
        return;
      }
      final partnerChanged = c.memberB != _couple.memberB;
      _couple = c;
      _cosmetic = _parseCosmetic(c.cosmetic);
      if (partnerChanged) unawaited(_loadNames());
      unawaited(_persistCache());
      _syncMood(celebrate: false);
      _syncCooldownTicker();
      unawaited(_refreshGoalsSource());
      unawaited(_maybeBeginNextConnection());
      _notify();
    });

    await _persistCache();
    _bootstrapping = false;
    _ready = true;
    _syncCooldownTicker();
    notifyListeners();
  }

  Future<void> _refreshGoalsSource() async {
    if (!isCoolingDown) {
      _goalsSourceDay = null;
      return;
    }
    if (_day?.bothAnswered == true) {
      _goalsSourceDay = _day;
      return;
    }
    _goalsSourceDay =
        await coupleService.fetchLatestConnectedDay(_couple.id);
  }

  Future<void> _maybeBeginNextConnection() async {
    if (_advancingCycle || _bootstrapping) return;
    if (isCoolingDown) return;
    if (!awaitingNextConnection) return;

    _advancingCycle = true;
    try {
      // Refresh so we don't race on a stale cooldown_until.
      await _refreshCouple();
      if (isCoolingDown) return;

      final next = await coupleService.beginNextConnection(_couple);
      _couple = next.couple;
      _goalsSourceDay = null;
      if (next.day != null) {
        _applyDay(next.day!);
        await _ensureDaySubscription(next.day!.dateKey);
      } else {
        final day = await coupleService.ensureTodayDay(_couple);
        _applyDay(day);
        await _ensureDaySubscription(day.dateKey);
      }
      await _refreshGoalsSource();
      _syncCooldownTicker();
      _notify();
    } catch (_) {
      // Partner won the race or transient error — refresh and retry once.
      try {
        await _refreshCouple();
        final day = await coupleService.ensureTodayDay(_couple);
        _applyDay(day);
        if (!isCoolingDown && awaitingNextConnection) {
          final retry = await coupleService.beginNextConnection(_couple);
          _couple = retry.couple;
          _goalsSourceDay = null;
          if (retry.day != null) {
            _applyDay(retry.day!);
          }
        }
      } catch (_) {}
      _syncCooldownTicker();
      _notify();
    } finally {
      _advancingCycle = false;
    }
  }

  void _syncCooldownTicker() {
    _cooldownTicker?.cancel();
    _cooldownTicker = null;
    if (isCoolingDown) {
      _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!isCoolingDown) {
          _cooldownTicker?.cancel();
          _cooldownTicker = null;
          unawaited(_maybeBeginNextConnection());
        }
        _notify();
      });
      return;
    }
    // Timer already ended but cycle not advanced yet — keep trying.
    if (awaitingNextConnection) {
      _cooldownTicker = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!awaitingNextConnection) {
          _cooldownTicker?.cancel();
          _cooldownTicker = null;
          return;
        }
        unawaited(_maybeBeginNextConnection());
      });
    }
  }

  Future<void> _ensureDaySubscription(String dateKey) async {
    if (_watchingDateKey == dateKey && _daySub != null) return;
    await _daySub?.cancel();
    _watchingDateKey = dateKey;
    _daySub = coupleService.watchDay(_couple.id, dateKey).listen((d) {
      if (d == null) return;
      _applyDay(d);
      unawaited(_refreshGoalsSource());
    });
  }

  Future<void> _loadNames() async {
    final uid = userId;
    if (uid == null) return;
    final mine = await coupleService.fetchMyProfile();
    final partnerId = iAmMemberA ? _couple.memberB : _couple.memberA;
    Profile? partner;
    if (partnerId != null) {
      partner = await coupleService.fetchProfile(partnerId);
    }
    _myName = _prettyName(mine?.displayName, fallback: 'You');
    _partnerName = _prettyName(partner?.displayName, fallback: 'Them');
    _notify();
  }

  Future<void> _persistCache() async {
    await SessionCache.write(
      coupleId: _couple.id,
      myName: _myName,
      partnerName: _partnerName,
      cosmetic: _cosmetic.name,
    );
  }

  Future<void> _refreshCouple() async {
    final c = await coupleService.fetchMyCouple();
    if (c != null) {
      _couple = c;
      _cosmetic = _parseCosmetic(c.cosmetic);
    }
  }

  void _applyDay(CoupleDay day) {
    final prevBoth = _day?.bothAnswered ?? false;
    _day = day;
    _syncMood(celebrate: !prevBoth && day.bothAnswered);
    _notify();
  }

  void _notify() {
    if (_bootstrapping) return;
    notifyListeners();
  }

  void _syncMood({required bool celebrate}) {
    final r = ritual;
    if (r.bothComplete || (isCoolingDown && loveGoalsUnlocked)) {
      if (allLoveGoalsDone) {
        _state = SoulState.reunited;
      } else {
        _state = celebrate ? SoulState.reunited : SoulState.whole;
      }
    } else if (r.iAnswered || r.partnerAnswered) {
      _state = SoulState.waiting;
    } else {
      _state = SoulState.lonely;
    }
  }

  static CompanionCosmetic _parseCosmetic(String raw) {
    for (final c in CompanionCosmetic.values) {
      if (c.name == raw) return c;
    }
    return CompanionCosmetic.none;
  }

  static String _prettyName(String? raw, {required String fallback}) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return fallback;
    return t;
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _coupleSub?.cancel();
    _daySub?.cancel();
    super.dispose();
  }
}
