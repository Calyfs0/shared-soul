import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/soul_colors.dart';
import '../theme/soul_typography.dart';
import 'cosmetic.dart';
import 'soul_companion_view.dart';
import 'synced_companion_controller.dart';

/// Player-facing accessory customization (not a debug panel).
Future<void> showCustomizeCompanionSheet({
  required BuildContext context,
  required SyncedCompanionController controller,
  VoidCallback? onLeftCouple,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => CustomizeCompanionSheet(
      controller: controller,
      onLeftCouple: onLeftCouple,
    ),
  );
}

class CustomizeCompanionSheet extends StatefulWidget {
  const CustomizeCompanionSheet({
    super.key,
    required this.controller,
    this.onLeftCouple,
  });

  final SyncedCompanionController controller;
  final VoidCallback? onLeftCouple;

  @override
  State<CustomizeCompanionSheet> createState() =>
      _CustomizeCompanionSheetState();
}

class _CustomizeCompanionSheetState extends State<CustomizeCompanionSheet> {
  late final TextEditingController _name;
  bool _savingName = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.controller.myDisplayName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final next = _name.text.trim();
    if (next.isEmpty) return;
    setState(() => _savingName = true);
    try {
      await widget.controller.setMyDisplayName(next);
      if (!mounted) return;
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t save name')),
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SoulColors.night,
        title: Text('Leave this couple?', style: SoulTypography.cardTitle),
        content: Text(
          'You’ll need a new invite code to reconnect. Your partner keeps the couple.',
          style: TextStyle(
            color: SoulColors.mistyLavender.withValues(alpha: 0.85),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Stay',
              style: TextStyle(
                color: SoulColors.mistyLavender.withValues(alpha: 0.8),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Leave',
              style: TextStyle(color: Color(0xFFFF8A80)),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _leaving = true);
    try {
      await widget.controller.leaveCouple();
      if (!mounted) return;
      Navigator.pop(context);
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
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottom),
          decoration: BoxDecoration(
            color: SoulColors.night,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: SoulColors.cardBorder),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SoulColors.mistyLavender.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Dress your companion', style: SoulTypography.cardTitle),
                const SizedBox(height: 4),
                Text('Little touches you share.', style: SoulTypography.cardBody),
                const SizedBox(height: 16),
                SoulCompanionView(
                  state: widget.controller.state,
                  cosmetic: widget.controller.cosmetic,
                  evolution: widget.controller.evolution,
                  size: const Size(160, 175),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Your name', style: SoulTypography.sectionLabel),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _name,
                        style: const TextStyle(color: SoulColors.warmIvory),
                        cursorColor: SoulColors.celestialGold,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Name',
                          hintStyle: TextStyle(
                            color: SoulColors.mistyLavender.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: SoulColors.mistyLavender.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: SoulColors.celestialGold),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _savingName ? null : _saveName,
                      child: Text(
                        _savingName ? '…' : 'Save',
                        style: const TextStyle(color: SoulColors.celestialGold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Accessories', style: SoulTypography.sectionLabel),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in CompanionCosmetic.values)
                      _AccessoryChip(
                        label: item.label,
                        selected: item == widget.controller.cosmetic,
                        onTap: () => widget.controller.setCosmetic(item),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _leaving ? null : _leave,
                  child: Text(
                    _leaving ? 'Leaving…' : 'Leave couple',
                    style: TextStyle(
                      color: const Color(0xFFFF8A80).withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccessoryChip extends StatelessWidget {
  const _AccessoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SoulColors.celestialGold.withValues(alpha: 0.22)
          : SoulColors.chipIdle,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? SoulColors.celestialGold.withValues(alpha: 0.7)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? SoulColors.celestialGold : SoulColors.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
