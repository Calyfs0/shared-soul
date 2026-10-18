/// Preview cosmetics that layer onto the moon creature.
enum CompanionCosmetic {
  none,
  starBeret,
  roundGlasses,
  cozyScarf,
  flowerClip,
  moonBow,
}

extension CompanionCosmeticX on CompanionCosmetic {
  String get label => switch (this) {
    CompanionCosmetic.none => 'None',
    CompanionCosmetic.starBeret => 'Star beret',
    CompanionCosmetic.roundGlasses => 'Round glasses',
    CompanionCosmetic.cozyScarf => 'Cozy scarf',
    CompanionCosmetic.flowerClip => 'Flower clip',
    CompanionCosmetic.moonBow => 'Moon bow',
  };
}
