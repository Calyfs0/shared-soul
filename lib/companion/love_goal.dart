import 'dart:math' as math;

import 'daily_ritual.dart';

/// Real-world affection tasks — only when both partners are on.
enum LoveGoalKind {
  /// Do it in real life, then check it off.
  real,
}

/// Local time windows for when a task makes sense.
enum DayPart {
  /// ~5:00–10:59
  morning,

  /// ~11:00–16:59
  day,

  /// ~17:00–20:59
  evening,

  /// ~21:00–4:59
  night,
}

extension DayPartX on DayPart {
  String get label => switch (this) {
    DayPart.morning => 'Morning',
    DayPart.day => 'Afternoon',
    DayPart.evening => 'Evening',
    DayPart.night => 'Night',
  };
}

DayPart dayPartFor(DateTime local) {
  final h = local.hour;
  if (h >= 5 && h < 11) return DayPart.morning;
  if (h >= 11 && h < 17) return DayPart.day;
  if (h >= 17 && h < 21) return DayPart.evening;
  return DayPart.night;
}

class LoveGoal {
  const LoveGoal({
    required this.id,
    required this.title,
    required this.detail,
    this.kind = LoveGoalKind.real,
    this.parts = const {
      DayPart.morning,
      DayPart.day,
      DayPart.evening,
      DayPart.night,
    },
  });

  final String id;
  final String title;
  final String detail;
  final LoveGoalKind kind;

  /// When this task is offered (local time).
  final Set<DayPart> parts;

  bool fits(DayPart part) => parts.contains(part);
}

/// Concrete real-life tasks, tagged by time of day.
const List<LoveGoal> loveGoalCatalog = [
  LoveGoal(
    id: 'morning_text',
    title: 'Send a real good-morning text',
    detail: 'Before the day gets loud.',
    parts: {DayPart.morning},
  ),
  LoveGoal(
    id: 'morning_coffee',
    title: 'Bring or send them a morning coffee',
    detail: 'Or their usual wake-up drink.',
    parts: {DayPart.morning},
  ),
  LoveGoal(
    id: 'breakfast_together',
    title: 'Share breakfast together',
    detail: 'Same table, or on a call while you both eat.',
    parts: {DayPart.morning},
  ),
  LoveGoal(
    id: 'ask_day_plan',
    title: 'Ask what their day looks like',
    detail: 'Listen — then check in on one thing later.',
    parts: {DayPart.morning, DayPart.day},
  ),
  LoveGoal(
    id: 'lunch_checkin',
    title: 'Check in around lunch',
    detail: 'A real call or voice note — “how’s it going?”',
    parts: {DayPart.day},
  ),
  LoveGoal(
    id: 'afternoon_walk',
    title: 'Go for a walk together',
    detail: 'Outside, side by side — even a short one.',
    parts: {DayPart.day, DayPart.evening},
  ),
  LoveGoal(
    id: 'ask_day',
    title: 'Ask about their day — and listen',
    detail: 'Follow up on one detail. No half-listening.',
    parts: {DayPart.evening, DayPart.night},
  ),
  LoveGoal(
    id: 'cook_dinner',
    title: 'Cook or eat dinner together',
    detail: 'Same table, same time — even if it’s takeout.',
    parts: {DayPart.evening},
  ),
  LoveGoal(
    id: 'goodnight_call',
    title: 'Call to say goodnight',
    detail: 'Hear their voice before sleep.',
    parts: {DayPart.evening, DayPart.night},
  ),
  LoveGoal(
    id: 'goodnight_text',
    title: 'Send a real goodnight text',
    detail: 'Soft close to the day — not a leftover “ok”.',
    parts: {DayPart.night},
  ),
  LoveGoal(
    id: 'watch_something',
    title: 'Watch something together',
    detail: 'Same show or movie — on a call if you’re apart.',
    parts: {DayPart.evening, DayPart.night},
  ),
  LoveGoal(
    id: 'call_10',
    title: 'Call them for 10 minutes',
    detail: 'A real phone call — not just texts.',
    parts: {DayPart.morning, DayPart.day, DayPart.evening},
  ),
  LoveGoal(
    id: 'video_15',
    title: 'Video call for 15 minutes',
    detail: 'See their face. No multitasking.',
    parts: {DayPart.morning, DayPart.day, DayPart.evening},
  ),
  LoveGoal(
    id: 'voice_note',
    title: 'Send a real voice note',
    detail: 'From your phone. Say something you’d rather speak than type.',
  ),
  LoveGoal(
    id: 'phones_away',
    title: 'Phones away for 30 minutes',
    detail: 'Both of you. No scrolling between you.',
    parts: {DayPart.evening, DayPart.night},
  ),
  LoveGoal(
    id: 'tiny_date',
    title: 'Plan a real date this week',
    detail: 'Pick a day, time, and place — and tell them.',
  ),
  LoveGoal(
    id: 'favorite_treat',
    title: 'Get them their favorite treat',
    detail: 'Coffee, snack, dessert — something they’d actually want.',
    parts: {DayPart.morning, DayPart.day, DayPart.evening},
  ),
  LoveGoal(
    id: 'chore_help',
    title: 'Do a chore they usually handle',
    detail: 'Dishes, laundry, errand — without being asked.',
    parts: {DayPart.day, DayPart.evening},
  ),
  LoveGoal(
    id: 'handwritten',
    title: 'Leave them a handwritten note',
    detail: 'Paper. Pen. Put it where they’ll find it.',
    parts: {DayPart.morning, DayPart.day, DayPart.evening},
  ),
  LoveGoal(
    id: 'sit_together',
    title: 'Sit together for 10 quiet minutes',
    detail: 'Same room or on a call. No phones. Just be there.',
    parts: {DayPart.evening, DayPart.night},
  ),
  LoveGoal(
    id: 'unwind_checkin',
    title: 'Help them unwind after the day',
    detail: 'Tea, a back rub, quiet company — whatever they need.',
    parts: {DayPart.evening, DayPart.night},
  ),
];

