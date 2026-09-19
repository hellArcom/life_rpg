import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';
import '../widgets/character_preview.dart';

class CharacterCustomizationScreen extends ConsumerWidget {
  const CharacterCustomizationScreen({super.key});

  static const _categoryTabs = ['skin', 'hair', 'eyes', 'brow', 'mouth', 'outfit', 'hat', 'acc'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final user = ref.watch(gameProvider).user;
    final notifier = ref.read(gameProvider.notifier);

    return DefaultTabController(
      length: _categoryTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.customize),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _categoryTabs.map((cat) => Tab(text: _catLabel(cat, t))).toList(),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 24),
            CharacterPreview(parts: user.characterParts, size: 140),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                children: _categoryTabs.map((cat) {
                  final parts = UserProfile.allParts.where((p) => p.category == cat).toList();
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: parts.length,
                      itemBuilder: (context, index) {
                        final part = parts[index];
                        final isUnlocked = user.hasPart(part.id);
                        final isSelected = user.partId(cat) == part.id;
                        final canUnlock = user.canUnlockPart(part.id);

                        return GestureDetector(
                          onTap: isUnlocked && !isSelected
                              ? () => notifier.selectCharacterPart(part.id)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.amber.withValues(alpha: 0.15)
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.amber
                                    : isUnlocked
                                        ? Colors.white24
                                        : Colors.white10,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: _partIcon(context, part, isUnlocked),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      part.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isUnlocked ? Colors.white : Colors.white38,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          t.equipped,
                                          style: const TextStyle(fontSize: 9, color: Colors.amber),
                                        ),
                                      )
                                    else if (isUnlocked)
                                      Text(
                                        t.equip,
                                        style: const TextStyle(fontSize: 10, color: Colors.cyan),
                                      )
                                    else if (part.cost > 0)
                                      Text(
                                        '${part.cost} 🪙',
                                        style: const TextStyle(fontSize: 9, color: Colors.amber),
                                      )
                                    else
                                      Text(
                                        '${t.levelRequired} ${part.unlockLevel}',
                                        style: const TextStyle(fontSize: 9, color: Colors.white38),
                                      ),
                                  ],
                                ),
                                if (!isUnlocked)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(
                                      canUnlock ? Icons.lock_open : Icons.lock,
                                      size: 16,
                                      color: canUnlock ? Colors.amber : Colors.white24,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _catLabel(String cat, Translations t) {
    switch (cat) {
      case 'skin': return t.skinCategory;
      case 'hair': return t.hairCategory;
      case 'eyes': return t.eyesCategory;
      case 'brow': return t.browCategory;
      case 'mouth': return t.mouthCategory;
      case 'outfit': return t.outfitCategory;
      case 'hat': return t.hatCategory;
      case 'acc': return t.accCategory;
      default: return cat;
    }
  }

  Widget _partIcon(BuildContext context, CharacterPartDefinition part, bool isUnlocked) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.3,
      child: Image.asset(
        part.assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        width: 48,
        height: 48,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.help_outline,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
