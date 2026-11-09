# Chipset: competitive-multiplayer

**Camera:** `static`, one arena that fits the window with every player on it; `chase` for a car
ball game; `first` for an arena shooter against bots.
**Online:** Two players face off on one screen, on one keyboard or on gamepads, or one player
takes on bots that stand in for people. Matches between machines, netcode and rollback,
matchmaking, ranks and anti-cheat need a server: not built yet.

## Card defaults

- **bot-rivals**: Bots take the other seats at a level picked on the title screen: they react after
  a human delay, miss sometimes, and never see through walls. Why: one person gets a real match, and
  the bots feel like people. Break it when: the game is made only for two friends at one keyboard.
- **first-to-score**: A match is first to a few points, or the most when the clock runs out, with
  the score always on screen; it ends on the winner and a rematch is one key away. Why: every point
  is a moment, and losing leads straight to another try. Break it when: one long match with no
  score, a hunt that ends when one side is caught.
- **fair-arena**: A mirrored arena with loops and cover, everyone starting equal, and a respawn far
  from whoever got the kill. Why: a win comes from playing better, never from where you started.
  Break it when: it is uneven on purpose, one hunter against many.

## Feel

- **who-hit-who**: Every hit says who landed it: the hitter's colour flashes, a kill has its own
  sound, and a line in the corner names both players. Why: a death is a lesson, never a mystery.
  Break it when: players hide from each other, and not knowing who is near is the game.
- **dodge-and-punish**: One quick dodge or dash beats an attack when timed right and leaves the
  attacker open for a moment. Why: the better player wins exchanges, not only the faster trigger.
  Break it when: a car or ball game, where movement itself is the skill.
- **match-point**: When someone is one point from winning, the screen says so and the music rises,
  and the winning point lands with a flourish. Why: the end of a close match is its best moment, and
  everyone feels it coming. Break it when: the match ends on a clock, where the final seconds count
  down instead.

## Feel variants

- **arena**: Fast and frantic: quick movement, short respawns, a scramble for pickups.
- **duel**: Tense and tactical: one life a round, every hit counts, careful footing.
- **sport**: A ball and two goals: everyone chases one ball, and physics carries the play.

## Choices that shape the pitch

- **Opponents:** bots at a picked level (default) · a friend on the same keyboard or a gamepad · two
  against two, friends and bots mixed.
- **Format:** first to a few points (default) · one life a round, best of a few rounds · a ball and
  two goals.
- **Arena:** one mirrored arena with loops (default) · a few small arenas in turn · a new arena each
  round.
- **What the player sees:** one arena, `static` (default) · from above, `topdown` · behind a car,
  `chase` · first person against bots, `first`.
- **Feeling:** the player feels sharp mastery by out-dodging a rival and taking the last point,
  because every hit was readable and both sides played by the same rules.

## Later, never in a one-shot

- Matches between machines, with rollback or lag compensation
  → needs a server: not built yet
- Matchmaking, ranks and seasons
  → needs a server: not built yet
- Anti-cheat → needs a server: not built yet
- Bots that learn and adapt like people → not tested yet: ask for it after play and the AI will try it untested
- Aim help for gamepads → change it after play
- Characters with their own strengths, kept fair → grow it
- Replays and a kill cam → add it as a feature
- Something to play while waiting for the next match → change it after play

## In a mashup

Competitive play leads the match: the score, the fair start, the respawns and the bots. Fighting
leads the moves and blocking in a duel. A shooter leads aiming and weapons. Racing leads handling,
and competitive play leads the match format. Sports leads the field and its rules. A party game
leads the rounds and the laughs when the pitch is for a room of friends.
