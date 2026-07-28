"""Generate the Last Seal palette system: ramps, hex tables, MagicaVoxel PNG, swatch sheet.

Ramp formula (shared by every matte channel -- this is the style glue):
  shadows shift hue toward COOL_ANCHOR, gain saturation, lose value
  highlights shift hue toward WARM_ANCHOR, lose saturation, gain value
"""
import colorsys, zlib, struct, json, os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "design", "art")

WARM_ANCHOR = 50.0   # yellow
COOL_ANCHOR = 260.0  # violet-blue

V_FLOOR, V_CEIL = 14.0, 92.0
S_CEIL = 88.0

# 9-step matte ramp. Steps are PROPORTIONAL, not absolute: each colour's available
# headroom inside the value window is divided up, so a dark base and a pale base both
# get nine distinct steps instead of collapsing against the clamp.
RAMP_F = [0.28, 0.52, 0.74, 0.94]
HUE_SWING = 22.0   # max hue shift at the far end of the ramp
SAT_GAIN = 14.0    # shadows gain this much saturation at the far end
SAT_DROP = 22.0    # highlights lose this much at the far end
TINT_FLOOR = 9.0   # ...but never below this, so neutrals stay tinted, not white

# Function tier (Hearth Gold) is locked by art-bible 8.4: 0 deg hue, +-5% S, +-10% V.
# It cannot carry a nine-step ramp without breaking that lock -- see doc, open items.
GOLD_STEPS = [
    ("S2", -10.0, +4.0, 0.0, None),
    ("S1",  -5.0, +2.0, 0.0, None),
    ("BASE", 0.0,  0.0, 0.0, None),
    ("L1",   0.0, -5.0, 0.0, None),
]

# Emissive: 5 steps, outer falloff -> burnt-out core. Not bound by the matte value
# window: real light blows out, and the core is what sells it as light.
EMISSIVE_STEPS = [
    ("OUTER", 95.0, 32.0,  0.0),
    ("GLOW",  90.0, 52.0,  0.0),
    ("MID",   78.0, 78.0,  5.0),
    ("CORE",  40.0, 94.0, 10.0),
    ("FLARE", 12.0, 100.0, 14.0),
]

# a near-white effect (spirit) needs its own saturation profile or it reads olive
EMISSIVE_PALE = [
    ("OUTER", 48.0, 40.0,  0.0),
    ("GLOW",  42.0, 60.0,  0.0),
    ("MID",   22.0, 85.0,  4.0),
    ("CORE",  10.0, 96.0,  8.0),
    ("FLARE",  3.0, 100.0, 12.0),
]


def hex_to_hsv(h):
    h = h.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    hh, ss, vv = colorsys.rgb_to_hsv(r, g, b)
    return hh * 360.0, ss * 100.0, vv * 100.0


def hsv_to_hex(h, s, v):
    r, g, b = colorsys.hsv_to_rgb((h % 360.0) / 360.0, max(0.0, min(1.0, s / 100.0)),
                                  max(0.0, min(1.0, v / 100.0)))
    return "#%02X%02X%02X" % (round(r * 255), round(g * 255), round(b * 255))


def shift_toward(h, anchor, amount):
    if anchor is None or amount == 0:
        return h
    d = ((anchor - h + 180.0) % 360.0) - 180.0
    if abs(d) <= amount:
        return anchor
    return (h + amount * (1 if d > 0 else -1)) % 360.0


def matte_ramp(base_hex):
    """Nine proportional steps: S4..S1, BASE, L1..L4."""
    h, s, v = hex_to_hsv(base_hex)
    down = max(0.0, v - V_FLOOR)
    up = max(0.0, V_CEIL - v)
    shadows, lights = [], []
    for i, f in enumerate(RAMP_F):
        shadows.append(("S%d" % (i + 1), hsv_to_hex(
            shift_toward(h, COOL_ANCHOR, HUE_SWING * f),
            min(S_CEIL, s + SAT_GAIN * f),
            v - down * f)))
        # Highlights desaturate -- but never all the way to pure grey. A near-neutral
        # keeps a rising warm tint floor, so stone lights warm up instead of collapsing
        # onto white (and onto each other).
        lights.append(("L%d" % (i + 1), hsv_to_hex(
            shift_toward(h, WARM_ANCHOR, HUE_SWING * f),
            max(s - SAT_DROP * f, TINT_FLOOR * f),
            v + up * f)))
    return list(reversed(shadows)) + [("BASE", base_hex.upper())] + lights


