import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/soul_colors.dart';
import '../theme/soul_typography.dart';
import 'daily_ritual.dart';
import 'synced_companion_controller.dart';

/// Leave a little note for them — quiet check-in, not a quiz.
class DailyRitualScreen extends StatefulWidget {
  const DailyRitualScreen({super.key, required this.controller});

  final SyncedCompanionController controller;

  @override
  State<DailyRitualScreen> createState() => _DailyRitualScreenState();
}

class _DailyRitualScreenState extends State<DailyRitualScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  String? _selectedChip;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.ensureToday();
    _submitted = widget.controller.iAnsweredToday;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? get _composedAnswer {
    final typed = _text.text.trim();
    if (typed.isNotEmpty) return typed;
    return _selectedChip;
  }

  Future<void> _submit() async {
    final answer = _composedAnswer;
    if (answer == null || answer.isEmpty) return;
    try {
      final ok = await widget.controller.submitMyAnswer(answer);
      if (!mounted) return;
      if (!ok) {
        final msg = widget.controller.isCoolingDown
            ? 'Come back after the rest timer.'
            : 'Couldn’t send that. Try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      HapticFeedback.lightImpact();
      _focus.unfocus();
      setState(() => _submitted = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t send that. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SoulColors.nightDeep,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final ritual = widget.controller.ritual;
              final prompt = ritual.prompt;
              final both = ritual.bothComplete;
              final waiting = ritual.iAnswered && !ritual.partnerAnswered;
              final composing = !_submitted && !ritual.iAnswered;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        Icons.close,
                        color: SoulColors.mistyLavender.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                      child: composing
                          ? _Compose(
                              prompt: prompt,
                              partnerName:
                                  widget.controller.partnerDisplayName,
                              text: _text,
                              focus: _focus,
                              selectedChip: _selectedChip,
                              onChip: (chip) => setState(() {
                                _selectedChip = chip;
                                if (prompt.chipOnly) _text.clear();
                              }),
                              onTextChanged: () => setState(() {}),
                              canSend: _composedAnswer != null,
                              onSend: _submit,
                            )
                          : _AfterNote(
                              partnerName:
                                  widget.controller.partnerDisplayName,
                              myNote: ritual.myAnswer ?? '—',
                              theirNote: ritual.partnerAnswer,
                              both: both,
                              waiting: waiting,
                              onDone: () => Navigator.of(context).maybePop(),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Compose extends StatelessWidget {
  const _Compose({
    required this.prompt,
    required this.partnerName,
    required this.text,
    required this.focus,
    required this.selectedChip,
    required this.onChip,
    required this.onTextChanged,
    required this.canSend,
    required this.onSend,
  });

  final RitualPrompt prompt;
  final String partnerName;
  final TextEditingController text;
  final FocusNode focus;
  final String? selectedChip;
  final ValueChanged<String> onChip;
  final VoidCallback onTextChanged;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final whisper = prompt.whisperFor(partnerName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        Text(
          'For $partnerName',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SoulColors.celestialGold.withValues(alpha: 0.75),
            fontSize: 12,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          prompt.textFor(partnerName),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SoulColors.warmIvory.withValues(alpha: 0.96),
            fontSize: 22,
            height: 1.4,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (whisper != null) ...[
          const SizedBox(height: 10),
          Text(
            whisper,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SoulColors.mistyLavender.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 36),
        if (!prompt.chipOnly) ...[
          TextField(
            controller: text,
            focusNode: focus,
            maxLength: 120,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(
              color: SoulColors.warmIvory,
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
            cursorColor: SoulColors.celestialGold,
            decoration: InputDecoration(
              hintText: 'A few quiet words…',
              hintStyle: TextStyle(
                color: SoulColors.mistyLavender.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
              counterText: '',
              filled: false,
              border: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: SoulColors.mistyLavender.withValues(alpha: 0.22),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: SoulColors.celestialGold),
              ),
            ),
            onChanged: (_) => onTextChanged(),
          ),
          const SizedBox(height: 28),
          Text(
            'or a feeling',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SoulColors.mistyLavender.withValues(alpha: 0.45),
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in ritualChips)
              _Feeling(
                label: chip,
                selected: selectedChip == chip,
                onTap: () => onChip(chip),
              ),
          ],
        ),
        const Spacer(flex: 3),
        _SendNote(
          enabled: canSend,
          partnerName: partnerName,
          onPressed: onSend,
        ),
      ],
    );
  }
}

class _AfterNote extends StatelessWidget {
  const _AfterNote({
    required this.partnerName,
    required this.myNote,
    required this.theirNote,
    required this.both,
    required this.waiting,
    required this.onDone,
  });

  final String partnerName;
  final String myNote;
  final String? theirNote;
  final bool both;
  final bool waiting;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        Text(
          both ? 'Between you two' : 'Your note is with $partnerName',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SoulColors.celestialGold.withValues(alpha: 0.8),
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        _SoftNote(line: myNote),
        const SizedBox(height: 20),
        if (both)
          _SoftNote(line: theirNote ?? '—', theirs: true)
        else
          Text(
            '$partnerName is still finding their words…',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SoulColors.mistyLavender.withValues(alpha: 0.55),
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        const Spacer(flex: 3),
        Text(
          waiting
              ? 'No rush. The soul will wait with you.'
              : both
                  ? 'You’re a little closer tonight.'
                  : '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SoulColors.celestialGold.withValues(alpha: 0.8),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: onDone,
          child: Text(
            both ? 'Back to your soul' : 'Stay close',
            style: TextStyle(
              color: SoulColors.warmIvory.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _Feeling extends StatelessWidget {
  const _Feeling({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? SoulColors.celestialGold.withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? SoulColors.celestialGold.withValues(alpha: 0.55)
                : SoulColors.mistyLavender.withValues(alpha: 0.28),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? SoulColors.warmIvory
                : SoulColors.mistyLavender.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SendNote extends StatelessWidget {
  const _SendNote({
    required this.enabled,
    required this.partnerName,
    required this.onPressed,
  });

  final bool enabled;
  final String partnerName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0D9A0), SoulColors.celestialGold],
            ),
          ),
          child: Text(
            'Leave this with $partnerName',
            style: SoulTypography.cta,
          ),
        ),
      ),
    );
  }
}

class _SoftNote extends StatelessWidget {
  const _SoftNote({required this.line, this.theirs = false});

  final String line;
  final bool theirs;

  @override
  Widget build(BuildContext context) {
    return Text(
      '“$line”',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: theirs
            ? SoulColors.celestialGold.withValues(alpha: 0.9)
            : SoulColors.warmIvory.withValues(alpha: 0.92),
        fontSize: 18,
        height: 1.45,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
