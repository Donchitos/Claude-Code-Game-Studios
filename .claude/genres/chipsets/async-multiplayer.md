# Chipset: async-multiplayer

**Camera:** `static` for a board played by turns; `follow2d` or `chase` for a ghost race; `orbit`
for a world where others leave signs.
**Online:** The other players are simulated in this browser: two people pass one device, a bot
takes the other side's turns, or a ghost and signs are saved for "the next player". Sending turns,
ghosts and signs between machines, notifications and accounts need a server: not built yet.
**Research:** needs primary research: our research for this genre is about leaving help for other
players and thanking them. It has no entry for sending turns or ghosts between players, or for
replaying the other side's move when you return.

## Card defaults

- **stand-ins**: The others are played here: two people pass the device, with a cover screen between
  turns, or a bot takes the other side and leaves the ghosts and signs, and the game says it is a
  bot. Why: the whole loop can be tried by one person or two on one machine. Break it when: it is
  played only against your own earlier runs, with no other side.
- **saved-between**: Every turn, ghost and sign is saved the moment it is made, so the game can
  close and pick up later exactly where it was. Why: async play lives around the rest of the day.
  Break it when: the whole game is one sitting, a pass-the-device game on one evening.
- **since-you-left**: Back at the game, the first screen shows what changed while you were away: the
  other side's move, a new ghost time, thanks for a sign you left. Why: the other player's move is
  the news, and coming back has a reason. Break it when: turns follow each other at once on one
  device, with nothing to catch up on.

## Feel

- **no-rush**: A turn takes as long as you like, and being away never costs anything: the game waits
  and greets you back. Why: the player returns because they want to, never out of fear. Break it
  when: a fast game with a short clock on each turn, as the person asked.
- **thanks-back**: One key thanks a sign, a ghost or a good move, and a thank-you for your own
  greets you next time. Why: help is easy to give and is noticed. Break it when: the async play is a
  rivalry, a ghost to beat and nothing to be grateful for.

## Feel variants

- **turns**: Patient turns: a word or board game, one move each, at the pace of a day.
- **ghosts**: Ghost chase: race the ghost of an earlier run, yours or a bot's, and beat its time.
- **strangers**: Kind strangers: signs and ladders left by others help you through, and you leave
  your own for the next player.

## Choices that shape the pitch

- **What is shared:** turns in a word or board game (default) · a ghost of an earlier run to race ·
  signs and help left in the world for the next player.
- **Who stands in:** a bot plays the other side (default) · two people pass one device · your own
  earlier runs.
- **Signs:** picked from a short list of words, so each is useful and none is rude (default) · free
  text, for a game between friends only.
- **What the player sees:** a board, `static` (default) · a side view, `follow2d` · a 3D world,
  `orbit`.
- **Feeling:** the player feels camaraderie by finding a sign that saves them and leaving one back,
  because help is easy to give and the thanks come the next time.

## Later, never in a one-shot

- Turns, ghosts and signs sent between real players' machines → needs a server: not built yet
- A note when it is your turn, outside the game → needs a server: not built yet
- Accounts, friend lists and ghost leaderboards → needs a server: not built yet
- Help from other players at the ending → needs a server: not built yet
- Structures left by others that wear down and can be repaired → add it as a feature
- Reporting and hiding signs → needs a server: not built yet
- A daily puzzle that is the same for everyone → needs a server: not built yet

## In a mashup

Async play leads what is left for others, what is saved, and what a return shows. A word, board or
card game leads the rules of a turn. A racer or platformer leads the run, and async play leads the
ghost. An exploration or survival game leads the world, and async play leads the signs and what
others leave in it.