def locked_ramp(base_hex, steps):
    h, s, v = hex_to_hsv(base_hex)
    out = []
    for name, dv, ds, amt, anchor in steps:
        if name == "BASE":
            out.append((name, base_hex.upper()))
        else:
            out.append((name, hsv_to_hex(shift_toward(h, anchor, amt),
                                         max(0.0, min(S_CEIL, s + ds)), v + dv)))
    return out


def emissive_ramp(hue, profile=None):
    out = []
    for name, s, v, warm in (profile or EMISSIVE_STEPS):
        out.append((name, hsv_to_hex(shift_toward(hue, WARM_ANCHOR, warm), s, v)))
    return out


# ---------------------------------------------------------------- colour set
STRUCTURE = [
    ("timber_oak",      "Eiche (kanonisch)",      "#8B5E3C"),
    ("timber_birch",    "Birke",                  "#CBAE84"),
    ("timber_pine",     "Kiefer",                 "#B08A55"),
    ("timber_darkoak",  "Dunkle Eiche",           "#5C3D28"),
    ("stone_hearth",    "Herdstein (kanonisch)",  "#8A8D8F"),
    ("stone_granite",   "Granit",                 "#8E9499"),
    ("stone_slate",     "Schiefer",               "#5A6169"),
    ("stone_sandstone", "Sandstein",              "#C7AA79"),
    ("clay_ochre",      "Lehm",                   "#B07C4C"),
    ("thatch_umber",    "Reet (kanonisch)",       "#A8642F"),
    ("shingle_brown",   "Holzschindel",           "#7A6A57"),
    ("plaster_cream",   "Putz",                   "#D9CBAE"),
]

TERRAIN = [
    ("band_lowland",  "Band 1 Tiefland (kanonisch)", "#9CAD6E"),
    ("band_midland",  "Band 2 Hügel (kanonisch)",    "#A98F5E"),
    ("band_highland", "Band 3 Fels (kanonisch)",     "#7C818A"),
    ("band_peak",     "Band 4 Gipfel (kanonisch)",   "#C9D3D8"),
    ("valley_ochre",  "Talocker (kanonisch)",        "#C2AD7C"),
]

VEGETATION = [
    ("veg_grass",        "Wiese",          "#7E9B4E"),
    ("veg_leaf_summer",  "Laub Sommer",    "#5E8A3C"),
    ("veg_leaf_spring",  "Laub Frühling",  "#9CBE55"),
    ("veg_leaf_autumn",  "Laub Herbst",    "#C4762B"),
    ("veg_conifer",      "Nadelholz",      "#3E6350"),
    ("veg_moss",         "Moos",           "#7A8C4A"),
    ("veg_bloom_violet", "Blüte Violett",  "#8A6BA8"),
    ("veg_bloom_rose",   "Blüte Rosé",     "#CE9AC4"),  # magenta-pink: clears Corruption
    ("veg_bloom_yellow", "Blüte Gelb",     "#E0C24E"),
    ("veg_crop_grain",   "Getreide",       "#C9A94E"),
]

FUNCTION = [("hearth_gold", "Hearth Gold (gesperrt)", "#F5A83C")]

# emissive channel: hue only -- saturation/value come from the emissive ramp
MAGIC = [
    ("mag_arcane",     "Arkan Violett",   275.0, None),
    ("mag_rune",       "Rune Cyan",       184.0, None),
    ("mag_vital",      "Vital Grün",      140.0, None),
    ("mag_ember",      "Glut Amber",       25.0, None),  # 25 not 32: widen gap to Hearth Gold (H36)
    ("mag_frost",      "Frost",           228.0, None),  # 228 not 206: stay clear of State Blue
    ("mag_corruption", "Corruption (5.5)", 328.0, None),  # sickly violet-red; 5.5 hex still open
    ("mag_void",       "Leere",           292.0, None),
    ("mag_spirit",     "Geist Warmweiß",   45.0, EMISSIVE_PALE),
]

