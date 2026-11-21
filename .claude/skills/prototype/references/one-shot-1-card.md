# /prototype — One-shot 1: The questions and the brief

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

A good brief is what makes a one-shot work: built from a vague one, the game is thin whatever
the effort. So the one-shot asks one round of questions drawn from the genre's sheet, writes the
brief from the answers, and shows it. **The brief is the card:** **Build it** is the person's
yes to everything this route writes; nothing is built or written before it.

**In this file:** 1 What to build from · 2 Match the genres · 3 Ask · 4 Write the brief · 5 Show
the brief · 6 On Build it

## 1. What to build from

- **A brief** (`design/game-brief.md`): read it by section. It is the source of truth. Its "In
  your words" section, when it has one, is never rewritten. A brief from before 1.3.0 has MVP
  for Features, Label and Art direction for Look and references, and Reference game for Games
  you love / don't. Ask only what it leaves open of section 3's questions, and fill its missing
  Look and references, First minute and Challenge sections from the answers.
- **A brief for another game:** when the person describes a game that is not the brief's (another
  pitch, not a change to it), build from their words as with no brief.
  The new brief takes `design/game-brief.md` only when the old one is safe as the same text in
  `prototypes/<its name>/brief.md`; otherwise the new one lives in `prototypes/<name>/brief.md`
  alone and `design/game-brief.md` stays as it is.
- **No brief:** the person's words are what they typed, word for word: the text after the skill
  name when they started the skill themselves; with nothing after it, what they wrote about the
  game earlier in this conversation (an answer to `/start`, say); otherwise their whole message
  that asked for the game. The skill's arguments, when it was started for them, are a summary,
  never their words.
- **A pivot note:** a `PIVOT-NOTE.md` in the folder of the game they just changed direction
  from: what to keep goes on the new brief's In your words, what to change on Avoid, and say
  in one line that you used it.
- **A longer concept doc or GDD named:** pull the brief's fields out of it. The build never gets
  the whole document: it pushes the build to make everything at once.
- **Nobody there** (the autonomous automation mode): ask no question; every question takes its
  default, *provisional*. A run with no question tool is not nobody there: it asks in plain text
  as anywhere else, and Build it as a numbered list.

**Their references.** The project's `references/` folder holds what the person likes: images,
screenshots, UI and sounds they dropped in, and its `notes.md`, a line per file or clip
link saying what to take, what to avoid, or `use` (their own file, for the game). Read it
before the questions:

- **Images:** look at each one, at most eight: those `notes.md` names first, then the newest.
  When they want a picture's colours, the brief's Look line names them, with their roles.
- **Sounds and clip links:** you cannot hear or watch them, so use the name and the note only,
  and never open a link.
- **A file with no line** is still a reference: take what it plainly shows.
- **An image they paste** with their ask or answers is a reference too: use it from the chat
  now; it is saved into the folder on Build it.
- **No folder, or nothing in it,** changes nothing: no line names it, no question asks for
  it, and no folder is made.

