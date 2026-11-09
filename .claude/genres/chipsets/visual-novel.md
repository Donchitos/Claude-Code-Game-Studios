# Chipset: visual-novel

There is no tested way to build long branching stories yet: a one-shot is one short scene with a few
choices and a few endings.

**Camera:** `static`; the art changes by scene, and nothing moves the view.

## Card defaults

- **choices-remembered**: Each choice changes what someone says later in the scene, and the scene
  shows that it remembered. Why: a choice feels real when the story answers it. Break it when: the
  choices are only flavour on purpose, a set story with a few asides. [telltale-1]
- **every-path-ends**: A wrong answer never ends the game early: the branches fold back together,
  every path reaches one of a few endings decided by what was chosen, the end screen names it and
  says how many there are, and play again starts at the first choice. Why: the player chooses for
  the character, not to dodge a game over, and wants another go to find the rest. Break it when:
  sudden bad ends are the charm, a choose-your-own-adventure with deaths. [ashwell-1], [emshort-2]
- **save-anywhere**: The game saves at every choice and from the pause screen, and continue picks up
  at that line. Why: a story is read in sittings. Break it when: the scene is so short it is always
  read in one go. [renpy-1]
- **reading-screen**: Each line appears at a speed the player sets, never on a clock they cannot
  stop, and a log key shows the lines already read. Why: the player reads at their own pace and can
  look back at a line they clicked past. Break it when: a timed scene where the clock is the point,
  and even then the speed setting stays. [gag-2], [renpy-1], [yarn-1]

## Feel

- **voices-and-faces**: Each speaker has a name on the box, a face that changes with the line, and
  their own soft blip as the letters appear. Why: the player hears who is talking and sees how they
  feel without being told. Break it when: one narrator tells it all in prose, with no cast on
  screen.
- **choice-lands**: A picked choice answers at once: the face reacts, a sound marks it, and the next
  line is about it. Why: the player feels the choice was heard, before any later payoff. Break it
  when: the choice is meant to sink in silently and come back much later. [telltale-1]
- **mood-music**: Music and background change with the scene's mood at a natural break, and a hard
  line can land in silence. Why: the player feels the turn in the scene before reading it. Break it
  when: the piece is silent on purpose, text alone.

## Feel variants

- **warm**: Warm and slow: gentle text, no timers, choices about how close to get to someone.
- **tense**: Tense: some choices run on a timer, and saying nothing is an answer too.
- **sharp**: Sharp and talky: some lines test a skill, and failing one opens its own scene.

## Choices that shape the pitch

- **What you choose:** what to say, line by line (default) · who to spend time with, a dating sim
  with a heart for each person · where to go next, a text adventure.
- **Stakes:** every path reaches an ending (default) · some bad ends, a replay to fix them · choices
  on a timer.
- **What the player sees:** drawn characters over a background (default) · text only,
  interactive fiction · a phone screen of messages.
- **Feeling:** the player feels responsible for someone by choosing what to say to them, because the
  story answers that choice before the scene ends.

## Later, never in a one-shot

- Routes that split and rejoin with what you chose → add it as a feature
- Consequences that show up chapters later → add it as a feature
- Many chapters and a full cast → grow it
- Skills that talk back as voices in your head → add it as a feature
- A skip key for lines already read → change it after play
- A gallery of unlocked art and a chart of endings → grow it
- Characters made by the game who remember and change
  → not tested yet: ask for it after play and the AI will try it untested

## In a mashup

The visual novel leads scenes, choices and what the story remembers. A life sim leads the days and
the visual novel leads the talks between them. A detective half leads the evidence and the visual
novel leads the questioning. An RPG or action half leads its fights, and a lost fight leads to a
scene, not a reload. A puzzle half leads its rules, and the story leads what solving them means.
