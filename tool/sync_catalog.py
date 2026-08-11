#!/usr/bin/env python3
"""Generates the hero 32x32 character sprites + the Dart catalog.

Single source of truth: tool/character_catalog.json.
  - re-writes assets/characters/<id>.png  (32x32 transparent PNGs, one per part)
  - writes a <eyes_id>_blink.png per eyes style
  - regenerates lib/models/character_catalog.g.dart (Dart part list)

Coordinate layout (heroic proportions, head ~1/3 of the 32px height):
  brow  y4..y5          eyes  y6..y7    mouth y10..y12
  face  y1..y11 (+neck y11..y12)        hair  y1..y8
  outfit y13..y31 (shoulders y13..y15, torso y16..y23, legs y24..y31)
Draw order (bottom -> top): outfit, skin, hair, eyes, brow, mouth, hat, acc
"""

import json
import os

from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(BASE)
OUT_DIR = os.path.join(ROOT, "assets", "characters")
MODEL_DIR = os.path.join(ROOT, "lib", "models")
K = 32


def rgb(hexstr):
    return (int(hexstr[1:3], 16), int(hexstr[3:5], 16), int(hexstr[5:7], 16), 255)


class Renderer:
    def __init__(self):
        self.px = [[(0, 0, 0, 0) for _ in range(K)] for _ in range(K)]

    def set(self, x, y, c):
        if 0 <= x < K and 0 <= y < K:
            self.px[y][x] = c

    def hline(self, y, x0, x1, c):
        if 0 <= y < K:
            for x in range(max(0, x0), min(K, x1 + 1)):
                self.px[y][x] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(max(0, y0), min(K, y1 + 1)):
            self.hline(y, x0, x1, c)

    def export(self, path):
        img = Image.new("RGBA", (K, K), (0, 0, 0, 0))
        px = img.load()
        for y in range(K):
            for x in range(K):
                px[x, y] = self.px[y][x]
        img.save(path)


# --------------------------------------------------------------------------
# SKIN (head + neck)
# --------------------------------------------------------------------------
def skin_ops(c1, c2):
    b = Renderer()
    spans = {
        1: (13, 18), 2: (12, 19), 3: (11, 20), 4: (10, 21), 5: (10, 21),
        6: (10, 21), 7: (11, 20), 8: (11, 20), 9: (12, 19), 10: (13, 18),
    }
    for y, (x0, x1) in spans.items():
        b.hline(y, x0, x1, c1)
    b.set(12, 2, c2)   # hairline sheen
    b.set(11, 3, c2)
    b.set(21, 7, c2)   # jaw
    b.hline(11, 13, 18, c1)  # chin
    b.hline(12, 14, 17, c1)  # neck
    return b


# --------------------------------------------------------------------------
# HAIR
# --------------------------------------------------------------------------
def _cap(b, c1, c2, y0, y1):
    prof = {0: (10, 21), 1: (9, 22), 2: (8, 23), 3: (9, 22), 4: (10, 21), 5: (11, 20)}
    for i in range(y0, y1 + 1):
        if i - y0 in prof:
            x0, x1 = prof[i - y0]
            b.hline(i, x0, x1, c1)
    b.set(12, y0 + 1, c2)


def hair_ops(style, c1, c2):
    b = Renderer()
    if style == "bald":
        return b
    if style == "short":
        _cap(b, c1, c2, 1, 5)
        b.hline(5, 12, 19, c1)
        for y in range(4, 7):
            b.hline(y, 10, 12, c1)
            b.hline(y, 22, 23, c1)
    elif style == "long":
        _cap(b, c1, c2, 1, 5)
        for y in range(6, 15):
            width = 3 if y < 11 else 2
            b.hline(y, 8, 8 + width - 1, c1)
            b.hline(y, 25 - width + 1, 25, c1)
        b.set(10, 14, c2)
    elif style == "curly":
        _cap(b, c1, c2, 1, 5)
        for y in range(4, 9):
            b.set(9, y, c1)
            b.set(23, y, c1)
        for y in range(4, 8):
            b.hline(y, 10, 12, c1)
            b.hline(y, 21, 23, c1)
    elif style == "pony":
        _cap(b, c1, c2, 1, 5)
        for y in range(4, 7):
            b.hline(y, 11, 13, c1)
            b.hline(y, 22, 24, c1)
        for y, w in zip(range(7, 15), range(5, 2, -1)):
            b.hline(y, 27 - w, 27, c1)
        b.set(26, 7, c2)
    elif style == "blond":
        _cap(b, c1, c2, 1, 5)
        for y in range(2, 6):
            b.set(15, y, c2)
            b.set(16, y, c2)
        for y in range(4, 8):
            b.hline(y, 10, 12, c1)
            b.hline(y, 23, 25, c1)
    elif style == "sweep":
        _cap(b, c1, c2, 1, 4)
        for y in range(3, 11):
            b.hline(y, 8, 10, c1)
            b.hline(y, 23, 25, c1)
    elif style == "spike":
        _cap(b, c1, c2, 1, 4)
        for x in (9, 13, 17, 22):
            b.set(x, 0, c2)
        for y in range(4, 7):
            b.set(10, y, c1)
            b.set(23, y, c1)
    return b


