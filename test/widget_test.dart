import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_companion/companion/love_goal.dart';

void main() {
  test('night window does not offer good-morning tasks', () {
    final night = DateTime(2026, 10, 17, 23, 30);
    final goals = eligibleLoveGoals(night);
    expect(goals.any((g) => g.id == 'morning_text'), isFalse);
    expect(goals.any((g) => g.id == 'goodnight_call'), isTrue);
  });

  test('morning window offers good-morning tasks', () {
    final morning = DateTime(2026, 10, 17, 8, 0);
    final goals = eligibleLoveGoals(morning);
    expect(goals.any((g) => g.id == 'morning_text'), isTrue);
    expect(goals.any((g) => g.id == 'goodnight_call'), isFalse);
  });

  test('rounds return up to three goals', () {
    final evening = DateTime(2026, 10, 17, 19, 0);
    final round0 = loveGoalsForRound(evening, 0);
    expect(round0.length, lessThanOrEqualTo(3));
    expect(round0, isNotEmpty);
  });

  test('connection cycle picks three anytime goals', () {
    final a = loveGoalsForConnectionCycle('2026-10-17', 0);
    final b = loveGoalsForConnectionCycle('2026-10-17', 1);
    expect(a.length, 3);
    expect(b.length, 3);
    // Different cycles should usually differ; allow rare collision.
    expect(a.map((g) => g.id).toList(), isNot(equals(b.map((g) => g.id).toList())));
  });
}