UI = [
    ("ui_chrome",  "Panel-Füllung (kanonisch)", "#262220"),
    ("ui_text",    "Text (kanonisch)",          "#EDE6DA"),
    ("state_blue", "State Blue (nur UI)",       "#4A90C4"),
    ("state_orange", "State Orange (nur UI)",   "#E1752E"),
    ("threshold_cool", "Threshold Cool (nur Nebel)", "#6B8593"),
]

# ---------------------------------------------------------------- build
channels = []
for title, items in [("Struktur / Baumaterial", STRUCTURE),
                     ("Terrain", TERRAIN),
                     ("Vegetation / Organik", VEGETATION)]:
    rows = [(k, label, matte_ramp(base)) for k, label, base in items]
    channels.append((title, rows))

gold_rows = [(k, label, locked_ramp(base, GOLD_STEPS)) for k, label, base in FUNCTION]
channels.append(("Funktion (gesperrt)", gold_rows))

magic_rows = [(k, label, emissive_ramp(hue, prof)) for k, label, hue, prof in MAGIC]
channels.append(("Magie / Emissiv", magic_rows))

ui_rows = [(k, label, [("BASE", base)]) for k, label, base in UI]
channels.append(("UI / State (gesperrt)", ui_rows))

# ---------------------------------------------------------------- markdown
md = []
for title, rows in channels:
    md.append("### %s\n" % title)
    steps = [s for s, _ in max(rows, key=lambda r: len(r[2]))[2]]
    what = "Effekt" if title.startswith("Magie") else (
        "Rolle" if title.startswith("UI") else "Material")
    md.append("| Slug | %s | %s |" % (what, " | ".join(steps)))
    md.append("|---|---|%s" % ("---|" * len(steps)))
    for k, label, ramp in rows:
        md.append("| `%s` | %s | %s |" % (k, label, " | ".join("`%s`" % c for _, c in ramp)))
    md.append("")
markdown = "\n".join(md)
open(os.path.join(OUT, "palette_tables.md"), "w", encoding="utf-8").write(markdown)

# ---------------------------------------------------------------- flat list
flat = []
for title, rows in channels:
    for k, label, ramp in rows:
        for step, hexv in ramp:
            flat.append({"channel": title, "slug": k, "label": label,
                         "step": step, "hex": hexv})
json.dump(flat, open(os.path.join(OUT, "palette.json"), "w", encoding="utf-8"),
          indent=1, ensure_ascii=False)

failures, notes = [], []


# ---------------------------------------------------------------- PNG writer
def write_png(path, pixels, w, h):
    raw = b""
    for y in range(h):
        raw += b"\x00" + b"".join(
            struct.pack("BBB", *pixels[y * w + x]) for x in range(w))
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    open(path, "wb").write(png)