# --------------------------------------------------------------------------
# EYES / BROWS / MOUTH
# --------------------------------------------------------------------------
def _eye(b, x, y, c1, c2):
    b.set(x, y, (255, 255, 255, 255))   # sclera
    b.set(x + 1, y, c1)                  # iris
    b.set(x + 2, y, (255, 255, 255, 255))
    b.set(x, y + 1, c1)
    b.set(x + 1, y + 1, c2)              # pupil
    b.set(x + 2, y + 1, c1)


def eyes_ops(shape, c1, c2):
    b = Renderer()
    if shape == "almond":
        for ex in (12, 18):
            b.set(ex, 7, c1)
            b.set(ex + 1, 7, c1)
        b.set(13, 7, c2)
        b.set(19, 7, c2)
    elif shape == "anger":
        for ex in (12, 18):
            b.hline(6, ex, ex + 1, c1)
            b.hline(7, ex, ex + 1, (46, 46, 46, 255))
    else:  # round + big + glint
        if shape == "glint":
            _eye(b, 11, 6, c1, c2)
            _eye(b, 19, 6, c1, c2)
            b.set(12, 6, (255, 255, 255, 255))
            b.set(19, 6, (255, 255, 255, 255))
        else:
            _eye(b, 12, 6, c1, c2)
            _eye(b, 18, 6, c1, c2)
            if shape == "big":
                b.set(13, 5, c1)
                b.set(19, 5, c1)
    return b


def brows_ops(style, c1, c2):
    b = Renderer()
    if style == "arch":
        b.set(11, 4, c1); b.set(12, 3, c1); b.set(13, 3, c1); b.set(14, 4, c1)
        b.set(18, 4, c1); b.set(19, 3, c1); b.set(20, 3, c1); b.set(21, 4, c1)
    elif style == "anger":
        b.hline(4, 12, 15, c1)
        b.hline(4, 18, 21, c1)
    else:
        b.hline(4, 11, 14, c1)
        b.hline(4, 17, 20, c1)
    return b


def mouth_ops(style, c1, c2):
    b = Renderer()
    if style == "smile":
        b.hline(10, 14, 18, c1)
        b.set(15, 11, c2)
        b.set(16, 11, c2)
    elif style == "big":
        b.hline(10, 13, 19, c1)
        b.set(14, 11, c2)
        b.set(15, 11, c2)
        b.set(16, 11, c2)
        b.set(17, 11, c2)
    elif style == "neutral":
        b.hline(10, 14, 18, c1)
    elif style == "open":
        b.hline(9, 14, 18, c2)
        b.hline(10, 13, 19, c1)
        b.rect(15, 10, 16, 11, (214, 69, 81, 255))  # tongue
        b.hline(11, 14, 18, c1)
    else:  # fine
        b.set(15, 10, c1)
        b.set(16, 10, c1)
    return b


