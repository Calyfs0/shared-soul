import 'evolution.dart';

/// Bond progress derived only from real whole-bond days — no invented scores.
class BondProgress {
  const BondProgress({
    required this.wholeDays,
    required this.evolution,
    required this.nextMilestoneDays,
    required this.nextMilestoneLabel,
    required this.progressToNext,
    required this.statusLabel,
  });

  final int wholeDays;
  final CompanionEvolution evolution;

  /// Null when already at the final known stage.
  final int? nextMilestoneDays;
  final String? nextMilestoneLabel;

  /// 0–1 toward next known evolution unlock, or null if none.
  final double? progressToNext;
  final String statusLabel;

  factory BondProgress.fromDays(int wholeDays) {
    final evolution = CompanionEvolutionX.fromWholeDays(wholeDays);
    final next = _next(evolution);
    double? progress;
    if (next != null) {
      final prev = evolution.requiredWholeDays;
      final span = next.requiredWholeDays - prev;
      if (span > 0) {
        progress = ((wholeDays - prev) / span).clamp(0.0, 1.0);
      }
    }

    return BondProgress(
      wholeDays: wholeDays,
      evolution: evolution,
      nextMilestoneDays: next?.requiredWholeDays,
      nextMilestoneLabel: next?.label,
      progressToNext: progress,
      statusLabel: next == null ? 'Held' : 'Growing',
    );
  }

  static CompanionEvolution? _next(CompanionEvolution current) {
    final i = current.index + 1;
    if (i >= CompanionEvolution.values.length) return null;
    return CompanionEvolution.values[i];
  }

  String get togethernessLine {
    if (wholeDays <= 0) return '✦ Beginning together';
    if (wholeDays == 1) return '✦ 1 day of togetherness';
    return '✦ $wholeDays days of togetherness';
  }

  String? get nextMilestoneExplanation {
    final days = nextMilestoneDays;
    final label = nextMilestoneLabel;
    if (days == null || label == null) {
      return 'Your companion has reached the light it can keep.';
    }
    final remaining = days - wholeDays;
    if (remaining <= 0) return 'Ready for $label.';
    if (remaining == 1) return '1 more whole day until $label.';
    return '$remaining more whole days until $label.';
  }
}

/// System milestones unlocked by real bond days — not fabricated memories.
class BondMemory {
  const BondMemory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final BondMemoryIcon icon;
}

enum BondMemoryIcon { spark, night, journey, moon }

/// Returns up to [limit] milestones the couple has actually earned.
List<BondMemory> earnedMemories(int wholeDays, {int limit = 2}) {
  final all = <BondMemory>[
    const BondMemory(
      id: 'first_spark',
      title: 'First spark',
      description: 'Your little cloud arrived.',
      icon: BondMemoryIcon.spark,
    ),
    if (wholeDays >= CompanionEvolutionX.driftDays)
      const BondMemory(
        id: 'first_week',
        title: 'A quiet week',
        description: 'Seven whole days, side by side.',
        icon: BondMemoryIcon.journey,
      ),
    if (wholeDays >= CompanionEvolutionX.ascendantDays)
      const BondMemory(
        id: 'starlit',
        title: 'Kept the light',
        description: 'Thirty days — the moon stayed.',
        icon: BondMemoryIcon.moon,
      ),
  ];

  // Prefer most recent when over limit
  if (all.length <= limit) return all;
  return all.sublist(all.length - limit);
}

/// Bond-day milestones the couple has earned.
List<BondMemory> gatherMemories({
  required int wholeDays,
  int limit = 3,
}) {
  return earnedMemories(wholeDays, limit: limit);
}
