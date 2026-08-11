import 'package:flutter/material.dart';
import '../../models/game_models.dart';

/// Renders the player character by compositing the selected part sprites
/// (assets/characters/`<id>.png`, laid out like a sprite sheet) in draw order,
/// with a subtle idle breathing animation.
class CharacterPreview extends StatefulWidget {
  final Map<String, String> parts;
  final double size;

  const CharacterPreview({super.key, required this.parts, this.size = 120});

  @override
  State<CharacterPreview> createState() => _CharacterPreviewState();
}

class _CharacterPreviewState extends State<CharacterPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;

  // Draw order (bottom → top), matching the brush order of the original
  // renderer: outfit (body) → face(skin) → hair → eyes → brow → mouth → hat → acc.
  static const List<String> _order = [
    'outfit', 'skin', 'hair', 'eyes', 'brow', 'mouth', 'hat', 'acc',
  ];

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  String _part(String category) {
    final id = widget.parts[category];
    if (id != null && UserProfile.allParts.any((p) => p.id == id)) return id;
    return UserProfile.allParts
        .firstWhere((p) => p.category == category,
            orElse: () => UserProfile.allParts.first)
        .id;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _breathe,
        builder: (context, _) {
          // Gentle up/down breathing (+ scale) so the sprite feels alive.
          final t = _breathe.value;
          final dy = -t * widget.size * 0.015;
          final scale = 1.0 + (t - 0.5) * 0.02;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: _StackedLayers(
              parts: widget.parts,
              size: widget.size,
              order: _order,
              partOf: _part,
            )),
          );
        },
      ),
    );
  }
}

class _StackedLayers extends StatelessWidget {
  final Map<String, String> parts;
  final double size;
  final List<String> order;
  final String Function(String) partOf;

  const _StackedLayers({
    required this.parts,
    required this.size,
    required this.order,
    required this.partOf,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: order.map((cat) {
        final id = partOf(cat);
        final asset = 'assets/characters/$id.png';
        return Positioned.fill(
          child: IgnorePointer(
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        );
      }).toList(),
    );
  }
}