**Who wins when sources disagree:** Avoid first, then the person's words, then their
references, then the sheet's defaults. A default fills only what was left unsaid and never
corrects a deliberate choice. **Removals are Avoid lines:** every removal in their words ("no
combat", "no waiting") becomes an Avoid line, and every fill respects it. **A twist beats its
reference only where they clash:** "like Slay the Spire, but the cards are dice" drops only what
dice contradict.

## 2. Match the genres

Each row under `chipsets:` in `.claude/genres/chipsets.yaml` is a genre, matched by meaning on
its name, `is` and `matches` lines and never shown as a menu. Match every genre in the person's
words: "a Pokémon-like with auto-battles" is creature-collector and auto-battler. Read the sheet of
each match, `.claude/genres/chipsets/<name>.md`, and no other. A sheet holds what the
questions and the brief draw on:

| Sheet part | Gives |
|---|---|
| Choices that shape the pitch | The questions: each is already a choice with a default |
| Feel variants | The "how should it feel" question |
| Card defaults and Feel | The genre's staples: the brief's Features, kept unless the person said otherwise |
| Later, never in a one-shot | Out of scope lines, each with its step |
| In a mashup | Which parent leads each system |
| Camera, Online | The Look's camera, and the stand-in for online play |

A sheet whose `**Research:**` line says it needs primary research has few lines: use what it
has, never add your own in its place. **No sheet fits:** don't force the nearest; ask the
questions from the genre as its best games play it, and say so in one line. **Their own
design** ("my own design", "skip the defaults"): read no sheet and take no staple.

**A mashup** (two or more genres) asks from each parent's sheet and combines by system: read
`.claude/genres/mashups.md` and name on the brief's Leads line which genre leads each system
(input and camera, death and saving, progression and economy, rules); the person's words lead
first. A parent's staple about a system the other leads is left out.

## 3. Ask

**One round, at most about eight questions, all in one message,** numbered, in plain words, each
with the default marked "(usual)":

1. **The sheet's Choices that shape the pitch** their words leave open, each as the sheet gives
   it: "Where do units stand: a board with a front and back (usual), an ordered line, or a wide
   field?"
2. **How it feels,** from the Feel variants, in a few words each: "calm planning (usual), or
   clever combinations?"
3. **How it looks,** for the Look and references section: the view and camera (the sheet's
   Camera line is the usual), and games or pictures whose look they like: "paste a screenshot
   or two, or drop them in references/". With no look in their words, offer two directions from
   `.claude/genres/art-direction.md` for this genre, the nearer one usual.
4. **How hard,** for the Challenge section: when trouble should first come and what a loss
   costs, with the genre's usual ("a real fight by the third wave; a loss restarts the level
   (usual)").
5. **The goal,** when their words have no win or end: "beat the gym leader (usual)".
6. **A slice or a quick test,** asked once, last: "A slice of the game: a short session from
   start to finish (usual), or a quick test of one mechanic, like how the jump feels?" It
   counts in the eight. Their words may settle it ("just test the grapple" is a quick test);
   then it is not asked. A quick test goes to Spike Mode (`references/spike-mode.md`) with the
   mechanic in their words as its question: no brief is written here. A spending limit on the
   session (a budget Claude Code shows, a cap the person set) is never said to them, or used to
   pick a slice or a quick test, or an effort for them:
   ask the question as it stands.

Ask only what their words and references leave open; ask none when they cover it all. Open the
message with: "A few questions so the game comes out the way you want. Answer any, skip any, or
say 'you pick' and I'll take the usual." Use no question tool here: the answers are their own
words. They may answer in a paragraph or more: take it as it is. **There is never a second
round:** what is still open, skipped or "you pick" takes the default, *provisional* on the
brief.

**A vague idea gets pitches first.** When their words name a genre or a game and little more ("a
game like Pokémon", "a racing game"), the message opens with two or three pitches, numbered, each
one line: what you do, how you lose, what you see, and the feeling. Each picks differently among
the sheet's Choices and Feel variants, and the first takes the defaults throughout. It is still
the one round: a pitch's number, a mix or their own idea answers the questions the pitch covers,
and "you pick" takes the first, *provisional*. An idea that already has a hook gets no pitches.
**No idea at all** ("make me a game", "surprise me", or nothing): the same, with three pitches
from three different genres, the first a popular one, each from its genre's sheet. Ask only the
questions no pitch answers; the picked pitch's sheet gives the defaults for the rest.

**None of these.** When they turn every pitch down ("none of these", "neither") and give no idea
of their own, offer two or three new pitches, numbered as before, each unlike the ones turned
down, and nothing else: their other answers stand. What they said against the old ones ("too
slow", "no shooting") goes on Avoid in their words, and the new pitches respect it. It is still
the one round: no question is asked again.

**Online play, VR, a phone or a console** in their words: read
`.claude/genres/online-and-devices.md` and say in one line what this build makes instead (the
sheet's Online line picks the stand-in); it goes on Out of scope. Never a server, unless they ask
for LAN play by name. **Never a terminal program** unless they ask for one by name.

## 4. Write the brief

Fill `.claude/docs/templates/game-brief.md` (`SKILL.md` names it) from their words, their
answers and the sheets, every field the template has. Shape it like a hand-written brief: one
screen, concrete, in this game's words. Mark each field you filled *(guessed)*, *(inferred
(strong))* or *(provisional)* for a default taken; unmarked means they said it. A default taken
because a question was skipped, left open or answered "you pick" is *(provisional)*, never
*(guessed)*: *(guessed)* is for a field nobody asked about.

- **In your words:** their words exactly as typed, then each answer after its number and a short
  name ("3. Look: like Pokémon Black and White"). Every look, view and reference word in them
  ("2.5D", "flat vector", "like Manor Lords") is built as written.
- **Look and references:** the look in words (the view, the camera, the shapes, the palette with
  its roles, one signature detail), written as `art-direction.md` says: their named look built
  as named, never the flat cream background with bare shapes. Then each reference game with what
  it gives, and each `references/` file drawn on, by name (the build reads those). Then "every figure drawn, no emoji, no plain circles". A mashup's look reads as both
  parents.
- **First minute:** what the player sees and does in the first 60 seconds, step by step, taught
  by doing, ending on the first moment the hook pays off. From the sheet's Feel lines and how the
  genre's best games open. A mashup's ends on the seam, where one parent's verb changes the
  other's system (`mashups.md`).
- **Challenge:** when the first real trouble comes (a minute range or a wave), what it is, what a
  loss costs and what grows later. From their answer and the genre's best games: never trivially
  easy, never a wall in the first minute.
- **Features:** the slice's parts, then the genre's staples (the sheet's Card defaults and Feel
  lines nearest the hook, in this game's words, never an id), all `[ ]`. A combat genre with a
  `variety:` floor in `chipsets.yaml` names it: "4 enemy kinds, each attacking differently".
  A system Your systems marks `thin stand-in` goes on Features only as its stand-in, ending
  `(thin stand-in)`, and one marked `later` not at all: the mark decides how deep it is built.
- **Your systems:** every system in their words and answers (a shop, crafting, day and night,
  weather), one a line in their words, each with one mark in the template's format: `in the
  slice` when the slice cannot play from start to end without it (the hook always is), `thin
  stand-in` when the slice touches it, `later` for the rest, which Out of scope also gets with
  its step. A mark they did not say ends *(guessed)*. A systemic idea's Skeleton line names the
  same systems. They named none: leave the section out.
- **Out of scope:** only the sheet's Later lines marked `grow it`, `add it as a feature`, `change
  it after play` or `needs a server`, with their step (`- a career of cups: grow it`); lines marked
  `not tested yet` stay off the brief. Then what online or a device asked for, with what is built
  instead.
- **Core loop:** a bullet a step: what the player does, what it changes, what they gain, how it
  repeats or fails, how they start again. A mashup's Leads line goes under it.
- **Build order:** step 1 is the slice: one tight, complete short session with the goal and the
  way to lose. A systemic idea (four or more systems that each talk to two others) builds the
  core action for real and every other system as a thin stub wired to the others; the Skeleton
  line under Core loop names each.
- **Intent:** only the person's words (*you said*), a named reference (from <reference>), or, for
  a "you pick" goal or failure, *no goal to reach* or *soft or no failure* (*provisional*). Its
  entries: *no goal to reach* · *soft or no failure* · *payoff builds* · *staged failure* ·
  *needs N players* · *outside the window*. Often empty.
- **A game they ask to copy** ("make X", "a clone of X", "X with the same UI", "X's
  characters"): never build the copy. Ask one question first: "An original game in the genre of
  X, or X with your own twist?", build what they pick, and Avoid gets "X's name, art, characters
  and UI". A new name or an "original" label does not change this rule. A game named as a
  reference ("a city builder like Manor Lords", "like Dark Souls") needs no question.

## 5. Show the brief

Show the whole brief, then these lines under it:

```text
Effort: this session's · "build it at medium" is cheaper and quicker, with a thinner game
Engine: web (<mark>) · Your goal: <goal> (<mark>)
Model: <the model you run on> · the one-shot is tuned on Opus: /model switches before Build it
Guessed: <each field you filled, in a few words>
Writes: design/game-brief.md, prototypes/<name>/
```

- **Effort** is this session's: the session builds the game itself (the build file says how),
  and high makes the deepest game. Before writing the line, run `printenv
  CLAUDE_CODE_EFFORT_LEVEL` in a shell (no output means it is unset). A value printed fixes this
  session's effort and every agent's, and the line reads `Effort: set by CLAUDE_CODE_EFFORT_LEVEL
  outside Claude Code Game Studios (change it there for another)`.
- **No price or time.** The brief names no cost and no minutes, and nothing before Build it
  estimates them; asked, say it depends on the game's size and the effort.
- **A lower effort only when the person names one** ("build it at medium"); xhigh too, and
  never offer max. An answer that leaves it to you ("medium is fine if it's cheaper, you pick")
  keeps this session's, and the reply says the trade in one line: "Keeping this session's effort: a lower one is cheaper and quicker, and makes thinner games." Their named pick goes on
  the line as `Effort: <it> (on a builder)` and a builder runs the build at it; with no Agent
  tool, or one with no `effort` input, the line says `Effort: this session's (type /effort <it>
  before Build it)`.
- **Engine** is web: *you said* when `engine.name: Web` is set or they asked for the browser,
  otherwise *guessed*. An engine asked for with none set: `Engine: web now; <engine> after
  you've played it`, and `/setup-engine` is the handover's Next line.
- **Your goal** is one of jam, learn, hobby, portfolio, sell, early_access, publisher, mobile or
  other: `project.goal` when it is set, otherwise from their words, otherwise hobby (*guessed*).
- **Model** shows only off Opus (Sonnet, Haiku or another vendor's).
- **Writes** names `design/game-brief.md` only when there is no brief yet; with one, it is
  `Writes: design/game-brief.md (its new sections), prototypes/<name>/`. Beside a brief for
  another game (section 1) it says which way: `Writes: design/game-brief.md (<old title>'s stays
  in prototypes/<its name>/brief.md), prototypes/<name>/`, or `Writes: prototypes/<name>/
  (design/game-brief.md stays <old title>'s)`. With pasted images to save, it names
  `references/` too.

Ask with the question tool: "Build this?" Options: Build it / Change something.

- **Change something:** ask what to change, then show the brief again. A change is the person's
  words: unmarked on the brief.
- Only an explicit Build it goes on. In the autonomous automation mode, log the brief as the
  decision and go on.

## 6. On Build it

1. **The folder name:** the title in lower case, hyphens for spaces, at most 40 characters.
   When `prototypes/<name>/` already exists, ask: carry on with that game, or start a new one
   beside it under another name.
   - **Carry on with that game:** write nothing of this brief. That game is the one they mean,
     and what they asked is a change to it: One-shot 4, with their words.
   - **A new one beside it:** the name with `-2` (or the next number free), said in one line.
2. **Write the brief** to `design/game-brief.md` as shown, Keep empty. A brief that lives in
   `prototypes/<name>/brief.md` alone (section 1) is written there after `one-shot-new.sh` made
   the folder (One-shot 2, section 1), never before: the script refuses a folder already there.
3. **Pasted images:** run `bash .claude/scripts/references-save.sh <N> [<N> ...]`, each N the
   number of an image the person pasted as a reference (`[Image #N]`). For each `saved` row,
   add `- <file>: take: <what they said of it>` to the `notes.md` beside it, or the file name
   alone when they said nothing of it. A `missing` or `not_assessed` row: say in one line that
   it was not saved and why, ask them to drop the file into `references/` to keep it, and build
   from what you saw. It never holds the build up.
4. Go on to One-shot 2.
