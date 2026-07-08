import 'package:flutter/material.dart';
import '../../models/game_models.dart';

// Sprite pixel format (12 wide, 1 padding each side → centered in 16 cells):
//  .    = transparent
//  1    = color1
//  2    = color2
//  k    = black
//  w    = white
//  r    = red

class _SpriteData {
  final List<String> rows;
  final int yo;
  const _SpriteData(this.rows, this.yo);
}

Color _c(String ch, Color c1, Color c2) => switch (ch) {
  '1' => c1, '2' => c2,
  'k' => const Color(0xFF1A1A2E),
  'w' => Colors.white,
  'r' => const Color(0xFFE74C3C),
  _ => Colors.transparent,
};

const _spriteData = <String, _SpriteData>{
  // ─── FACE (skin, 13 rows) ──────────────────────
  'face': _SpriteData([
    '....1111....',
    '...111111...',
    '..11111111..',
    '.1111..1111.',
    '.1111..1111.',
    '.1111111111.',
    '.1111111111.',
    '.1111..1111.',
    '.1111111111.',
    '..11111111..',
    '...111111...',
    '....1111....',
    '.....11.....',
  ], 0),

  // ─── HAIR (10 rows) ─────────────────────────────
  'hair_0': _SpriteData([
    '............','............','............',
    '............','............','............',
    '............','............','............','............',
  ], 0),

  'hair_1': _SpriteData([
    '....1111....',
    '...111111...',
    '..11111111..',
    '.111....111.',
    '.111....111.',
    '.11......11.',
    '.11......11.',
    '..11....11..',
    '...1....1...',
    '....1..1....',
  ], 0),

  'hair_2': _SpriteData([
    '....1111....',
    '...111111...',
    '..11111111..',
    '.1111..1111.',
    '.1111..1111.',
    '.111....111.',
    '.111....111.',
    '.111....111.',
    '..111..111..',
    '...1....1...',
  ], 0),

  'hair_3': _SpriteData([
    '..11111111..',
    '.1111111111.',
    '111111111111',
    '1111....1111',
    '1111....1111',
    '1111....1111',
    '.111....111.',
    '.111....111.',
    '..11....11..',
    '...1....1...',
  ], 0),

  'hair_4': _SpriteData([
    '....1111....',
    '...111111...',
    '..11111111..',
    '.111....111.',
    '.111....111.',
    '.11......11.',
    '.11......11.',
    '..11....11..',
    '..1......1..',
    '............',
  ], 0),

  'hair_5': _SpriteData([
    '...111111...',
    '..11111111..',
    '.1111111111.',
    '.1111..1111.',
    '.1111..1111.',
    '.111....111.',
    '.111....111.',
    '..111..111..',
    '...1....1...',
    '....1..1....',
  ], 0),

  // ─── EYES (3 rows, yo=3) ───────────────────────
  'eyes_1': _SpriteData([
    '....ww..ww..',
    '....kk..kk..',
    '............',
  ], 3),

  'eyes_2': _SpriteData([
    '....ww..ww..',
    '....kk..kk..',
    '............',
  ], 3),

  'eyes_3': _SpriteData([
    '...www.www..',
    '..kkkk.kkkk.',
    '............',
  ], 3),

  'eyes_4': _SpriteData([
    '....kk..kk..',
    '............',
    '............',
  ], 3),

  // ─── MOUTH (2 rows, yo=7) ──────────────────────
  'mouth_1': _SpriteData([
    '.....rr.....',
    '....rrrr....',
  ], 7),

  'mouth_2': _SpriteData([
    '...rrrrrr...',
    '...rrrrrr...',
  ], 7),

  'mouth_3': _SpriteData([
    '...rrrrrr...',
    '............',
  ], 7),

  'mouth_4': _SpriteData([
    '..rrrrrrrr..',
    '..r......r..',
  ], 7),

  // ─── OUTFIT (9 rows, yo=9) ─────────────────────
  'outfit_1': _SpriteData([
    '....1111....',
    '...111111...',
    '...111111...',
    '..11111111..',
    '..11222211..',
    '..11....11..',
    '.111....111.',
    '.111....111.',
    '.111....111.',
  ], 9),

  'outfit_2': _SpriteData([
    '....1111....',
    '...111111...',
    '..11111111..',
    '..11111111..',
    '.1111221111.',
    '.1111..1111.',
    '.1111..1111.',
    '11111..11111',
    '11111..11111',
  ], 9),

  'outfit_3': _SpriteData([
    '....1111....',
    '...111111...',
    '..11111111..',
    '..11111111..',
    '.1111221111.',
    '.11......11.',
    '111......111',
    '111......111',
    '111......111',
  ], 9),

  'outfit_4': _SpriteData([
    '....1111....',
    '...111111...',
    '...111111...',
    '..11111111..',
    '..11222211..',
    '..11....11..',
    '.111....111.',
    '.111....111.',
    '..11....11..',
  ], 9),

  'outfit_5': _SpriteData([
    '....1111....',
    '...111111...',
    '...111111...',
    '..11111111..',
    '.1111111111.',
    '.1122222211.',
    '.1111..1111.',
    '11111..11111',
    '111......111',
  ], 9),

  // ─── HAT (6 rows, yo=0) ────────────────────────
  'hat_0': _SpriteData([
    '............','............','............',
    '............','............','............',
  ], 0),

  'hat_1': _SpriteData([
    '...111111...',
    '..11111111..',
    '.1111111111.',
    '.1111111111.',
    '.1111111111.',
    '..11111111..',
  ], 0),

  'hat_2': _SpriteData([
    '....1111....',
    '...111111...',
    '..11111111..',
    '.1111111111.',
    '.1111111111.',
    '..11111111..',
  ], 0),

  'hat_3': _SpriteData([
    '..11.11.11..',
    '.1.1.1.1.1.1',
    '.1.1.1.1.1.1',
    '111111111111',
    '.1111111111.',
    '..11111111..',
  ], 0),

  // ─── ACCESSORY (3 rows) ────────────────────────
  'acc_0': _SpriteData([
    '............','............','............',
  ], 3),

  'acc_1': _SpriteData([
    '.1111..1111.',
    '.1111..1111.',
    '............',
  ], 3),

  'acc_2': _SpriteData([
    '..11111111..',
    '.1122112211.',
    '.1111111111.',
  ], 4),

  'acc_3': _SpriteData([
    '1..1.1.1..1.',
    '1..1.1.1..1.',
    '............',
  ], 2),
};

