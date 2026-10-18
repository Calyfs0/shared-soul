/// Companion growth from shared bond days (whole days both showed up).
///
/// Desire ladder (same soul, new job):
/// - Spark wants light it can hold
/// - Drift wants to go somewhere with you
/// - Starlit wants to keep that light — sky that stays
enum CompanionEvolution {
  /// Day 0 — a little puff that just learned it exists.
  spark,

  /// After [driftDays] — traveler cloud, coming along.
  drift,

  /// After [ascendantDays] — star-mist that learned to keep the moon.
  ascendant,
}

extension CompanionEvolutionX on CompanionEvolution {
  String get label => switch (this) {
    CompanionEvolution.spark => 'Spark',
    CompanionEvolution.drift => 'Drift',
    CompanionEvolution.ascendant => 'Starlit',
  };

  String get subtitle => switch (this) {
    CompanionEvolution.spark => 'Just a little puff',
    CompanionEvolution.drift => 'Coming along with you',
    CompanionEvolution.ascendant => 'Learned to keep the light',
  };

  /// Uppercase stage name for the hero identity.
  String get displayTitle => label.toUpperCase();

  /// Soft emotional line under the stage name.
  String get emotionalLine => switch (this) {
    CompanionEvolution.spark => 'A little closer, every day.',
    CompanionEvolution.drift => 'Finding its way with you.',
    CompanionEvolution.ascendant => 'Sky that stays.',
  };

  /// Whole bond days required to unlock this stage.
  int get requiredWholeDays => switch (this) {
    CompanionEvolution.spark => 0,
    CompanionEvolution.drift => driftDays,
    CompanionEvolution.ascendant => ascendantDays,
  };

  /// Body scale — close across stages; feeling does the work.
  double get bodyScale => switch (this) {
    CompanionEvolution.spark => 1.0,
    CompanionEvolution.drift => 1.08,
    CompanionEvolution.ascendant => 1.0,
  };

  static const driftDays = 7;
  static const ascendantDays = 30;

  static CompanionEvolution fromWholeDays(int wholeDays) {
    if (wholeDays >= ascendantDays) return CompanionEvolution.ascendant;
    if (wholeDays >= driftDays) return CompanionEvolution.drift;
    return CompanionEvolution.spark;
  }
}
