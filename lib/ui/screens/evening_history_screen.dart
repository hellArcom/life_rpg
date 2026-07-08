import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';

class EveningHistoryScreen extends ConsumerWidget {
  const EveningHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final log = ref.watch(gameProvider).eveningLog;
    final sorted = List<EveningEntry>.from(log)..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: Text(t.eveningHistoryTitle)),
      body: sorted.isEmpty
          ? Center(child: Text(t.eveningHistoryEmpty, style: const TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final e = sorted[i];
                final dateStr = DateFormat.yMd( Localizations.localeOf(context).languageCode).format(e.date);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(e.mood, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            if (e.coinReward > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('+${e.coinReward}💰', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                              ),
                          ],
                        ),
                        if (e.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(e.text, style: const TextStyle(fontSize: 14, height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
