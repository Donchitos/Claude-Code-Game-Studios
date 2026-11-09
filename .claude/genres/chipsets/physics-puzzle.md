# Chipset: physics-puzzle

There is no tested way to build real vehicle physics yet: a one-shot uses simple bodies of its own, and
since no solver can search physics, each level is proved by a recorded clear.

**Camera:** `static`; `follow2d` to follow a long shot, `orbit` for golf in 3D.

## Card defaults

- **same-shot-same-result**: The physics runs on a fixed step, never tied to the frame rate, so the
  same shot always does the same thing, and each level keeps a recorded clear. Why: a puzzle the
  player can solve twice, where luck never decides. Break it when: chaos is the fun, a sandbox of
  things to topple. [box2d-1], [matter-1], [fiedler-1]
- **settle-then-judge**: A shot is judged only once everything has come to rest, so a tower still
  wobbling can still fall, and a retry puts the level back at once. Why: the result is what the
  physics did, and a miss costs seconds, not a menu. Break it when: a clock judges the level, a race
  against time. [box2d-1], [limbo-5]
- **rated-clear**: Any clear wins the level, and a better one, fewer shots or more knocked down,
  earns a higher rating shown on the level select. Why: everyone moves on, and a player who wants
  more has a reason to replay. Break it when: a calm puzzle where any answer is enough.
  [angry-birds-1]

## Feel

- **aim-preview**: Dragging back aims and sets power, with a dotted line showing the first part of
  the flight. Why: the player aims by eye and learns the arc, but the landing stays theirs to judge.
  Break it when: reading the arc is the challenge, golf with only a power bar.
- **launch-and-follow**: The launch stretches and snaps with a whoosh, and the view follows the
  shot, then pans back to the level. Why: the player watches their own shot play out. Break it when:
  the level fits one screen and the shot never leaves it.
- **material-crash**: Wood, glass, stone and rubber each sound and break their own way, and a tower
  falls in a way you can read from what held it up. Why: the player learns which piece to hit by
  watching it fall. Break it when: there is one kind of material, a clean abstract puzzle.

## Feel variants

- **wrecking**: Big and destructive: towers that crash down, chain reactions, a score for the wreck.
- **clever**: Clever and calm: one exact answer found by a trick, a rope cut at the right moment.
- **golf**: Golf: a ball, a course of holes, strokes against par, slopes and walls to bank off.

## Choices that shape the pitch

- **What you do:** launch at a tower to knock it down (default) · cut, drop and swing things so they
  land in a goal · hit a ball into a hole in few strokes, golf or mini-golf · build a bridge from
  pieces that hold each other up.
- **Stakes:** a few shots per level, stars for fewer (default) · unlimited tries, a score for
  the best · par per hole over a round of holes.
- **What the player sees:** the whole level on one screen, `static` (default) · a view that
  follows the shot, `follow2d` · 3D behind the ball, `orbit`.
- **Feeling:** the player feels clever satisfaction by watching a tower fall exactly as planned,
  because the shot was aimed by eye and the physics did what they predicted.

## Later, never in a one-shot

- Real rope, vehicle and soft-body physics → not tested yet: ask for it after play and the AI will try it untested
- A level editor with a required clear before sharing → not tested yet: ask for it after play and the AI will try it untested
- Worlds of hand-made levels → grow it
- Shots with special powers, split or explode → change it after play
- Wind and moving targets → change it after play
- Best scores shared online → needs a server: not built yet
- Full 3D golf with clubs, lie and wind → add it as a feature

## In a mashup

The physics puzzle leads the shot, the physics and how a level is judged. Puzzle leads the level's
one idea and its teaching, and a recorded clear proves each level. A platformer half leads movement,
and the physics serves the level. A sandbox leads free building, and the goal becomes optional. A
sports half leads the ball and the score, mini-golf or a trick-shot contest.
