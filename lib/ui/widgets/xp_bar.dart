import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';
import '../../providers/game_provider.dart';

class XPBar extends ConsumerWidget {
  final int currentXp;
  final int level;
  final String label;

  const XPBar({
    super.key,
    required this.currentXp,
    required this.level,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final xpForCurrentLevel = xpForLevel(level);
    final xpForNextLevel = xpForLevel(level + 1);
    final xpInRange = currentXp - xpForCurrentLevel;
    final totalInRange = xpForNextLevel - xpForCurrentLevel;
    final progress = (xpInRange / totalInRange).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text('$currentXp / $xpForNextLevel ${t.xpShort}'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
