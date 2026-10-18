import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/shared_soul_brand.dart';
import '../couple/couple_service.dart';
import '../theme/soul_colors.dart';
import '../theme/soul_typography.dart';
import 'bond_milestones.dart';
import 'cosmetic.dart';
import 'customize_companion_sheet.dart';
import 'debug_companion_panel.dart';
import 'evolution.dart';
import 'daily_ritual_screen.dart';
import 'love_goals_panel.dart';
import 'partner_outline.dart';
import 'soul_companion_view.dart';
import 'soul_state.dart';
import 'synced_companion_controller.dart';

/// Fixed-viewport home — companion + partners first, then bond + CTA.
///
/// [controller] must already be hydrated (see splash bootstrap).
class CompanionStageScreen extends StatefulWidget {
  const CompanionStageScreen({
    super.key,
    required this.coupleService,
    required this.controller,
    this.onLeftCouple,
  });

  final CoupleService coupleService;
  final SyncedCompanionController controller;
  final VoidCallback? onLeftCouple;

  @override
  State<CompanionStageScreen> createState() => _CompanionStageScreenState();
}

class _CompanionStageScreenState extends State<CompanionStageScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _starTwinkle;
  Timer? _dayPartTimer;

  SyncedCompanionController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _starTwinkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _dayPartTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _controller.ensureToday();
      unawaited(widget.coupleService.touchLastSeen());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.ensureToday();
      unawaited(widget.coupleService.touchLastSeen());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayPartTimer?.cancel();
    _starTwinkle.dispose();
    // Controller is owned by SoulAppRoot.
    super.dispose();
  }

  void _openRitual() {
    _controller.ensureToday();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: DailyRitualScreen(controller: _controller),
        ),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  void _openCustomize() {
    showCustomizeCompanionSheet(
      context: context,
      controller: _controller,
      onLeftCouple: widget.onLeftCouple,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final controller = _controller;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SoulColors.nightDeep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (reduceMotion)
              const _CelestialBackdrop(twinkle: 0)
            else
              AnimatedBuilder(
                animation: _starTwinkle,
                builder: (context, _) =>
                    _CelestialBackdrop(twinkle: _starTwinkle.value),
              ),
            SafeArea(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final state = controller.state;
                  final cosmetic = controller.cosmetic;
                  final evolution = controller.evolution;
                  final bond = BondProgress.fromDays(controller.wholeBondDays);
                  final goalsUnlocked = controller.loveGoalsUnlocked;
                  final waiting = controller.waitingOnPartner;
                  final cooling = controller.showCooldown;
                  final milestone = bond.nextMilestoneExplanation;
                  final memories = gatherMemories(
                    wholeDays: controller.wholeBondDays,
                    limit: 1,
                  );
                  final memoryLine =
                      memories.isEmpty ? null : memories.last.title;

                  final awaitingNext = controller.awaitingNextConnection;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      // Keep hero compact when cooldown + chores share the screen.
                      final bottomReserve = cooling
                          ? (goalsUnlocked ? 300.0 : 180.0)
                          : (awaitingNext ? 120.0 : 140.0);
                      final heroBudget =
                          (h - bottomReserve).clamp(120.0, h * 0.42);
                      final heroSide = math
                          .min(w * 0.62, heroBudget * 0.78)
                          .clamp(110.0, 200.0)
                          .toDouble();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            onCustomize: _openCustomize,
                            inviteCode: controller.couple.inviteCode,
                            debugButton: DebugCompanionButton(
                              controller: controller,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: _CompanionHero(
                                heroSide: heroSide,
                                state: state,
                                cosmetic: cosmetic,
                                evolution: evolution,
                                reduceMotion: reduceMotion,
                                bondLine: bond.togethernessLine,
                                milestoneLine: milestone,
                                memoryLine: memoryLine,
                                youLabel: controller.myDisplayName,
                                themLabel: controller.partnerDisplayName,
                                youPresent: controller.iAnsweredToday ||
                                    (cooling && goalsUnlocked),
                                themPresent: controller.partnerAnsweredToday ||
                                    (cooling && goalsUnlocked),
                              ),
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (cooling)
                                    _CooldownBanner(
                                      remaining: controller.cooldownRemaining,
                                    ),
                                  if (goalsUnlocked)
                                    LoveGoalsPanel(controller: controller)
                                  else if (awaitingNext)
                                    _CtaBar(
                                      label: 'Opening next check-in…',
                                      waiting: true,
                                      onPressed: null,
                                    )
                                  else if (!cooling)
                                    _CtaBar(
                                      label: waiting
                                          ? 'Waiting for ${controller.partnerDisplayName}…'
                                          : 'Leave a note for ${controller.partnerDisplayName}',
                                      waiting: waiting,
                                      onPressed: waiting ? null : _openRitual,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionHero extends StatelessWidget {
  const _CompanionHero({
    required this.heroSide,
    required this.state,
    required this.cosmetic,
    required this.evolution,
    required this.reduceMotion,
    required this.bondLine,
    required this.milestoneLine,
    required this.memoryLine,
    required this.youLabel,
    required this.themLabel,
    required this.youPresent,
    required this.themPresent,
  });

  final double heroSide;
  final SoulState state;
  final CompanionCosmetic cosmetic;
  final CompanionEvolution evolution;
  final bool reduceMotion;
  final String bondLine;
  final String? milestoneLine;
  final String? memoryLine;
  final String youLabel;
  final String themLabel;
  final bool youPresent;
  final bool themPresent;

  @override
  Widget build(BuildContext context) {
    final stageWide =
        math.min(heroSide * 1.15, MediaQuery.sizeOf(context).width - 40);
    final paintH = heroSide *
        (evolution == CompanionEvolution.ascendant ? 1.2 : 1.08);
    final symbolH = heroSide * 0.18;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        // Scale the stage down when the Expanded slot is short (cooldown + chores).
        final scale = maxH < 360 ? (maxH / 360).clamp(0.72, 1.0) : 1.0;
        final side = heroSide * scale;
        final wide = math.min(stageWide * scale, constraints.maxWidth);
        final painted = paintH * scale;
        final symbols = (symbolH * scale).clamp(22.0, symbolH);

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: constraints.maxWidth,
            height: maxH.isFinite ? maxH : null,
            child: Column(
              children: [
                const Spacer(flex: 1),
                SizedBox(
                  width: wide,
                  height: painted,
                  child: RepaintBoundary(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Container(
                          width: side * 1.05,
                          height: side * 0.95,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                SoulColors.celestialGold.withValues(alpha: 0.14),
                                SoulColors.mistyLavender.withValues(alpha: 0.04),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.42, 1.0],
                            ),
                          ),
                        ),
                        Semantics(
                          label:
                              'Cloud companion, ${evolution.label}, ${state.label}',
                          child: SoulCompanionView(
                            state: state,
                            cosmetic: cosmetic,
                            evolution: evolution,
                            size: Size(wide, painted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PartnerOutline(
                      isYou: true,
                      present: youPresent,
                      height: symbols,
                      label: youLabel,
                    ),
                    SizedBox(width: side * 0.14),
                    PartnerOutline(
                      isYou: false,
                      present: themPresent,
                      height: symbols,
                      label: themLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                  child: Text(
                    key: ValueKey(evolution.name),
                    evolution.displayTitle,
                    style: SoulTypography.evolutionTitle.copyWith(
                      fontSize: 18 * scale,
                      letterSpacing: 2.8,
                      color: SoulColors.warmIvory.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bondLine,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.celestialGold.withValues(alpha: 0.85),
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                if (milestoneLine != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    milestoneLine!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SoulColors.mistyLavender.withValues(alpha: 0.65),
                      fontSize: 11,
                    ),
                  ),
                ],
                if (memoryLine != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    memoryLine!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SoulColors.celestialGold.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const Spacer(flex: 1),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onCustomize,
    required this.debugButton,
    required this.inviteCode,
  });

  final VoidCallback onCustomize;
  final Widget debugButton;
  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
      child: Row(
        children: [
          SizedBox(width: 36, child: debugButton),
          Expanded(
            child: Column(
              children: [
                Text(
                  SharedSoulBrand.nameUpper,
                  textAlign: TextAlign.center,
                  style: SoulTypography.appTitle.copyWith(fontSize: 12),
                ),
                Text(
                  inviteCode,
                  style: TextStyle(
                    color: SoulColors.mistyLavender.withValues(alpha: 0.45),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 36,
            child: IconButton(
              tooltip: 'Customize companion',
              onPressed: onCustomize,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.auto_awesome_outlined,
                color: SoulColors.celestialGold.withValues(alpha: 0.85),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CooldownBanner extends StatelessWidget {
  const _CooldownBanner({required this.remaining});

  final Duration remaining;

  String _format(Duration d) {
    final total = d.inSeconds.clamp(0, 99 * 3600);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
    return '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: SoulColors.celestialGold.withValues(alpha: 0.35),
          ),
          color: SoulColors.night.withValues(alpha: 0.55),
        ),
        child: Column(
          children: [
            Text(
              'Come back after 4 hours',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SoulColors.mistyLavender.withValues(alpha: 0.75),
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _format(remaining),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SoulColors.celestialGold,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You’re connected — rest a little.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SoulColors.warmIvory.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtaBar extends StatelessWidget {
  const _CtaBar({
    required this.label,
    required this.onPressed,
    this.waiting = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: waiting
          ? _WaitingCta(label: label)
          : _PrimaryCta(label: label, onPressed: onPressed!),
    );
  }
}

class _WaitingCta extends StatelessWidget {
  const _WaitingCta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SoulColors.mistyLavender.withValues(alpha: 0.35),
        ),
        color: SoulColors.night.withValues(alpha: 0.45),
      ),
      child: Text(
        label,
        style: SoulTypography.cta.copyWith(
          color: SoulColors.mistyLavender.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatefulWidget {
  const _PrimaryCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<_PrimaryCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: double.infinity,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0D9A0), SoulColors.celestialGold],
              ),
              boxShadow: [
                BoxShadow(
                  color: SoulColors.celestialGold.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(widget.label, style: SoulTypography.cta),
          ),
        ),
      ),
    );
  }
}

class _CelestialBackdrop extends StatelessWidget {
  const _CelestialBackdrop({required this.twinkle});

  final double twinkle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A2A42),
                SoulColors.nightDeep,
                Color(0xFF121C2C),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        CustomPaint(painter: _StarFieldPainter(phase: twinkle)),
      ],
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (var i = 0; i < 48; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.7;
      final r = 0.4 + rng.nextDouble() * 1.2;
      final tw =
          0.25 + 0.75 * ((math.sin(phase * math.pi * 2 + i * 0.7) + 1) / 2);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = SoulColors.warmIvory.withValues(alpha: 0.12 + 0.28 * tw),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      phase != oldDelegate.phase;
}
