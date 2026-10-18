import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth_service.dart';
import '../brand/shared_soul_brand.dart';
import '../companion/companion_stage_screen.dart';
import '../companion/synced_companion_controller.dart';
import '../couple/couple_models.dart';
import '../couple/couple_service.dart';
import '../onboarding/pair_screen.dart';
import '../onboarding/waiting_lobby_screen.dart';
import '../theme/soul_colors.dart';
import 'splash_screen.dart';

/// Auth + hydrate under splash → pair / lobby / home.
class SoulAppRoot extends StatefulWidget {
  const SoulAppRoot({super.key});

  @override
  State<SoulAppRoot> createState() => _SoulAppRootState();
}

class _SoulAppRootState extends State<SoulAppRoot> {
  final _auth = AuthService();
  final _couples = CoupleService();

  bool _loading = true;
  String? _error;
  Couple? _couple;
  SyncedCompanionController? _homeController;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _homeController?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.ensureSignedIn();
      await _couples.touchLastSeen();
      final couple = await _couples.fetchMyCouple();
      SyncedCompanionController? home;
      if (couple != null && couple.isFull) {
        home = await SyncedCompanionController.create(
          coupleService: _couples,
          initialCouple: couple,
          onCoupleIncomplete: _onCoupleIncomplete,
        );
      }
      if (!mounted) {
        home?.dispose();
        return;
      }
      _homeController?.dispose();
      setState(() {
        _couple = couple;
        _homeController = home;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _afterPairFlow() async {
    setState(() => _loading = true);
    try {
      final couple = await _couples.fetchMyCouple();
      SyncedCompanionController? home;
      if (couple != null && couple.isFull) {
        home = await SyncedCompanionController.create(
          coupleService: _couples,
          initialCouple: couple,
          onCoupleIncomplete: _onCoupleIncomplete,
        );
      }
      if (!mounted) {
        home?.dispose();
        return;
      }
      _homeController?.dispose();
      setState(() {
        _couple = couple;
        _homeController = home;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SplashScreen();
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: SoulColors.nightDeep,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Couldn’t connect',
                  style: TextStyle(
                    color: SoulColors.warmIvory.withValues(alpha: 0.95),
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.mistyLavender.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.mistyLavender.withValues(alpha: 0.45),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _bootstrap,
                  child: const Text(
                    'Try again',
                    style: TextStyle(color: SoulColors.celestialGold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final couple = _couple;
    if (couple == null) {
      return PairScreen(
        coupleService: _couples,
        onPaired: _afterPairFlow,
      );
    }

    if (!couple.isFull) {
      return WaitingLobbyScreen(
        coupleService: _couples,
        initialCouple: couple,
        onPartnerJoined: _afterPairFlow,
        onLeftCouple: _afterLeaveCouple,
      );
    }

    final home = _homeController;
    if (home == null) {
      return const SplashScreen();
    }

    return CompanionStageScreen(
      coupleService: _couples,
      controller: home,
      onLeftCouple: _afterLeaveCouple,
    );
  }

  Future<void> _afterLeaveCouple() async {
    _homeController?.dispose();
    _homeController = null;
    if (!mounted) return;
    setState(() {
      _couple = null;
      _loading = false;
    });
  }

  /// Partner left (or seat emptied) — keep invite lobby so they can wait or leave.
  Future<void> _onCoupleIncomplete() async {
    _homeController?.dispose();
    _homeController = null;
    Couple? couple;
    try {
      couple = await _couples.fetchMyCouple();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _couple = couple;
      _loading = false;
    });
  }
}

class SharedSoulApp extends StatelessWidget {
  const SharedSoulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: SharedSoulBrand.name,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SoulColors.nightDeep,
        colorScheme: const ColorScheme.dark(
          primary: SoulColors.celestialGold,
          secondary: SoulColors.mistyLavender,
          surface: SoulColors.night,
          onPrimary: SoulColors.nightDeep,
          onSurface: SoulColors.textPrimary,
        ),
        useMaterial3: true,
      ),
      home: const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SoulAppRoot(),
      ),
    );
  }
}
