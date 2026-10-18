import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../brand/shared_soul_brand.dart';
import '../couple/couple_models.dart';
import '../couple/couple_service.dart';
import '../theme/soul_colors.dart';
import '../theme/soul_typography.dart';

/// Holds the creator until their partner joins with the invite code.
class WaitingLobbyScreen extends StatefulWidget {
  const WaitingLobbyScreen({
    super.key,
    required this.coupleService,
    required this.initialCouple,
    required this.onPartnerJoined,
    this.onLeftCouple,
  });

  final CoupleService coupleService;
  final Couple initialCouple;
  final VoidCallback onPartnerJoined;
  final VoidCallback? onLeftCouple;

  @override
  State<WaitingLobbyScreen> createState() => _WaitingLobbyScreenState();
}

class _WaitingLobbyScreenState extends State<WaitingLobbyScreen> {
  StreamSubscription<Couple?>? _sub;
  late Couple _couple;
  bool _copied = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _couple = widget.initialCouple;
    if (_couple.isFull) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPartnerJoined();
      });
      return;
    }
    _sub = widget.coupleService.watchCouple(_couple.id).listen((c) {
      if (c == null || !mounted) return;
      setState(() => _couple = c);
      if (c.isFull) {
        HapticFeedback.mediumImpact();
        widget.onPartnerJoined();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _couple.inviteCode));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied')),
    );
  }

  Future<void> _shareCode() async {
    final code = _couple.inviteCode;
    await SharePlus.instance.share(
      ShareParams(
        text: 'Join me on Shared Soul. Invite code: $code',
        subject: 'Shared Soul invite',
      ),
    );
  }

  Future<void> _leave() async {
    setState(() => _leaving = true);
    try {
      await widget.coupleService.leaveCouple();
      if (!mounted) return;
      widget.onLeftCouple?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _leaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t leave. Try again.')),
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
                const Spacer(flex: 2),
                Text(
                  'Waiting for them',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.warmIvory.withValues(alpha: 0.95),
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Share this code. Your soul stays here until they join.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.mistyLavender.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  _couple.inviteCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SoulColors.celestialGold,
                    fontSize: 40,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _shareCode,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF0D9A0), SoulColors.celestialGold],
                      ),
                    ),
                    child: Text('Share invite', style: SoulTypography.cta),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _copyCode,
                  child: Text(
                    _copied ? 'Copied' : 'Copy code',
                    style: const TextStyle(color: SoulColors.celestialGold),
                  ),
                ),
                const Spacer(flex: 3),
                Text(
                  'This screen updates when they join.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.mistyLavender.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: _leaving ? null : _leave,
                  child: Text(
                    _leaving ? 'Leaving…' : 'Cancel and leave',
                    style: TextStyle(
                      color: SoulColors.mistyLavender.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
