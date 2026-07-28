# Emotional-Fidelity Playtest Checklist — Mochi Baby Mood Sprites

> **Purpose**: satisfy `mochi-baby-mood-sprites.md`'s Next Steps #3 and Production gate-check exit-criteria #5. Confirms the 5 delivered sprites communicate mood through art alone — no color legend, no text label — per Art Bible P3's "text-off test." This gate must **pass before** Pet Room screen implementation begins.
>
> **Status this checklist produces**: Approved / Needs Revision — feeds back into `design/assets/asset-manifest.md`'s Approved column.

---

## 1. Materials to prepare

- [ ] The 5 sprite files, each shown **alone, full-screen or full-page, with no filename, no caption, no color legend visible**:
  - `design/assets/generated/mochi_baby/spec_compliant/mochi_baby_happy_idle.png`
  - `design/assets/generated/mochi_baby/spec_compliant/mochi_baby_content_idle.png`
  - `design/assets/generated/mochi_baby/spec_compliant/mochi_baby_tired_idle.png`
  - `design/assets/generated/mochi_baby/spec_compliant/mochi_baby_sad_idle.png`
  - `design/assets/generated/mochi_baby/spec_compliant/mochi_baby_sleep_idle.png`
- [ ] A way to show one sprite at a time (phone/tablet/printout), background must not be a game screen with any HUD/color cue nearby.
- [ ] A blind randomized order for each child — **do not show HAPPY→CONTENT→TIRED→SAD→SLEEPING in spec order**, since energy-descending order is itself a hint. Shuffle per child (e.g. draw slips of paper, or randomize in a slideshow).
- [ ] This recording table (Section 4), printed or open on a second device.
- [ ] Testers: **3–5 children, ages 6–10** (the GDD's target range). More is better if available; 3 is the minimum for the pass/fail math in Section 5 to mean anything.

---

## 2. What NOT to do (avoids invalidating the test)

- [ ] Do **not** say the mood name before showing the image ("this is when Mochi is sad — what do you think?" is leading).
- [ ] Do **not** offer a multiple-choice list of mood words. Ask open-ended.
- [ ] Do **not** let the child see more than one sprite at a time, and don't let them compare/re-look at a previous one before answering the current one.
- [ ] Do **not** correct or hint after their answer ("close, but...") until all 5 are done — save discussion for after.
- [ ] Do **not** test your own child/tester twice on the same sprite in one session (learning effect).

---

## 3. Procedure (run once per child)

1. Say: *"I'm going to show you a picture of a character named Mochi. Just look at the picture and tell me: how do you think Mochi is feeling right now?"*
2. Show sprite #1 (per that child's randomized order). Wait for a spontaneous answer — don't prompt beyond "take your time" if they're quiet.
3. Write down their **exact words** in the recording table (Section 4), not your interpretation yet.
4. Repeat for all 5 sprites, one at a time, in that child's randomized order.
5. Only after all 5 are shown: you may go back and ask "why did you think that one?" for any answer you want more context on — this is optional color, not part of the pass/fail score.

---

## 4. Recording table

Copy this table once per child. `Guess (verbatim)` = exactly what the child said. `Match?` = filled in *after* the session using Section 5's synonym list, not during.

| Child ID | Sprite shown (mood) | Order shown | Guess (verbatim) | Match? (Y/N) |
|---|---|---|---|---|
| C1 | HAPPY | | | |
| C1 | CONTENT | | | |
| C1 | TIRED | | | |
| C1 | SAD | | | |
| C1 | SLEEPING | | | |
| C2 | HAPPY | | | |
| C2 | CONTENT | | | |
| C2 | TIRED | | | |
| C2 | SAD | | | |
| C2 | SLEEPING | | | |
| C3 | HAPPY | | | |
| C3 | CONTENT | | | |
| C3 | TIRED | | | |
| C3 | SAD | | | |
| C3 | SLEEPING | | | |

(Add C4/C5 rows if testing more children.)

---

## 5. Scoring — accepted synonyms per mood

Mark `Match? = Y` if the child's answer falls in that mood's accepted list below (age-appropriate synonyms count; a 6-year-old won't say "content," they'll say "okay" or "fine").

| Mood | Accept as a match |
|---|---|
| **HAPPY** | happy, excited, joyful, super happy, really glad, cheering |
| **CONTENT** | okay, fine, good, calm, relaxed, normal, content, chill |
| **TIRED** | tired, sleepy, yawning, worn out, low energy |
| **SAD** | sad, upset, unhappy, down, crying (without actual tears drawn), lonely |
| **SLEEPING** | sleeping, asleep, sleepy (only mark Y for SLEEPING if they clearly mean *already asleep*, not just tired — if ambiguous between TIRED/SLEEPING, note both under "why" in Section 3 step 5 and use your judgment) |

**Do not accept as a match**: any answer that requires the child to have seen a color legend or label elsewhere (if they say a color name instead of a feeling — e.g. "purple" — that's not a mood identification, mark N).

---

## 6. Pass/fail threshold

For **each of the 5 moods**, calculate: `(# children who matched) / (# children tested)`.

- **≥ 80% match rate** (e.g. 4/5 or 3/3 children correct) → that mood **passes**.
- **50–79%** → **borderline** — note it, but don't auto-fail; look at the "why" notes for a pattern (e.g. if everyone confuses SAD and TIRED specifically, that's a real signal even at 60%).
- **< 50%** → that mood **fails** — the sprite does not read on its own and needs revision before this gate can close.

**Overall gate verdict**:
- All 5 moods ≥ 80% → **Approved**. Update `design/assets/asset-manifest.md`'s Approved column, proceed to Pet Room screen implementation.
- Any mood < 80% → **Needs Revision** for that specific sprite only (the other passing moods do not need rework). Log which mood(s) and the specific confusion pattern observed (e.g. "SAD read as TIRED by 3/3 children — ears not flat enough / no visible frown at this size").

> This 80%/50% threshold is a reasonable default, not dictated by the spec (the spec only says "confirm each mood is independently identifiable"). Adjust if you have a strong reason to use a stricter or looser bar before running the test — don't change it after seeing results.

---

## 7. If a mood fails — where to route the fix

1. Re-read that mood's **Visual Description** in `design/assets/specs/mochi-baby-mood-sprites.md` against the actual delivered sprite — check whether the confused-with-mood's distinguishing detail (e.g. SAD's flattened ears vs. TIRED's asymmetric-but-not-flat ears) is actually visible at the size children were shown.
2. If the art itself is the problem (not just presentation size), that sprite needs a targeted regeneration — feedback the specific confusion pattern from Section 6 as the correction instruction, the same way the PerfectPixel regeneration passes were done during production.
3. Re-run only Sections 3–6 for the revised sprite (no need to re-test the moods that already passed).

---

## 8. Sign-off

- [ ] Tester/parent name: ______________________
- [ ] Date run: ______________________
- [ ] Number of children tested: ______________________
- [ ] Verdict: ☐ Approved (all 5 ≥80%) ☐ Needs Revision (list moods below)
- [ ] Moods needing revision: ______________________
- [ ] Notes for whoever revises: ______________________

---

## Informal feedback log (does not count toward the pass/fail verdict above)

Positive general reactions ("likes the art style") are a good signal but are **not** a substitute for Section 3–6's per-mood identification test — liking the character and correctly reading its mood are different questions. Log informal reactions here; they don't move Section 8's verdict.

| Date | Child | What happened | Note |
|---|---|---|---|
| 2026-07-15 | (unspecified) | Shown the art informally (not the structured randomized test) | Positive reaction — liked the sprite(s) |

**Still open**: the structured Section 3–6 test (randomized, unlabeled, per-mood guess recorded) has not been run yet. Run it before marking Section 8's verdict.
