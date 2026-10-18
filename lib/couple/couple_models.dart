class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    this.coupleId,
  });

  final String id;
  final String displayName;
  final String? coupleId;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: (json['display_name'] as String?) ?? '',
      coupleId: json['couple_id'] as String?,
    );
  }
}

class Couple {
  const Couple({
    required this.id,
    required this.inviteCode,
    required this.memberA,
    this.memberB,
    required this.timezoneOffsetMinutes,
    required this.wholeBondDays,
    required this.countedDayKeys,
    this.cosmetic = 'none',
    this.discoveredMemories = const [],
    this.cooldownUntil,
  });

  final String id;
  final String inviteCode;
  final String memberA;
  final String? memberB;
  final int timezoneOffsetMinutes;
  final int wholeBondDays;
  final List<String> countedDayKeys;
  final String cosmetic;
  final List<String> discoveredMemories;
  final DateTime? cooldownUntil;

  bool get isFull => memberB != null;

  bool isMember(String uid) => uid == memberA || uid == memberB;

  bool isMemberA(String uid) => uid == memberA;

  /// True while the shared 4h come-back timer is running.
  bool get isCoolingDown {
    final until = cooldownUntil;
    if (until == null) return false;
    return until.isAfter(DateTime.now().toUtc());
  }

  Duration? get cooldownRemaining {
    final until = cooldownUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now().toUtc());
    if (left.isNegative) return Duration.zero;
    return left;
  }

  factory Couple.fromJson(Map<String, dynamic> json) {
    final counted = json['counted_day_keys'];
    final memories = json['discovered_memories'];
    final cool = json['cooldown_until'];
    return Couple(
      id: json['id'] as String,
      inviteCode: json['invite_code'] as String,
      memberA: json['member_a'] as String,
      memberB: json['member_b'] as String?,
      timezoneOffsetMinutes:
          (json['timezone_offset_minutes'] as num?)?.toInt() ?? 0,
      wholeBondDays: (json['whole_bond_days'] as num?)?.toInt() ?? 0,
      countedDayKeys: counted is List
          ? counted.map((e) => e.toString()).toList()
          : const [],
      cosmetic: (json['cosmetic'] as String?) ?? 'none',
      discoveredMemories: memories is List
          ? memories.map((e) => e.toString()).toList()
          : const [],
      cooldownUntil: cool == null ? null : DateTime.tryParse(cool.toString())?.toUtc(),
    );
  }

  Couple copyWith({
    String? memberB,
    int? wholeBondDays,
    List<String>? countedDayKeys,
    String? cosmetic,
    List<String>? discoveredMemories,
    DateTime? cooldownUntil,
    bool clearCooldown = false,
  }) {
    return Couple(
      id: id,
      inviteCode: inviteCode,
      memberA: memberA,
      memberB: memberB ?? this.memberB,
      timezoneOffsetMinutes: timezoneOffsetMinutes,
      wholeBondDays: wholeBondDays ?? this.wholeBondDays,
      countedDayKeys: countedDayKeys ?? this.countedDayKeys,
      cosmetic: cosmetic ?? this.cosmetic,
      discoveredMemories: discoveredMemories ?? this.discoveredMemories,
      cooldownUntil:
          clearCooldown ? null : (cooldownUntil ?? this.cooldownUntil),
    );
  }
}

class CoupleDay {
  const CoupleDay({
    required this.id,
    required this.coupleId,
    required this.dateKey,
    required this.promptId,
    this.answerA,
    this.answerB,
    this.goalsSlotKey,
    required this.goalRound,
    required this.goalIds,
    required this.completedA,
    required this.completedB,
    this.connectionCycle = 0,
  });

  final String id;
  final String coupleId;
  final String dateKey;
  final String promptId;
  final String? answerA;
  final String? answerB;
  final String? goalsSlotKey;
  final int goalRound;
  final List<String> goalIds;
  final List<String> completedA;
  final List<String> completedB;
  final int connectionCycle;

  bool get bothAnswered {
    final a = answerA?.trim() ?? '';
    final b = answerB?.trim() ?? '';
    return a.isNotEmpty && b.isNotEmpty;
  }

  String? myAnswer(bool iAmA) => iAmA ? answerA : answerB;
  String? theirAnswer(bool iAmA) => iAmA ? answerB : answerA;

  List<String> myCompleted(bool iAmA) => iAmA ? completedA : completedB;
  List<String> theirCompleted(bool iAmA) => iAmA ? completedB : completedA;

  bool bothCompletedAllGoals() {
    if (goalIds.isEmpty) return false;
    for (final id in goalIds) {
      if (!completedA.contains(id) || !completedB.contains(id)) return false;
    }
    return true;
  }

  factory CoupleDay.fromJson(Map<String, dynamic> json) {
    List<String> asList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];

    return CoupleDay(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      dateKey: json['date_key'] as String,
      promptId: json['prompt_id'] as String,
      answerA: json['answer_a'] as String?,
      answerB: json['answer_b'] as String?,
      goalsSlotKey: json['goals_slot_key'] as String?,
      goalRound: (json['goal_round'] as num?)?.toInt() ?? 0,
      goalIds: asList(json['goal_ids']),
      completedA: asList(json['completed_a']),
      completedB: asList(json['completed_b']),
      connectionCycle: (json['connection_cycle'] as num?)?.toInt() ?? 0,
    );
  }
}
