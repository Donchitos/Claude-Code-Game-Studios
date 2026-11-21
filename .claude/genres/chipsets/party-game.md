# Chipset: party-game

**Camera:** `static`, one arena that fits the window; `follow2d` for a wider stage, zoomed to keep
every player on screen.
**Online:** Everyone plays on one screen, on one keyboard or on gamepads, and bots take any empty
seat so one person can try it alone. Friends on other machines, lobbies and matchmaking
need a server: not built yet.
**Research:** needs primary research: our research has party entries on slapstick bodies, catch-up
for whoever trails, a job split between players, and voice. It has no entry for microgames, for
players joining on one screen, or for a board between rounds.

## Card defaults

- **press-to-join**: On the title screen each player joins by pressing a key or a gamepad button,
  and bots fill the empty seats. Why: the game starts in seconds with whoever is in the room, and
  one person can still play. Break it when: the game is made for exactly two people on one keyboard,
  with no seats to fill.
- **short-rounds**: Each round opens with its goal in a word or two, big in the middle, and ends on
  a scoreboard; the first to a few round wins takes the match. Why: a loss is over fast, and
  everyone is back in at once. Break it when: it is one long free-for-all to play around in, with no
  score.
- **trailing-help**: Whoever is last gets a small boost or a better pickup in the next round. Why:
  nobody falls so far behind that they stop trying. Break it when: the person wants a pure contest,
  the best player always wins.

## Feel

- **slapstick-bodies**: Bodies are a little floppy: shoves, bumps and falls knock players about, and
  getting back up is quick. Why: a mistake is funny to watch, and nobody sits out for long. Break it
  when: the game is a quiz or a reaction test with no bodies on screen.
- **own-colour**: Every player has a bright colour and a marker over their head, kept through a
  pile-up and on the scoreboard. Why: in the chaos everyone finds themselves at a glance. Break it
  when: all the players steer one shared thing together.
- **winner-moment**: The round's winner gets a beat: a short freeze, a cheer in their colour, and
  their points ticking up. Why: the whole room sees who won and laughs or groans together. Break it
  when: rounds flow straight into each other with no pause, a non-stop brawl.

## Feel variants

- **slapstick**: Floppy and physical: wobbly bodies, shoves and falls that get a laugh.
- **quickfire**: Quick-fire: tiny games of a few seconds each, one after another, getting faster.
- **cutthroat**: Sly and cutthroat: points can be stolen from the leader, and a late round is worth
  more.

## Choices that shape the pitch

- **Format:** one arena, a new short round each time (default) · a string of tiny microgames,
  faster and faster · a board you move around, with a minigame after each turn.
- **Sides:** each for themselves (default) · two teams · everyone against one player.
- **Who plays:** friends on one keyboard or gamepads, bots in the empty seats (default) · one person
  against bots only.
- **What the player sees:** one arena, `static` (default) · a wider stage that zooms to fit
  everyone, `follow2d` · a 3D arena seen from one angle, `fixed`.
- **Feeling:** the player feels shared laughter by knocking a friend off the edge a moment before
  falling off too, because bodies react the same way every time and the next round is seconds away.

## Later, never in a one-shot

- Friends on other machines, lobbies and matchmaking → needs a server: not built yet
- Voice chat through the game, voices that change when a player is in trouble
  → needs a server: not built yet
- Full ragdoll bodies driven by motors → not tested yet: ask for it after play and the AI will try it untested
- Bots that learn each minigame and play like people → not tested yet: ask for it after play and the AI will try it untested
- A board with dozens of minigames → grow it
- Hats and costumes to unlock → change it after play
- An arena editor to build and play in together → not tested yet: ask for it after play and the AI will try it untested

## In a mashup

The party game leads joining, the rounds, the scoreboard and the bots. A platformer leads movement
inside each round. Racing leads handling, and the party game leads the help for whoever trails and
the score across races. Sports leads the field and its scoring. Fighting leads the moves when the
party brawls. A co-op half leads the shared goal when everyone plays against the game, and the party
game keeps the rounds short and the mistakes funny.
