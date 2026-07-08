import 'dart:math';
import 'package:flutter/material.dart';

class XPBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final xpForCurrentLevel = pow(level - 1, 2).toInt() * 100;
    final xpForNextLevel = pow(level, 2).toInt() * 100;
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
            Text('$currentXp / $xpForNextLevel XP'),
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
