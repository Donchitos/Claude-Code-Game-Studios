# Building Concept Prototype — "The Last Seal"

> PROTOTYPE — NOT FOR PRODUCTION. Throwaway build to test ONE question:
> **Does hybrid drag + free-place voxel building feel fluid and expressive?**
>
> **Status: CONCLUDED — Verdict PROCEED (2026-07-09).** Hypothesis confirmed.
> Findings in [REPORT.md](REPORT.md). This code is throwaway; the production building
> system is written from scratch, informed by the report.

## Starten

1. Öffne den **Godot 4.7**-Editor.
2. **Import** → wähle `prototypes/building-concept/project.godot`.
3. Oben rechts auf **▶ (Play / F5)** klicken.

## Steuerung

| Aktion | Eingabe |
|---|---|
| Wand-Pfeiler / 1 Block | **Links-Klick** (Wand = voller Höhe-Pfeiler) |
| Fläche bauen | **Links ziehen** (Wand = Umriss in voller Höhe, Boden/Dach/Fixture = gefüllt) |
| Block löschen | **Rechts-Klick** (auf den anvisierten Block, jede Höhe) |
| Bautyp wählen | **1** Wand · **2** Boden · **3** Dach · **4** Fixture |
| Dachform wechseln | **3** erneut drücken: Flach → Sattel → Walm → Pult |
| Bauhöhe (Ebene) | **R** höher · **F** tiefer (nur fürs Flächen-Ziehen auf leerem Boden) |
| Wandhöhe | **T** höher · **G** niedriger (Standard 3) |
| Block-Modus | **X** = Aufsetzen ⇄ Ersetzen |
| Rückgängig / Wiederherstellen | **Strg+Z** / **Strg+Y** (oder die Knöpfe unten links) |

### Dächer (neu)

Ziehst du mit Typ **Dach** eine Fläche, entsteht kein Flachdach mehr, sondern ein
gestuftes **echtes Dach** in der aktuellen Form. Drück **3** wiederholt, um die Form zu
wechseln — die Ghost-Vorschau zeigt sie vor dem Setzen:

- **Satteldach** — First, zwei Schrägen (klassisches Hausdach)
- **Walmdach** — Pyramide, Schrägen an allen vier Seiten
- **Pultdach** — eine durchgehende Schräge
- **Flachdach** — flache Platte (wie zuvor)

Tipp: Wände hochziehen, dann mit **Dach** über die **Wandoberkante** ziehen → das Dach
sitzt automatisch oben drauf.

### Rückgängig / Wiederherstellen (neu)

Jede Aktion (Setzen, Ziehen, Löschen, Alles-löschen) ist **eine** Undo-Stufe.
**Strg+Z** nimmt zurück, **Strg+Y** stellt wieder her — oder die Knöpfe **◄ Zurück** /
**Vorwärts ►** unten links.

### Blöcke auf/an bestehende Blöcke setzen (neu)

Fährst du mit der Maus über einen bereits gesetzten Block, wird er **weiß hervorgehoben**
— die Höhe ergibt sich automatisch, du musst die Ebene nicht ändern.

- **Modus „Aufsetzen"** (Standard): Klick setzt den neuen Block auf die anvisierte
  **Fläche** (z.B. ein Fixture außen an eine Wand, oder einen Block obendrauf).
- **Modus „Ersetzen"** (**X** drücken): Klick **ersetzt** den anvisierten Block direkt
  in seiner Zelle (z.B. Wandblock → Fenster/Tür).
| Kamera drehen | **Mittlere Maus ziehen** oder **Q / E** |
| Zoom | **Mausrad** |
| Schwenken | **W A S D** |
| Alles löschen | **C** |

## So testest du die Hypothese

Bau ein kleines Haus: Boden ziehen (Ebene 0), dann Ebene mit **R** auf 1 setzen und
mit dem Typ **Wand** einen Umriss ziehen → Wände. Ebene 2 → nochmal Wand-Umriss für
höhere Wände. Ebene 3 → Typ **Dach**, Fläche ziehen. Dann Typ **Fixture** einzeln
setzen (Tür/Fenster/Möbel). Frei einzelne Blöcke setzen für die kreative Ader.

Achte darauf: Fühlt sich Ziehen/Setzen **flüssig** an, oder wird Kamera / Snapping /
Tiefe **fummelig**? Genau das ist die riskanteste Annahme.
