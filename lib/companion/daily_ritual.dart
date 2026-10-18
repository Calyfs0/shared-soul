// One soft daily note — show up means leaving a little something, not a quiz.

class RitualPrompt {
  const RitualPrompt({
    required this.id,
    required this.text,
    this.whisper,
    this.chipOnly = false,
  });

  final String id;

  /// Warm invitation line (not a test question).
  /// Use `{name}` where the partner’s display name should appear.
  final String text;

  /// Tiny hint under the invitation. May include `{name}`.
  final String? whisper;

  /// When true, only tap feelings (no free text).
  final bool chipOnly;

  String textFor(String partnerName) =>
      text.replaceAll('{name}', partnerName);

  String? whisperFor(String partnerName) =>
      whisper?.replaceAll('{name}', partnerName);
}

/// Soft rotating invitations — one shared per calendar day.
const List<RitualPrompt> ritualPromptCatalog = [
  RitualPrompt(
    id: 'think_of_them',
    text: 'Something about {name} crossed your mind…',
    whisper: 'Leave whatever floated up.',
  ),
  RitualPrompt(
    id: 'one_word',
    text: 'If tonight had one soft word for you two…',
    whisper: 'It can be tiny.',
  ),
  RitualPrompt(
    id: 'grateful_for',
    text: 'A small kindness you noticed from {name}…',
    whisper: 'Even something ordinary.',
  ),
  RitualPrompt(
    id: 'soft_chip_day',
    text: 'How does your heart sit with {name} today?',
    whisper: 'Just tap what fits.',
    chipOnly: true,
  ),
  RitualPrompt(
    id: 'miss_or_near',
    text: 'Does {name} feel near, or a little far?',
    whisper: 'Either is okay.',
  ),
  RitualPrompt(
    id: 'proud_moment',
    text: 'Something about {name} you’re quietly proud of…',
    whisper: '{name} won’t see a score — only you.',
  ),
];

/// Gentle feelings — not multiple-choice options.
const List<String> ritualChips = [
  'Grateful',
  'Miss you',
  'Proud of you',
  'Want a hug',
];

/// Date key in local calendar: `yyyy-MM-dd`.
String ritualDateKey(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

RitualPrompt promptForDate(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  final dayOfYear = local.difference(DateTime(local.year)).inDays;
  return ritualPromptCatalog[dayOfYear % ritualPromptCatalog.length];
}

/// Today's ritual notes for the couple (local-first).
class DailyRitual {
  const DailyRitual({
    required this.dateKey,
    required this.prompt,
    this.myAnswer,
    this.partnerAnswer,
  });

  final String dateKey;
  final RitualPrompt prompt;
  final String? myAnswer;
  final String? partnerAnswer;

  bool get iAnswered => myAnswer != null && myAnswer!.trim().isNotEmpty;
  bool get partnerAnswered =>
      partnerAnswer != null && partnerAnswer!.trim().isNotEmpty;
  bool get bothComplete => iAnswered && partnerAnswered;

  DailyRitual copyWith({
    String? myAnswer,
    String? partnerAnswer,
    bool clearMyAnswer = false,
    bool clearPartnerAnswer = false,
  }) {
    return DailyRitual(
      dateKey: dateKey,
      prompt: prompt,
      myAnswer: clearMyAnswer ? null : (myAnswer ?? this.myAnswer),
      partnerAnswer:
          clearPartnerAnswer ? null : (partnerAnswer ?? this.partnerAnswer),
    );
  }

  static DailyRitual forToday([DateTime? now]) {
    final date = now ?? DateTime.now();
    return DailyRitual(
      dateKey: ritualDateKey(date),
      prompt: promptForDate(date),
    );
  }
}
