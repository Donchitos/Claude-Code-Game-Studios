# Chipset: word-game

There is no tested way to build large authored content yet: a one-shot uses a small prepared letter set and an
explicit list of accepted words.

**Camera:** `static`, the letters and the current word fit the window.

## Card defaults

- **letters-to-words**: Give the player a prepared bank of letters and ask them to find words made
  from it. Why: the same letters can reveal fresh possibilities. Break it when: the goal is to guess
  a hidden word from feedback on earlier guesses. [spellingbee-1]
- **known-word-rules**: Check submissions against the chosen word list, and accept each word only
  once in the puzzle. Why: success comes from finding something new under consistent rules. Break it
  when: the game deliberately allows repeated words on a changing board. [letterpress-1],
  [letterpress-2]

## Feel

- **rejection-explained**: When a word cannot be played, let the player see why. Why: a rejected
  word teaches the rule instead of feeling arbitrary. Break it when: dictionary challenges are a
  deliberate part of a contest between players. [letterpress-3]
- **fresh-arrangement**: Let the player shuffle the letter bank to see it in a different order. Why:
  a fresh arrangement can suggest another word. Break it when: letter positions are part of the
  puzzle, such as connected paths or captured territory. [wordwheel-1]
- **word-means-something**: Selecting a played word shows its definition. Why: an unfamiliar
  accepted word becomes something the player can learn. Break it when: the puzzle uses an invented
  language and discovering meanings is the goal. [letterpress-4]

## Feel variants

- **discovery**: Word discovery: turn the letter bank around and look for fresh combinations.
  [spellingbee-1], [wordwheel-1]
- **learning**: Curious learning: explain rejected words and offer meanings for accepted ones.
  [letterpress-3], [letterpress-4]

## Choices that shape the pitch

- **The puzzle:** find words in a letter bank (default) · guess a hidden word · trace connected
  letters · place words across a shared board.
- **Word rules:** a prepared accepted list (default) · a broader dictionary · a themed list
  with its restrictions explained.
- **Goal:** find as many different words as you can (default; [spellingbee-1]) · uncover the
  hidden answer · score more than a local opponent.
- **What the player sees:** letters and an entry area, `static` (default) · a board of tiles
  whose positions constrain the words.
- **Feeling:** the player feels a small spark of discovery by seeing a new word in letters
  they have stared at for a while, often just after a shuffle ([spellingbee-1], [wordwheel-1]).

## Later, never in a one-shot

- More prepared puzzles and themed word lists → grow it
- A generator that checks playable words before offering letters → add it as a feature
- A shared board with letter values and placement bonuses → add it as a feature
- A local opponent that chooses words from the same dictionary → add it as a feature
- A faster way to edit the current word → change it after play
- Daily puzzles with shared scores → needs a server: not built yet
- Remote opponents → needs a server: not built yet

## In a mashup

The word game leads which letters make a legal word. A puzzle half leads paths and placement
on the board. An RPG half turns accepted words into actions while keeping word validation
consistent. A party half leads turns and scoring. A story half supplies a theme for the word
list; it must explain any restrictions that differ from ordinary word play.
