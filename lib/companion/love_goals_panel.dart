import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/soul_colors.dart';
import '../theme/soul_typography.dart';
import 'love_goal.dart';
import 'synced_companion_controller.dart';

/// Inline real-task list for home — three ideas for this connection.
class LoveGoalsPanel extends StatelessWidget {
  const LoveGoalsPanel({super.key, required this.controller});

  final SyncedCompanionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final goals = controller.todaysLoveGoals;
        final done = controller.loveGoalsDoneCount;
        final total = controller.loveGoalsTotal;
        final roundDone = controller.allLoveGoalsDone;
        final partnerDone = controller.partnerLoveGoalsDoneCount;
        final partner = controller.partnerDisplayName;
        final cooling = controller.showCooldown;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                roundDone
                    ? 'That’s enough for now.'
                    : controller.togetherWindowLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SoulColors.celestialGold.withValues(alpha: 0.85),
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                roundDone
                    ? (cooling
                        ? 'Rest together — a new check-in opens when the timer ends.'
                        : 'You’re ready for another check-in.')
                    : '$done of $total for you · $partnerDone of $total for $partner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SoulColors.mistyLavender.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              if (!roundDone)
                for (final goal in goals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _GoalTile(
                      goal: goal,
                      mineDone: controller.isLoveGoalDone(goal.id),
                      partnerDone: controller.isPartnerLoveGoalDone(goal.id),
                      partnerLabel: partner,
                      onTap: () => runLoveGoal(context, controller, goal),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> runLoveGoal(
  BuildContext context,
  SyncedCompanionController controller,
  LoveGoal goal,
) async {
  if (controller.isLoveGoalDone(goal.id)) return;

  final ok = await _confirmDidIt(context, goal);
  if (!ok || !context.mounted) return;
  HapticFeedback.lightImpact();
  try {
    await controller.completeRealGoal(goal.id);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Couldn’t save that. Try again.')),
    );
  }
}

Future<bool> _confirmDidIt(BuildContext context, LoveGoal goal) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: SoulColors.night,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(goal.title, style: SoulTypography.cardTitle),
        content: Text(
          '${goal.detail}\n\nCheck this off only after you actually did it.',
          style: TextStyle(
            color: SoulColors.mistyLavender.withValues(alpha: 0.85),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Not yet',
              style: TextStyle(
                color: SoulColors.mistyLavender.withValues(alpha: 0.8),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'I did it',
              style: TextStyle(color: SoulColors.celestialGold),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.mineDone,
    required this.partnerDone,
    required this.partnerLabel,
    required this.onTap,
  });

  final LoveGoal goal;
  final bool mineDone;
  final bool partnerDone;
  final String partnerLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: mineDone
          ? SoulColors.celestialGold.withValues(alpha: 0.1)
          : SoulColors.night.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: mineDone ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Icon(
                mineDone ? Icons.check_circle : Icons.circle_outlined,
                color: mineDone
                    ? SoulColors.celestialGold
                    : SoulColors.mistyLavender.withValues(alpha: 0.55),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        color: SoulColors.warmIvory.withValues(
                          alpha: mineDone ? 0.6 : 0.95,
                        ),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: mineDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goal.detail,
                      style: TextStyle(
                        color: SoulColors.mistyLavender.withValues(alpha: 0.65),
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                    if (partnerDone) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$partnerLabel did this too',
                        style: TextStyle(
                          color: SoulColors.celestialGold.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
