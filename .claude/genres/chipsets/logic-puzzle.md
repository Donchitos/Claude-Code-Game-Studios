# Chipset: logic-puzzle

**Camera:** `static`, the board fits the window.

## Card defaults

- **one-board-graded**: One board solved in minutes, picked from a few difficulties graded by the
  kind of reasoning each needs, not only by its size. Why: the player picks a challenge that fits.
  Break it when: a hand-made run of boards, each teaching one technique.
- **logic-alone**: The solver proves every board can be solved by reasoning alone from the first
  move: a mine board's first click is safe, and no guess is ever needed. Why: a loss is the player's
  slip, never a coin toss. Break it when: a clearly labelled lucky mode.

## Feel

- **mark-what-you-know**: One button fills a cell and another marks it surely empty, a drag marks a
  whole run at once, and cells are big enough to hit easily. Why: the player writes down each
  deduction and builds on it. Break it when: cells take numbers, not marks, and notes are small
  pencil numbers instead.
- **clues-answer**: A clue greys out once its row or region meets it, and a rule broken by your own
  marks, two of one number in a row, shows in red; whether a mark is right stays hidden until the
  board is done. Why: each deduction gets an answer without the game solving it for you. Break it
  when: the person wants a strict mode where nothing answers until the end.
- **undo-marks**: Undo takes marks back one at a time with no limit, restart clears the board, and a
  fatal click on a mine board can be undone once. Why: a slip never ruins a board half solved, so
  the player keeps reasoning. Break it when: a strict mode where a mine ends the board.
- **picture-reveal**: The last right cell finishes the board at once: the picture colours in, or the
  safe cells flip over in a wave, with a chime and the time taken. Why: a board of reasoning ends on
  a beat of payoff. Break it when: boards come back to back in a timed race, and the next one starts
  at once.

## Feel variants

- **relaxed**: Calm and gentle: no timer, broken rules shown in red, a hint on request.
- **strict**: Sharp and strict: a timer and best times, nothing confirmed until the whole board is
  done.

## Choices that shape the pitch

- **The puzzle:** picture logic, number clues on rows and columns (default) · mines, where a number
  counts the hidden mines next to it · number place, each number once per row, column and box · a
  logic grid of who-owns-what clues.
- **Boards:** generated each game and proven by the solver (default) · a hand-made set, each
  teaching one technique · a daily board, the same for everyone.
- **Feeling:** the player feels sharp and independent by proving a cell that no single clue names,
  because two clues together settle it and nothing pointed the way.

## Later, never in a one-shot

- Hints that point to the next deduction without giving it → change it after play
- Big boards in parts, and picture logic in colour → grow it
- Logic grids told as a whodunit, confirmed in batches → add it as a feature
- A campaign of hand-made boards → grow it
- Mixed rules on one board, or rules that change mid-board → add it as a feature
- Daily boards with times compared online → needs a server: not built yet

## In a mashup

Logic leads the board, the clues and the proof that no guess is needed. A mystery or detective half
leads the story, and a logic grid is its deduction, confirmed in batches. An adventure half leads
the world, and boards are its locks. A cozy half leads theme and pace. A roguelike half leads the
run, and what a solved board earns carries over.
