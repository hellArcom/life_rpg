import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  bool _alreadyOwned(ShopItem item, UserProfile user) {
    if (item.type == 'character_part' && item.value != null) {
      return user.unlockedCharacterParts.contains(item.value);
    }
    if (item.type == 'title' && item.value != null) {
      return user.badgeIds.contains('title_${item.value}');
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final gameState = ref.watch(gameProvider);
    final shopItems = gameState.shopItems;
    final user = gameState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.shop),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('💰', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text('${user.coins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shopItems.length,
        itemBuilder: (context, index) {
          final item = shopItems[index];
          final owned = _alreadyOwned(item, user);
          final canAfford = user.coins >= item.cost;
          return Card(
            key: ValueKey(item.id),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Text(item.icon, style: const TextStyle(fontSize: 32)),
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.description),
              trailing: owned
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text('Possédé ✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  : ElevatedButton(
                      onPressed: canAfford
                          ? () {
                              final success = ref.read(gameProvider.notifier).buyItem(item.id);
                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pas assez de pièces !')),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? Colors.amber : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text('${item.cost}'),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
