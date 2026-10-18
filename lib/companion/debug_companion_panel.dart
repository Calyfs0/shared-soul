import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/soul_colors.dart';
import 'cosmetic.dart';
import 'evolution.dart';
import 'soul_state.dart';
import 'synced_companion_controller.dart';

/// Developer-only controls. Never shown in release builds.
class DebugCompanionButton extends StatelessWidget {
  const DebugCompanionButton({super.key, required this.controller});

  final SyncedCompanionController controller;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return IconButton(
      tooltip: 'Developer controls',
      onPressed: () => showDebugCompanionPanel(context, controller),
      icon: Icon(
        Icons.bug_report_outlined,
        color: SoulColors.mistyLavender.withValues(alpha: 0.45),
        size: 20,
      ),
    );
  }
}

Future<void> showDebugCompanionPanel(
  BuildContext context,
  SyncedCompanionController controller,
) {
  assert(kDebugMode);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: SoulColors.night,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer controls',
                      style: TextStyle(
                        color: SoulColors.warmIvory.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Couple ${controller.couple.inviteCode} · synced via Supabase',
                      style: TextStyle(
                        color: SoulColors.mistyLavender.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: controller.couple.inviteCode),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy invite code'),
                      style: TextButton.styleFrom(
                        foregroundColor: SoulColors.celestialGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _section('Relationship state'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in SoulState.values)
                          _chip(
                            s.label,
                            s == controller.state,
                            () => controller.setState(s),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _section('Evolution preview'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in CompanionEvolution.values)
                          _chip(
                            '${e.label} (${e.requiredWholeDays}d)',
                            e == controller.evolution,
                            () => controller.previewEvolution(e),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _section('Daily ritual (live)'),
                    Text(
                      controller.bothAnsweredToday
                          ? 'Both answered today'
                          : controller.iAnsweredToday
                              ? 'You answered — waiting on them'
                              : 'Neither answered yet',
                      style: TextStyle(
                        color: SoulColors.mistyLavender.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _section('Bond days (local preview)'),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => controller.setWholeBondDays(
                            controller.wholeBondDays - 1,
                          ),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: SoulColors.mistyLavender,
                          ),
                        ),
                        Text(
                          '${controller.wholeBondDays}',
                          style: const TextStyle(
                            color: SoulColors.celestialGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          onPressed: () => controller.setWholeBondDays(
                            controller.wholeBondDays + 1,
                          ),
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: SoulColors.mistyLavender,
                          ),
                        ),
                        TextButton(
                          onPressed: controller.clearEvolutionPreview,
                          child: const Text('Clear override'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _section('Accessories'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in CompanionCosmetic.values)
                          _chip(
                            c.label,
                            c == controller.cosmetic,
                            () => controller.setCosmetic(c),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _section(String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: TextStyle(
        color: SoulColors.mistyLavender.withValues(alpha: 0.65),
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

Widget _chip(String label, bool selected, VoidCallback onTap) {
  return Material(
    color: selected ? SoulColors.chipActive : SoulColors.chipIdle,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? SoulColors.warmIvory : SoulColors.textSoft,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}