class CharacterPreview extends StatelessWidget {
  final Map<String, String> parts;
  final double size;

  const CharacterPreview({super.key, required this.parts, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _P(parts), size: Size(size, size)),
    );
  }
}

class _P extends CustomPainter {
  final Map<String, String> parts;
  _P(this.parts);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 16;
    final x0 = cell * 2;

    Color c1(String id) => UserProfile.allParts.where((p) => p.id == id).firstOrNull?.color1 ?? const Color(0xFFFFE0BD);
    Color c2(String id) => UserProfile.allParts.where((p) => p.id == id).firstOrNull?.color2 ?? const Color(0xFFD4A574);

    void dr(String id, Color a, Color b) {
      final sp = _spriteData[id];
      if (sp == null) return;
      for (var r = 0; r < sp.rows.length; r++) {
        final line = sp.rows[r];
        for (var col = 0; col < line.length; col++) {
          final ch = line[col];
          if (ch == '.') continue;
          final color = _c(ch, a, b);
          if (color == Colors.transparent) continue;
          canvas.drawRect(Rect.fromLTWH(x0 + col * cell, cell * sp.yo + r * cell, cell, cell), Paint()..color = color);
        }
      }
    }

    final sk = parts['skin'] ?? 'skin_1';
    final ha = parts['hair'] ?? 'hair_0';
    final ey = parts['eyes'] ?? 'eyes_1';
    final mo = parts['mouth'] ?? 'mouth_1';
    final ot = parts['outfit'] ?? 'outfit_1';
    final ht = parts['hat'] ?? 'hat_0';
    final ac = parts['acc'] ?? 'acc_0';

    dr(ot, c1(ot), c2(ot));
    dr(ha, c1(ha), c2(ha));
    dr('face', c1(sk), c2(sk));
    dr(ey, c1(ey), c2(ey));
    dr(mo, c1(mo), c2(mo));
    dr(ht, c1(ht), c2(ht));
    dr(ac, c1(ac), c2(ac));
  }

  @override
  bool shouldRepaint(covariant _P old) => old.parts != parts;
}
