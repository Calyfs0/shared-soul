import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/shared_soul_brand.dart';
import '../brand/starlit_mark.dart';
import '../theme/soul_colors.dart';
import '../theme/soul_typography.dart';

/// Branded hold screen while auth + couple + day hydrate.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SoulColors.nightDeep,
        body: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = reduceMotion ? 1.0 : _pulse.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StarlitMark(size: 132, starPulse: t),
                    const SizedBox(height: 28),
                    Text(
                      SharedSoulBrand.nameUpper,
                      style: SoulTypography.appTitle.copyWith(
                        fontSize: 16,
                        letterSpacing: 4.2,
                        color: SoulColors.warmIvory.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      SharedSoulBrand.tagline,
                      style: TextStyle(
                        color: SoulColors.mistyLavender.withValues(
                          alpha: 0.55 + 0.2 * t,
                        ),
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
