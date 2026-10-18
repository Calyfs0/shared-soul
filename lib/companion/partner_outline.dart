import 'package:flutter/material.dart';

import '../theme/soul_colors.dart';

/// You / them — lit when that partner answered today’s prompt.
class PartnerOutline extends StatelessWidget {
  const PartnerOutline({
    super.key,
    required this.isYou,
    required this.present,
    required this.height,
    this.label,
  });

  final bool isYou;
  final bool present;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final who = label?.trim().isNotEmpty == true
        ? label!.trim()
        : (isYou ? 'You' : 'Them');
    final symbol = isYou ? '✦' : '✧';
    final color = present
        ? SoulColors.celestialGold
        : SoulColors.mistyLavender.withValues(alpha: 0.35);

    return Semantics(
      label: present
          ? '$who answered today'
          : '$who hasn\'t answered yet',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: color,
              fontSize: height * 0.5,
              fontWeight: FontWeight.w300,
              height: 1,
              shadows: present
                  ? [
                      Shadow(
                        color: SoulColors.celestialGold.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Text(symbol),
          ),
          SizedBox(height: height * 0.12),
          Text(
            who,
            style: TextStyle(
              color: color.withValues(alpha: present ? 0.9 : 0.55),
              fontSize: (height * 0.22).clamp(9.0, 12.0),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
