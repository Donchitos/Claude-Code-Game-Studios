# Chipset: arcade-sports

Our research has no entries on a sport's own rules or opponents: its sports lines are timing, input
and impact feel, so the match and the AI lean on those and on racing's catch-up entries. There is no
tested way to build opponents that act in real time yet: the AI side is simple, chasing the ball and
playing the same moves as you.

**Camera:** `static` when the whole court or pitch fits; `follow2d` for a side view that scrolls
with the ball, `fixed` for a 3D court.

## Card defaults

- **short-match**: A match is short, first to a few points or a short clock, with the score and the
  time big on screen, then a results screen. Why: a match is one sitting, and the score says who is
  winning at a glance. Break it when: a season or a league is the point.
- **catch-up**: Whoever trails gets a small boost they can see, a hotter shot or a quicker player,
  which ends when the score is level. Why: the match stays a match to the final whistle. Break it
  when: the person wants a strict, even contest, a duel of pure skill.

## Feel

- **sweet-spot**: A hit or shot timed to the right moment goes stronger and straighter, and the
  moment shows as the ball meets the hand, foot or racket. Why: timing wins points, not button
  mashing. Break it when: the sport has no timed hit, a game of running and tackling.
- **buffered-actions**: A pass or shot pressed a moment early fires when the ball arrives, and a
  block or dive pressed near the right moment counts. Why: the player's intent wins, not an exact
  frame. Break it when: exact timing is the whole challenge, a hardcore sim.
- **power-shot**: Holding the button charges a power shot that glows and hums, and letting go sends
  the ball fast with a trail and a whoosh. Why: the big exaggerated shot is what makes it arcade.
  Break it when: the person wants a grounded sim, every shot realistic.
- **instant-pose**: A press snaps the player straight into the swing, jump or dive, before the rest
  of the move plays out. Why: the press is seen at once, so a late hit is the player's timing, not
  the game's. Break it when: slow floppy bodies are the joke, a physics sport.

## Feel variants

- **flowing**: Flowing: passes and moves link into one long play, a combo you keep alive.
- **duel**: Tight duel: one against one, reads and counters, every shot answered.
- **slapstick**: Floppy and silly: tackles that send players tumbling, a ball that surprises.

## Choices that shape the pitch

- **The sport:** a ball over a net, tennis or volleyball (default) · a goal at each end,
  football or basketball, a few players a side · a made-up sport with one strange rule.
- **Players:** you against the AI (default) · two on one keyboard or two gamepads (local
  co-op) · two of you against the AI.
- **What the player sees:** the whole court at once, `static` (default) · a side view that
  follows the ball, `follow2d` · a 3D court from a set angle, `fixed`.
- **Feeling:** the player feels kinetic flow by stringing passes and shots into one play, because
  each press lands at once and a well-timed hit pays off.

## Later, never in a one-shot

- Real teams, leagues and seasons → grow it
- Ranked online matches → needs a server: not built yet
- Teammates who play positions and tactics → not tested yet: ask for it after play and the AI will try it untested
- Bodies that tumble and get up with physics → not tested yet: ask for it after play and the AI will try it untested
- A commentator → grow it
- Players who improve with practice → add it as a feature
- A replay of a great point → change it after play

## In a mashup

Sports leads scoring, the field and the match clock. Fighting leads command reads, recovery and
defence, and any help for one side is the same for both and shown. Racing leads catch-up, and it
ends when the score is level. A party game leads silly rules between matches. An RPG half leads
players who grow between matches.
