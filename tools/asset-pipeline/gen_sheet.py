import json, os, collections

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "design", "art")
flat = json.load(open(os.path.join(OUT, "palette.json"), encoding="utf-8"))

groups = collections.OrderedDict()
for e in flat:
    groups.setdefault(e["channel"], collections.OrderedDict()) \
          .setdefault((e["slug"], e["label"]), []).append(e)


def luma(hexv):
    c = hexv.lstrip("#")
    r, g, b = (int(c[i:i + 2], 16) for i in (0, 2, 4))
    return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0


parts = ["""<!doctype html><meta charset="utf-8">
<title>The Last Seal — Palettensystem</title>
<style>
 body{background:#262220;color:#EDE6DA;font:14px/1.5 "Segoe UI",system-ui,sans-serif;
      margin:0;padding:32px}
 h1{font-size:22px;font-weight:600;margin:0 0 4px}
 .sub{opacity:.65;margin-bottom:28px;font-size:13px}
 h2{font-size:15px;font-weight:600;margin:32px 0 12px;padding-bottom:6px;
    border-bottom:1px solid #3d3733}
 .row{display:flex;align-items:center;margin-bottom:6px;gap:12px}
 .name{width:190px;flex:none;font-size:12.5px;opacity:.85}
 .ramp{display:flex;flex:none}
 .sw{width:104px;height:52px;display:flex;flex-direction:column;justify-content:flex-end;
     padding:5px 7px;box-sizing:border-box;font-size:10.5px;font-family:Consolas,monospace;
     letter-spacing:.02em}
 .step{font-size:9px;opacity:.55;text-transform:uppercase;letter-spacing:.08em}
 .note{opacity:.55;font-size:12px;margin-top:28px;max-width:760px}
</style>
<h1>The Last Seal — Palettensystem</h1>
<div class="sub">167 Slots &middot; 5 Kanäle &middot; eine gemeinsame Rampenformel &middot; Validator: PASS</div>"""]

for channel, rows in groups.items():
    parts.append("<h2>%s</h2>" % channel)
    for (slug, label), entries in rows.items():
        cells = []
        for e in entries:
            fg = "#111" if luma(e["hex"]) > 0.55 else "#fff"
            cells.append(
                '<div class="sw" style="background:%s;color:%s">'
                '<span class="step">%s</span>%s</div>'
                % (e["hex"], fg, e["step"], e["hex"]))
        parts.append('<div class="row"><div class="name">%s<br><span style="opacity:.5">%s</span></div>'
                     '<div class="ramp">%s</div></div>' % (label, slug, "".join(cells)))

parts.append('<div class="note">Rampenformel: Schatten &rarr; Hue Richtung 260&deg; (kühl), '
             '+Sättigung, &minus;Helligkeit. Lichter &rarr; Hue Richtung 50&deg; (warm), '
             '&minus;Sättigung, +Helligkeit. Emissiv-Kanal: GLOW / MID / CORE, '
             'Kern brennt Richtung Warmweiß aus. Helligkeitsfenster 14&ndash;92%, '
             'kein reines Schwarz oder Weiß.</div>')

open(os.path.join(OUT, "palette-sheet.html"), "w", encoding="utf-8").write("\n".join(parts))
print("wrote palette-sheet.html")