# --------------------------------------------------------------------------
# OUTFIT (heroic silhouette)
# --------------------------------------------------------------------------
def outfit_ops(accent, c1, c2):
    b = Renderer()

    def darken(c):
        return tuple(int(ch * 0.62) for ch in c[:3]) + (255,)

    # shoulders (narrow, just wider than the head line x8..x21)
    b.rect(9, 13, 22, 13, c1)
    b.rect(9, 14, 22, 14, c1)
    # torso (rectangular, straight sides w/ sloped shoulders)
    b.rect(10, 15, 21, 15, c1)
    b.rect(10, 16, 21, 23, c1)
    # arms (short — hang alongside the torso and end at the hips y21)
    for y in range(15, 22):
        b.set(7, y, c1)   # left sleeve
        b.set(8, y, c1)
        b.set(23, y, c1)  # right sleeve
        b.set(24, y, c1)
    for x in (7, 8, 23, 24):    # sleeve shoulder cap
        b.set(x, 15, darken(c1))
    b.hline(20, 7, 8, darken(c1))      # left hand
    b.hline(20, 23, 24, darken(c1))    # right hand
    b.hline(21, 7, 8, darken(c1))
    b.hline(21, 23, 24, darken(c1))
    # legs (straight, symmetric about center col 15.5)
    b.hline(24, 10, 12, c1); b.hline(24, 19, 21, c1)
    b.hline(25, 10, 12, c1); b.hline(25, 19, 21, c1)
    b.hline(26, 10, 12, c1); b.hline(26, 19, 21, c1)
    b.hline(27, 10, 12, c1); b.hline(27, 19, 21, c1)
    b.hline(28, 10, 12, c1); b.hline(28, 19, 21, c1)
    b.hline(29, 10, 12, c1); b.hline(29, 19, 21, c1)
    # boots (symmetric, no offset)
    b.hline(30, 11, 13, c1); b.hline(30, 18, 20, c1)
    b.hline(31, 11, 13, c1); b.hline(31, 18, 20, c1)
    # generic shading / belt
    b.hline(22, 10, 21, c2)
    b.hline(31, 11, 13, c2)
    b.hline(31, 18, 20, c2)
    # class accents
    if accent == "plate":                       # Paladin
        b.hline(13, 13, 18, c2)
        b.rect(15, 16, 16, 17, c2)
    elif accent == "robe":                       # Mage
        b.rect(10, 24, 21, 30, c2)
        b.rect(15, 18, 16, 20, c2)
    elif accent == "hood":                       # Voleur
        b.rect(12, 14, 19, 15, c2)
        b.rect(11, 16, 20, 17, c2)
    elif accent == "rknight":                    # Chevalier Noir
        b.rect(15, 16, 16, 18, c2)
        b.set(12, 20, c2)
        b.set(20, 20, c2)
        b.rect(10, 24, 12, 30, c2)
        b.rect(19, 24, 21, 30, c2)
    elif accent == "ranger":                     # Ranger
        b.set(9, 20, c2)   # wrist trims
        b.set(22, 20, c2)
        b.rect(14, 21, 17, 22, c2)
    elif accent == "scuyer":                     # Écuyer
        b.rect(10, 17, 21, 18, c2)
        b.rect(15, 20, 16, 19, c2)
        b.hline(13, 12, 19, (214, 69, 81, 255))
    else:                                        # Guerrier
        b.rect(15, 19, 16, 20, c2)
    return b


# --------------------------------------------------------------------------
# HATS + ACCESSORIES
# --------------------------------------------------------------------------
def hat_ops(style, c1, c2):
    b = Renderer()
    if style == "cap":
        b.rect(9, 2, 22, 5, c1)
        b.rect(8, 4, 23, 5, c2)
    elif style == "wizard":
        b.rect(11, 0, 20, 3, c1)
        b.rect(9, 3, 22, 4, c1)
        b.rect(13, 1, 18, 2, c2)
    elif style == "crown":
        b.hline(1, 12, 16, c1)
        b.rect(11, 1, 20, 3, c1)
        b.rect(12, 0, 12, 1, c2)
        b.rect(16, 0, 16, 1, c2)
        b.hline(3, 11, 19, c2)
    elif style == "sal":
        b.rect(10, 1, 21, 4, c1)   # cap above the eyes
        b.rect(9, 4, 22, 5, c2)    # brim, stops at y5 (never covers eyes y6..7)
    elif style == "mage":
        b.rect(11, 0, 20, 3, c1)
        b.set(14, 0, c2)
        b.set(17, 0, c2)
        b.rect(9, 3, 22, 4, c1)
    return b


