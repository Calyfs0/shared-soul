import 'package:flutter/foundation.dart';

import 'cosmetic.dart';
import 'daily_ritual.dart';
import 'evolution.dart';
import 'love_goal.dart';
import 'soul_state.dart';

/// Local-only companion driver (tests / offline sketches).
/// Production uses [SyncedCompanionController].
class CompanionController extends ChangeNotifier {
  CompanionController({DateTime? now}) {
    final at = now ?? DateTime.now();
    _now = at;
    _ritual = DailyRitual.forToday(at);
    _goalsSlotKey = loveGoalsSlotKey(at);
    _todaysGoals = loveGoalsForRound(at, 0);
    _syncMoodFromRitual(celebrate: false);
  }

  DateTime _now = DateTime.now();
  DayPart get currentDayPart => dayPartFor(_now);

  SoulState _state = SoulState.lonely;
  SoulState get state => _state;

  CompanionCosmetic _cosmetic = CompanionCosmetic.none;
  CompanionCosmetic get cosmetic => _cosmetic;

  int _wholeBondDays = 0;
  int get wholeBondDays => _wholeBondDays;

  CompanionEvolution? _evolutionOverride;
  CompanionEvolution get evolution =>
      _evolutionOverride ?? CompanionEvolutionX.fromWholeDays(_wholeBondDays);

  late DailyRitual _ritual;
  DailyRitual get ritual => _ritual;

  final Set<String> _countedWholeDays = <String>{};

  late String _goalsSlotKey;
  late List<LoveGoal> _todaysGoals;
  final Set<String> _completedGoalIds = <String>{};

  List<LoveGoal> get todaysLoveGoals => List.unmodifiable(_todaysGoals);

  String get togetherWindowLabel => switch (currentDayPart) {
    DayPart.morning => 'This morning',
    DayPart.day => 'This afternoon',
    DayPart.evening => 'This evening',
    DayPart.night => 'Tonight',
  };

  bool get iAnsweredToday => _ritual.iAnswered;
  bool get partnerAnsweredToday => _ritual.partnerAnswered;
  bool get bothAnsweredToday => _ritual.bothComplete;
  bool get needsCheckIn => !_ritual.iAnswered;
  bool get waitingOnPartner => _ritual.iAnswered && !_ritual.partnerAnswered;
  bool get loveGoalsUnlocked => _ritual.bothComplete;

  int get loveGoalsDoneCount =>
      _todaysGoals.where((g) => _completedGoalIds.contains(g.id)).length;

  int get loveGoalsTotal => _todaysGoals.length;

  bool get allLoveGoalsDone =>
      loveGoalsUnlocked &&
      loveGoalsTotal > 0 &&
      loveGoalsDoneCount >= loveGoalsTotal;

  bool isLoveGoalDone(String id) => _completedGoalIds.contains(id);

  void setState(SoulState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  void setCosmetic(CompanionCosmetic next) {
    if (_cosmetic == next) return;
    _cosmetic = next;
    notifyListeners();
  }

  void setWholeBondDays(int days) {
    final d = days.clamp(0, 999);
    if (_wholeBondDays == d) return;
    _wholeBondDays = d;
    notifyListeners();
  }

  void previewEvolution(CompanionEvolution stage) {
    _evolutionOverride = stage;
    _wholeBondDays = stage.requiredWholeDays;
    notifyListeners();
  }

  void clearEvolutionPreview() {
    _evolutionOverride = null;
    notifyListeners();
  }

  void ensureToday([DateTime? now]) {
    final at = now ?? DateTime.now();
    _now = at;
    final fresh = DailyRitual.forToday(at);
    final slotKey = loveGoalsSlotKey(at);
    var changed = false;

    if (fresh.dateKey != _ritual.dateKey) {
      _ritual = fresh;
      _syncMoodFromRitual(celebrate: false);
      changed = true;
    }
    if (slotKey != _goalsSlotKey) {
      _goalsSlotKey = slotKey;
      _todaysGoals = loveGoalsForRound(at, 0);
      _completedGoalIds.clear();
      changed = true;
    }
    if (changed) notifyListeners();
  }

  bool submitMyAnswer(String answer) {
    ensureToday();
    final trimmed = answer.trim();
    if (trimmed.isEmpty || _ritual.iAnswered) return false;

    final wasPartnerDone = _ritual.partnerAnswered;
    _ritual = _ritual.copyWith(myAnswer: trimmed);
    _onAnswerProgress(justCompletedBoth: wasPartnerDone);
    return true;
  }

  bool simulatePartnerAnswer([String answer = 'Thinking of you']) {
    ensureToday();
    if (_ritual.partnerAnswered) return false;

    final wasIDone = _ritual.iAnswered;
    _ritual = _ritual.copyWith(partnerAnswer: answer.trim());
    _onAnswerProgress(justCompletedBoth: wasIDone);
    return true;
  }

  void clearPartnerAnswerForDebug() {
    ensureToday();
    if (!_ritual.partnerAnswered) return;
    _ritual = _ritual.copyWith(clearPartnerAnswer: true);
    _syncMoodFromRitual(celebrate: false);
    notifyListeners();
  }

  bool completeRealGoal(String goalId) {
    ensureToday();
    if (!loveGoalsUnlocked) return false;
    LoveGoal? goal;
    for (final g in _todaysGoals) {
      if (g.id == goalId) {
        goal = g;
        break;
      }
    }
    if (goal == null) return false;
    if (_completedGoalIds.contains(goalId)) return false;

    _completedGoalIds.add(goalId);
    if (allLoveGoalsDone) {
      _state = SoulState.reunited;
    } else {
      _state = SoulState.whole;
    }
    notifyListeners();
    return true;
  }

  void _onAnswerProgress({required bool justCompletedBoth}) {
    if (justCompletedBoth && _ritual.bothComplete) {
      _countWholeDayIfNeeded();
      _syncMoodFromRitual(celebrate: true);
    } else {
      _syncMoodFromRitual(celebrate: false);
    }
    notifyListeners();
  }

  void _countWholeDayIfNeeded() {
    if (!_ritual.bothComplete) return;
    if (_countedWholeDays.contains(_ritual.dateKey)) return;
    _countedWholeDays.add(_ritual.dateKey);
    _wholeBondDays = (_wholeBondDays + 1).clamp(0, 999);
  }

  void _syncMoodFromRitual({required bool celebrate}) {
    if (_ritual.bothComplete) {
      if (allLoveGoalsDone) {
        _state = SoulState.reunited;
      } else {
        _state = celebrate ? SoulState.reunited : SoulState.whole;
      }
    } else if (_ritual.iAnswered || _ritual.partnerAnswered) {
      _state = SoulState.waiting;
    } else {
      _state = SoulState.lonely;
    }
  }
}
