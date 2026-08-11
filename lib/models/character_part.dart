/// A customizable character part, as listed in the JSON-driven catalog
/// (tool/character_catalog.json -> tool/sync_catalog.py).
enum CharacterCategory { skin, hair, eyes, brow, mouth, outfit, hat, acc }

class CharacterPart {
  const CharacterPart({
    required this.id,
    required this.category,
    required this.label,
    required this.unlockLevel,
    required this.cost,
  });

  final String id;
  final CharacterCategory category;
  final String label;
  final int unlockLevel;
  final int cost;

  String get assetPath => 'assets/characters/$id.png';
}