def acc_ops(style, c1, c2):
    b = Renderer()
    if style == "glasses":
        b.rect(11, 6, 15, 7, c1)
        b.rect(18, 6, 22, 7, c1)
        b.hline(7, 15, 18, c1)
        b.set(11, 5, c2)
        b.set(22, 5, c2)
    elif style == "mask":
        b.rect(10, 9, 21, 10, c1)
        for x in (12, 14, 16, 18, 20):
            b.set(x, 9, (26, 26, 46, 255))
    elif style == "diadem":
        b.hline(0, 12, 19, c1)
        b.hline(1, 12, 19, c2)
        b.set(15, 0, c2)
    elif style == "tri":
        b.set(12, 13, c1)
        b.set(20, 13, c1)
        b.set(13, 14, c2)
        b.set(19, 14, c2)
        for sy in (16, 18, 20):
            b.set(12, sy, c1)
            b.set(20, sy, c1)
    return b


# --------------------------------------------------------------------------
# dispatch
# --------------------------------------------------------------------------
HAIR_STYLES = {
    "hair_0": "bald", "hair_1": "short", "hair_2": "long", "hair_3": "curly",
    "hair_4": "pony", "hair_5": "blond", "hair_6": "sweep", "hair_7": "spike",
}
EYE_STYLES = {
    "eyes_1": "round", "eyes_2": "almond", "eyes_3": "big", "eyes_4": "anger",
    "eyes_5": "glint",
}
BROW_STYLES = {"brow_1": "neutral", "brow_2": "arch", "brow_3": "anger"}
MOUTH_STYLES = {
    "mouth_1": "smile", "mouth_2": "big", "mouth_3": "neutral",
    "mouth_4": "open", "mouth_5": "fine",
}
OUTFIT_STYLES = {
    "outfit_1": "plain", "outfit_2": "robe", "outfit_3": "hood",
    "outfit_4": "plate", "outfit_5": "rknight", "outfit_6": "ranger",
    "outfit_7": "scuyer",
}
HAT_STYLES = {
    "hat_0": "none", "hat_1": "cap", "hat_2": "wizard", "hat_3": "crown",
    "hat_4": "sal", "hat_5": "mage",
}
ACC_STYLES = {
    "acc_0": "none", "acc_1": "glasses", "acc_2": "mask", "acc_3": "diadem",
    "acc_4": "tri",
}


def render_part(part):
    cat = part["category"]
    c1 = rgb(part["color1"])
    c2 = rgb(part["color2"])
    if cat == "skin":
        return skin_ops(c1, c2), False
    if cat == "hair":
        return hair_ops(HAIR_STYLES.get(part["id"], "short"), c1, c2), False
    if cat == "eyes":
        return eyes_ops(EYE_STYLES.get(part["id"], "round"), c1, c2), False
    if cat == "brow":
        return brows_ops(BROW_STYLES.get(part["id"], "neutral"), c1, c2), False
    if cat == "mouth":
        return mouth_ops(MOUTH_STYLES.get(part["id"], "smile"), c1, c2), False
    if cat == "outfit":
        return outfit_ops(OUTFIT_STYLES.get(part["id"], "plain"), c1, c2), False
    if cat == "hat":
        return hat_ops(HAT_STYLES.get(part["id"], "none"), c1, c2), False
    if cat == "acc":
        return acc_ops(ACC_STYLES.get(part["id"], "none"), c1, c2), False
    return Renderer(), False


def main():
    with open(os.path.join(BASE, "character_catalog.json")) as f:
        data = json.load(f)
    parts = data["parts"]
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(MODEL_DIR, exist_ok=True)
    written = 0
    for part in parts:
        renderer, _ = render_part(part)
        renderer.export(os.path.join(OUT_DIR, part["id"] + ".png"))
        written += 1

    dart_path = os.path.join(MODEL_DIR, "character_catalog.g.dart")
    with open(dart_path, "w") as f:
        f.write("// GENERATED by tool/sync_catalog.py -- DO NOT EDIT MANUALLY.\n")
        f.write("import 'character_part.dart';\n\n")
        f.write("const List<CharacterPart> kCharacterParts = [\n")
        for part in parts:
            name = part["label"].replace("'", "\\'")
            f.write(
                "  CharacterPart(id: '%s', category: CharacterCategory.%s, "
                "label: '%s', unlockLevel: %d, cost: %s),\n"
                % (part["id"], part["category"], name, part["unlockLevel"], part["cost"])
            )
        f.write("];\n")
    print("Generated %d sprite files + %s" % (written, os.path.relpath(dart_path, ROOT)))


if __name__ == "__main__":
    main()