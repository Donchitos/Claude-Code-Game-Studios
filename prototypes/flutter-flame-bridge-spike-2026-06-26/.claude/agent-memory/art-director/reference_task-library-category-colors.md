---
name: task-library-category-colors
description: Where the 5 task-category-to-color mapping lives (Task Library #8), used by any child-facing category picker UI.
metadata:
  type: reference
---

The task category → Art Bible color mapping is defined in `design/gdd/task-library.md` (System #8), in its Visual/Audio Requirements section (~line 235–242), not in the Art Bible itself:

- `study` → Mint Breeze
- `arts` → Lavender Soft
- `chores` → Peach Glow
- `sport` → Honey Gold
- `helping` → Cloud White with border
- `custom` → neutral (+ / star icon)

Format spec there: SVG or PNG, 48×48px, pastel per category.

**How to use**: any screen that renders task category icons (Task Management UI #19's Step-1 picker, Task History rows, Parent Dashboard's pending-list category icons) should pull from this table rather than inventing new category colors. Verify the table still matches `task-library.md` before reuse — it could change if Task Library gets revised. See [[project_two-tone-visual-identity]] for how these colors are treated differently in child-facing vs parent-facing surfaces.
