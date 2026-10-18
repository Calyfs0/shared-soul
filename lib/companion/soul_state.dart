/// Emotional states of the shared companion.
enum SoulState { waiting, lonely, whole, reunited }

extension SoulStateX on SoulState {
  String get label => switch (this) {
    SoulState.waiting => 'Waiting',
    SoulState.lonely => 'Lonely',
    SoulState.whole => 'Whole',
    SoulState.reunited => 'Reunited',
  };

  String get subtitle => switch (this) {
    SoulState.waiting => 'Waiting for us',
    SoulState.lonely => 'Feels a little empty',
    SoulState.whole => 'We\'re whole today',
    SoulState.reunited => 'They came back',
  };

  /// 0 = dimmest / loneliest, 1 = fullest glow.
  double get glowStrength => switch (this) {
    SoulState.waiting => 0.55,
    SoulState.lonely => 0.28,
    SoulState.whole => 0.9,
    SoulState.reunited => 1.0,
  };

  /// Ear droop: 0 upright, 1 fully down.
  double get earDroop => switch (this) {
    SoulState.waiting => 0.15,
    SoulState.lonely => 0.85,
    SoulState.whole => 0.0,
    SoulState.reunited => 0.0,
  };

  /// Body scale / posture curl.
  double get curl => switch (this) {
    SoulState.waiting => 0.08,
    SoulState.lonely => 0.35,
    SoulState.whole => 0.0,
    SoulState.reunited => 0.0,
  };

  bool get celebrates => this == SoulState.reunited;

  /// Mouth smile amount for the moon creature.
  double get smile => switch (this) {
    SoulState.waiting => 0.45,
    SoulState.lonely => 0.18,
    SoulState.whole => 0.85,
    SoulState.reunited => 1.0,
  };

  /// Eye openness bias (sleepy when lonely).
  double get eyeOpenBias => switch (this) {
    SoulState.waiting => 0.95,
    SoulState.lonely => 0.7,
    SoulState.whole => 1.0,
    SoulState.reunited => 1.0,
  };

  /// Left partner figure (e.g. you) — lit when present today.
  bool get leftPartnerPresent => switch (this) {
    SoulState.waiting => true,
    SoulState.lonely => false,
    SoulState.whole => true,
    SoulState.reunited => true,
  };

  /// Right partner figure — lit when they showed up.
  bool get rightPartnerPresent => switch (this) {
    SoulState.waiting => false,
    SoulState.lonely => false,
    SoulState.whole => true,
    SoulState.reunited => true,
  };
}