def hx(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


# A .vox palette holds exactly 256 slots, and 9 steps per colour no longer fit in one
# file. Split by authoring task instead -- you load the palette for what you are building.
PALETTE_FILES = {
    "palette-build": ["Struktur / Baumaterial", "Terrain",
                      "Funktion (gesperrt)", "UI / State (gesperrt)"],
    "palette-nature": ["Vegetation / Organik", "Terrain"],
    "palette-magic": ["Magie / Emissiv", "Funktion (gesperrt)",
                      "UI / State (gesperrt)"],
}

png_report = []
for name, wanted in PALETTE_FILES.items():
    entries = [e for e in flat if e["channel"] in wanted]
    if len(entries) > 256:
        failures.append("PNG %s overflows: %d slots" % (name, len(entries)))
        entries = entries[:256]
    slots = [hx(e["hex"]) for e in entries]
    n = len(slots)
    slots += [(0, 0, 0)] * (256 - n)
    write_png(os.path.join(OUT, name + ".png"), slots, 256, 1)
    png_report.append("%s.png: %d/256 slots (%d free)" % (name, n, 256 - n))

# ---------------------------------------------------------------- validator
# Rules that must hold for the palette to stay inside the Art Bible.
GOLD_H, GOLD_S, GOLD_V = hex_to_hsv("#F5A83C")
BLUE_H, BLUE_S, BLUE_V = hex_to_hsv("#4A90C4")
GOLD_PUNCH = GOLD_S * GOLD_V / 100.0

WORLD = ("Struktur / Baumaterial", "Terrain", "Vegetation / Organik")


def hue_dist(a, b):
    return abs(((a - b + 180.0) % 360.0) - 180.0)


for e in flat:
    h, s, v = hex_to_hsv(e["hex"])
    tag = "%s.%s" % (e["slug"], e["step"])
    if e["channel"] in WORLD:
        # R1 -- Hearth Gold must win the eye (art-bible 3.3 / prohibition 4)
        if s * v / 100.0 >= GOLD_PUNCH:
            failures.append("R1 %s %s outpunches Hearth Gold (%.0f >= %.0f)"
                            % (tag, e["hex"], s * v / 100.0, GOLD_PUNCH))
        # R2 -- no saturated world colour crowding State Blue (prohibition 3)
        if hue_dist(h, BLUE_H) < 15.0 and s > 40.0:
            failures.append("R2 %s %s crowds State Blue" % (tag, e["hex"]))
        # R3 -- no saturated red in world geometry (prohibition 2).
        # Value guard: a saturated warm hue below 50% value reads as brown/umber,
        # not as a red signal -- deep wood/thatch shadows legitimately land there.
        if (h >= 345.0 or h <= 15.0) and s > 40.0 and v > 50.0:
            failures.append("R3 %s %s lands in the forbidden red band" % (tag, e["hex"]))
        # R4 -- value window, no pure black/white
        if v > V_CEIL + 0.5 or v < V_FLOOR - 0.5:
            failures.append("R4 %s %s outside value window" % (tag, e["hex"]))

# R5 -- emissive must not read as Hearth Gold.
# Documented exemption: mag_ember IS hearth fire. Sharing Gold's warm family is
# the intent (art-bible 2.1 "warmest pixel cluster"), not a collision.
R5_EXEMPT = {"mag_ember"}
for e in flat:
    if e["channel"].startswith("Magie") and e["step"] == "MID" \
            and e["slug"] not in R5_EXEMPT:
        h, s, v = hex_to_hsv(e["hex"])
        if hue_dist(h, GOLD_H) < 12.0 and abs(v - GOLD_V) < 20.0:
            failures.append("R5 %s %s reads as Hearth Gold" % (e["slug"], e["hex"]))

# R6 -- no duplicate slots
seen = {}
for e in flat:
    seen.setdefault(e["hex"], []).append("%s.%s" % (e["slug"], e["step"]))
for hexv, owners in seen.items():
    if len(owners) > 1:
        notes.append("duplicate %s -> %s" % (hexv, ", ".join(owners)))

# adjacency notes (not failures -- pairs to verify in the grayscale/Dusk pass)
for a, b, why in [("veg_bloom_rose", "mag_corruption", "Bluete Rose vs Corruption"),
                  ("mag_frost", "state_blue", "Frost vs State Blue"),
                  ("mag_ember", "hearth_gold", "Glut vs Hearth Gold")]:
    ha = [x for x in flat if x["slug"] == a]
    hb = [x for x in flat if x["slug"] == b]
    if ha and hb:
        d = hue_dist(hex_to_hsv(ha[0]["hex"])[0], hex_to_hsv(hb[0]["hex"])[0])
        notes.append("adjacency %s: %.0f deg apart" % (why, d))

print("colors generated:", len(flat))
for line in png_report:
    print("  ", line)
print("VALIDATOR:", "PASS" if not failures else "FAIL (%d)" % len(failures))
for f in failures:
    print("  !", f)
for n in notes:
    print("  -", n)
print()
print()
print(markdown[:1600])