const int loveGoalsPerRound = 3;

List<LoveGoal> eligibleLoveGoals(DateTime local) {
  final part = dayPartFor(local);
  return loveGoalCatalog.where((g) => g.fits(part)).toList(growable: false);
}

List<LoveGoal> _shuffledEligible(DateTime local) {
  final part = dayPartFor(local);
  final list = List<LoveGoal>.from(eligibleLoveGoals(local));
  // Stable for this calendar day + time window.
  final seed = local.year * 10000 +
      local.month * 400 +
      local.day * 10 +
      part.index;
  final rng = math.Random(seed);
  for (var i = list.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
  return list;
}

/// Three goals for [round] that fit the local time. Empty if none left.
List<LoveGoal> loveGoalsForRound(DateTime local, int round) {
  final all = _shuffledEligible(local);
  final start = round * loveGoalsPerRound;
  if (start >= all.length) return const [];
  final end = math.min(start + loveGoalsPerRound, all.length);
  return all.sublist(start, end);
}

/// Anytime connection cycle — three tasks from the full catalog (no day-part gate).
List<LoveGoal> loveGoalsForConnectionCycle(String dateKey, int cycle) {
  final list = List<LoveGoal>.from(loveGoalCatalog);
  final seed = Object.hash(dateKey, cycle);
  final rng = math.Random(seed);
  for (var i = list.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
  final end = math.min(loveGoalsPerRound, list.length);
  return list.sublist(0, end);
}

bool hasLoveGoalRound(DateTime local, int round) =>
    loveGoalsForRound(local, round).isNotEmpty;

List<LoveGoal> loveGoalsForDate(DateTime local) => loveGoalsForRound(local, 0);

String loveGoalsDateKey(DateTime date) => ritualDateKey(date);

/// Stable slot key for a connection cycle (no clock day-part rotation).
String loveGoalsCycleSlotKey(String dateKey, int cycle) =>
    '${dateKey}_c$cycle';

/// Day + day-part key (legacy / local sketches).
String loveGoalsSlotKey(DateTime local) =>
    '${loveGoalsDateKey(local)}_${dayPartFor(local).name}';
