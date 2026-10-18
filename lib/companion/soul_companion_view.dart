import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cosmetic.dart';
import 'evolution.dart';
import 'soul_companion_painter.dart';
import 'soul_state.dart';

/// Code-drawn Cloud Friend with soft idle life and a gentle tap delight.
class SoulCompanionView extends StatefulWidget {
  const SoulCompanionView({
    super.key,
    required this.state,
    this.cosmetic = CompanionCosmetic.none,
    this.evolution = CompanionEvolution.spark,
    this.size = const Size(320, 360),
  });

  final SoulState state;
  final CompanionCosmetic cosmetic;
  final CompanionEvolution evolution;
  final Size size;

  @override
  State<SoulCompanionView> createState() => _SoulCompanionViewState();
}

class _SoulCompanionViewState extends State<SoulCompanionView>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _float;
  late final AnimationController _tail;
  late final AnimationController _sparkle;
  late final AnimationController _blink;
  late final AnimationController _celebrate;
  late final AnimationController _mood;
  late final AnimationController _look;
  late final AnimationController _earTwitch;
  late final AnimationController _react;
  late final AnimationController _tears;

  double _glow = 0.9;
  double _earDroop = 0;
  double _curl = 0;
  double _smile = 0.85;
  double _eyeOpenBias = 1.0;
  double _tearIntensity = 0;

  double _lookX = 0;
  double _lookY = 0;
  double _targetLookX = 0;
  double _targetLookY = 0;
  double _headTilt = 0;

  Timer? _blinkTimer;
  Timer? _lookTimer;
  Timer? _earTimer;
  final _rng = math.Random();

  bool _reduceMotion = false;
  bool _tapping = false;

  @override
  void initState() {
    super.initState();

    // Slow, unhurried breath — ease feels continuous when reversed.
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    // Independent float, slightly out of phase with breath.
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    );

    _tail = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );

    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _mood = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _look = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_tickLook);

    _earTwitch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // Soft tap arc — up and settle, no springy bounce.
    _react = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _tears = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );

    _applyMood(widget.state, animate: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      _configureMotion();
    } else if (!_breath.isAnimating && !_reduceMotion) {
      _configureMotion();
    }
  }

  void _configureMotion() {
    if (_reduceMotion) {
      _breath
        ..stop()
        ..value = 0.45;
      _float
        ..stop()
        ..value = 0.5;
      _tail.stop();
      _sparkle.stop();
      _blinkTimer?.cancel();
      _lookTimer?.cancel();
      _earTimer?.cancel();
      return;
    }

    if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
    if (!_float.isAnimating) {
      // Offset phase so float and breath don't peak together.
      _float.value = 0.35;
      _float.repeat(reverse: true);
    }
    if (!_tail.isAnimating) {
      _tail.repeat();
    }
    if (!_sparkle.isAnimating) {
      _sparkle.repeat();
    }
    _scheduleBlink();
    _scheduleLook();
    _scheduleEarTwitch();
  }

  void _tickLook() {
    final t = Curves.easeInOutCubic.transform(_look.value);
    setState(() {
      _lookX = _lookX + (_targetLookX - _lookX) * (0.12 + t * 0.88);
      _lookY = _lookY + (_targetLookY - _lookY) * (0.12 + t * 0.88);
      _headTilt = _lookX * 0.1;
    });
  }

  void _applyMood(SoulState state, {required bool animate}) {
    final g = state.glowStrength;
    final e = state.earDroop;
    final c = state.curl;
    final sm = state.smile;
    final eo = state.eyeOpenBias;
    final tears = state == SoulState.lonely ? 1.0 : 0.0;

    if (!animate) {
      setState(() {
        _glow = g;
        _earDroop = e;
        _curl = c;
        _smile = sm;
        _eyeOpenBias = eo;
        _tearIntensity = tears;
      });
    } else {
      final fg = _glow;
      final fe = _earDroop;
      final fc = _curl;
      final fs = _smile;
      final feo = _eyeOpenBias;
      void tick() {
        final t = Curves.easeInOutCubic.transform(_mood.value);
        setState(() {
          _glow = fg + (g - fg) * t;
          _earDroop = fe + (e - fe) * t;
          _curl = fc + (c - fc) * t;
          _smile = fs + (sm - fs) * t;
          _eyeOpenBias = feo + (eo - feo) * t;
        });
      }

      _mood
        ..removeListener(tick)
        ..stop()
        ..value = 0
        ..addListener(tick);
      _mood.forward().whenComplete(() => _mood.removeListener(tick));
    }

    _tearIntensity = tears;
    if (tears > 0 && !_reduceMotion) {
      if (!_tears.isAnimating) _tears.repeat();
    } else {
      _tears
        ..stop()
        ..value = 0;
    }

    _tail.duration = Duration(
      milliseconds: state == SoulState.lonely ? 3200 : 2400,
    );
    if (_tail.isAnimating && !_reduceMotion) {
      _tail
        ..stop()
        ..repeat();
    }

    if (state.celebrates && !_reduceMotion) {
      _celebrate.forward(from: 0);
    } else {
      _celebrate.value = 0;
    }
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    if (_reduceMotion) return;
    // Occasional, never frantic.
    final delay = Duration(milliseconds: 2200 + _rng.nextInt(3200));
    _blinkTimer = Timer(delay, () async {
      if (!mounted || _reduceMotion || _tapping) return;
      await _blink.forward(from: 0);
      if (!mounted) return;
      await _blink.reverse();
      // Rare soft double-blink
      if (_rng.nextDouble() < 0.22 && mounted && !_tapping) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!mounted || _tapping) return;
        await _blink.forward(from: 0);
        if (!mounted) return;
        await _blink.reverse();
      }
      if (mounted) _scheduleBlink();
    });
  }

  void _scheduleLook() {
    _lookTimer?.cancel();
    if (_reduceMotion) return;
    _lookTimer = Timer(Duration(milliseconds: 1800 + _rng.nextInt(2800)), () {
      if (!mounted || _reduceMotion || _tapping) return;
      if (widget.state == SoulState.lonely && _rng.nextDouble() < 0.5) {
        _targetLookX = _rng.nextBool() ? 0.55 : -0.55;
        _targetLookY = 0.12;
      } else if (_rng.nextDouble() < 0.4) {
        _targetLookX = 0;
        _targetLookY = 0;
      } else {
        _targetLookX = (_rng.nextDouble() - 0.5) * 0.9;
        _targetLookY = (_rng.nextDouble() - 0.5) * 0.45;
      }
      _look.forward(from: 0);
      _scheduleLook();
    });
  }

  void _scheduleEarTwitch() {
    _earTimer?.cancel();
    if (_reduceMotion) return;
    _earTimer = Timer(
      Duration(milliseconds: 2800 + _rng.nextInt(4500)),
      () async {
        if (!mounted || _reduceMotion || _tapping) return;
        await _earTwitch.forward(from: 0);
        if (!mounted) return;
        await _earTwitch.reverse();
        if (mounted) _scheduleEarTwitch();
      },
    );
  }

  Future<void> _onTap() async {
    if (_tapping) return;
    _tapping = true;
    HapticFeedback.selectionClick();

    // Meet the gaze, then a soft hop + blink.
    _targetLookX = 0;
    _targetLookY = -0.08;
    _look.forward(from: 0);

    if (_reduceMotion) {
      await _blink.forward(from: 0);
      if (mounted) await _blink.reverse();
      _tapping = false;
      if (mounted) _scheduleBlink();
      return;
    }

    // Soft hop: sin(π·t) rises and lands in one forward; no reverse hop.
    await _react.forward(from: 0);
    if (!mounted) return;
    await _blink.forward(from: 0);
    if (!mounted) return;
    await _blink.reverse();
    _tapping = false;
    if (mounted) _scheduleBlink();
  }

  @override
  void didUpdateWidget(covariant SoulCompanionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _applyMood(widget.state, animate: true);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _lookTimer?.cancel();
    _earTimer?.cancel();
    _breath.dispose();
    _float.dispose();
    _tail.dispose();
    _sparkle.dispose();
    _blink.dispose();
    _celebrate.dispose();
    _mood.dispose();
    _look.dispose();
    _earTwitch.dispose();
    _react.dispose();
    _tears.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breath,
          _float,
          _tail,
          _sparkle,
          _blink,
          _celebrate,
          _mood,
          _look,
          _earTwitch,
          _react,
          _tears,
        ]),
        builder: (context, _) {
          final breath = Curves.easeInOutSine.transform(_breath.value);
          final float = Curves.easeInOutSine.transform(_float.value);
          // Smooth arc for tap — rises and eases down via controller direction.
          final delight = Curves.easeInOutCubic.transform(_react.value);

          return CustomPaint(
            size: widget.size,
            painter: SoulCompanionPainter(
              breath: breath,
              float: float,
              delight: delight,
              blink: Curves.easeInOut.transform(_blink.value),
              lookX: _lookX,
              lookY: _lookY,
              earTwitch: Curves.easeOut.transform(_earTwitch.value),
              tailPhase: _tail.value,
              headTilt: _headTilt,
              glow: _glow,
              earDroop: _earDroop,
              curl: _curl,
              celebrate: _celebrate.value,
              sparklePhase: _sparkle.value,
              smile: _smile,
              eyeOpenBias: _eyeOpenBias,
              tearPhase: _tears.value,
              tearIntensity: _tearIntensity,
              cosmetic: widget.cosmetic,
              evolution: widget.evolution,
              lonely: widget.state == SoulState.lonely,
            ),
          );
        },
      ),
    );
  }
}
