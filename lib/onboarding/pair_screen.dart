import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/shared_soul_brand.dart';
import '../theme/soul_colors.dart';
import '../theme/soul_typography.dart';
import '../couple/couple_service.dart';

/// Create or join a couple with a short invite code.
class PairScreen extends StatefulWidget {
  const PairScreen({
    super.key,
    required this.coupleService,
    required this.onPaired,
  });

  final CoupleService coupleService;
  final VoidCallback onPaired;

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final offset = DateTime.now().timeZoneOffset.inMinutes;
      await widget.coupleService.createCouple(
        displayName: _name.text.trim().isEmpty ? 'You' : _name.text.trim(),
        timezoneOffsetMinutes: offset,
      );
      HapticFeedback.lightImpact();
      // Waiting lobby — never open home alone.
      widget.onPaired();
    } catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.coupleService.joinCouple(
        inviteCode: _code.text.trim(),
        displayName: _name.text.trim().isEmpty ? 'You' : _name.text.trim(),
      );
      HapticFeedback.lightImpact();
      widget.onPaired();
    } catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('Already in a couple')) return 'You’re already paired.';
    if (s.contains('both partners are active')) {
      return 'Your partner is still connected on another device. Wait half a minute, then try the code again.';
    }
    if (s.contains('Invalid or full')) {
      return 'That code isn’t valid.';
    }
    if (s.contains('Not authenticated')) {
      return 'Sign-in failed. Check Anonymous Auth is enabled.';
    }
    return 'Something went wrong. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SoulColors.nightDeep,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  SharedSoulBrand.nameUpper,
                  textAlign: TextAlign.center,
                  style: SoulTypography.appTitle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with your love',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.warmIvory.withValues(alpha: 0.95),
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a code or join.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.mistyLavender.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your shared day follows the creator’s timezone. Reinstalled? Enter the same invite code to reconnect.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.mistyLavender.withValues(alpha: 0.5),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _name,
                  style: const TextStyle(color: SoulColors.warmIvory),
                  cursorColor: SoulColors.celestialGold,
                  decoration: _fieldDecoration('Your name'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _code,
                  style: const TextStyle(
                    color: SoulColors.warmIvory,
                    letterSpacing: 4,
                  ),
                  cursorColor: SoulColors.celestialGold,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: _fieldDecoration('Invite code'),
                  onChanged: (_) => setState(() {}),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13),
                  ),
                ],
                const Spacer(),
                if (_busy)
                  const Center(
                    child: CircularProgressIndicator(
                      color: SoulColors.celestialGold,
                    ),
                  )
                else ...[
                  _GoldButton(label: 'Create a code', onPressed: _create),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _code.text.trim().length >= 4 ? _join : null,
                    child: Text(
                      'Join',
                      style: TextStyle(
                        color: SoulColors.warmIvory.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: SoulColors.mistyLavender.withValues(alpha: 0.4),
      ),
      counterText: '',
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: SoulColors.mistyLavender.withValues(alpha: 0.25),
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: SoulColors.celestialGold),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFF0D9A0), SoulColors.celestialGold],
          ),
        ),
        child: Text(label, style: SoulTypography.cta),
      ),
    );
  }
}
