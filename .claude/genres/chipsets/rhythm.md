# Chipset: rhythm

The song in a one-shot is a tune the game makes from its own sounds: no recorded or licensed
music. These lines build on the timing rules of the audio clock.

**Camera:** `static`; `fixed` for a 3D note highway, `topdown` for moving on a grid to the beat.

## Card defaults

- **first-song-teaches**: The first song starts with single notes on the strong beats, then adds
  off-beats and holds, and ends on a burst. Why: the player learns the song's language within one
  song. Break it when: an expert chart for players who know the genre.
- **tap-to-calibrate**: A short tap test before the first song sets this device's delay, and the
  delay moves the judging, not only the sound. Why: TVs and wireless headphones add delay that would
  make every hit feel late. Break it when: the windows are so wide that a small delay cannot be
  felt.
- **combo-counter**: A combo count and the score sit beside the notes, and a miss resets the combo.
  Why: a streak becomes something to protect. Break it when: each short scene is graded pass or fail
  as a whole, with no running count.
- **song-results**: The song ends on a results screen with a grade, the accuracy and the best combo,
  and one key plays it again. Why: the player sees how they did and goes straight back in. Break it
  when: songs are stages of a story and the next one follows at once.

## Feel

- **song-clock**: Notes move toward a hit line by the song's own clock, never the frame count, and
  each press is judged at the moment it was made. Why: a note that looks on the beat is on the beat,
  all song long. Break it when: the beat only paces the world and no press is judged in time.
- **graded-hits**: Each press gets a grade by how close it was, perfect, good or miss, flashed at
  the hit line the instant you press. Why: the player sees how close they came and aims to do
  better. Break it when: a relaxed game for anyone, with wide windows and no grades.
- **music-swells**: A streak adds layers to the song, drums then bass then melody, and a miss drops
  one, each change on the bar line. Why: the soundtrack celebrates the player's run. Break it when:
  the song must play the same for everyone, one fixed track.

## Feel variants

- **strict**: Sharp and strict: tight windows, dense charts, a miss costs the whole combo.
- **groove**: Loose and groovy: wide windows, notes on the strong beats, a miss only dims the music.
- **beat-fight**: Fight on the beat: you move and strike on the beat, and enemies move to the music.

## Choices that shape the pitch

- **What you press:** notes down lanes on a few keys (default) · circles to click where they appear
  · moves on a grid on the beat, fighting monsters.
- **Failure:** a health bar that misses drain, ending the song early (default) · no failing,
  only a grade at the end · one miss ends it, a challenge mode.
- **The song:** one song made in the game (default) · a few short songs of rising difficulty · a
  beat that speeds up until you miss, an endless mode.
- **What the player sees:** lanes on a flat screen, `static` (default) · a 3D note highway,
  `fixed` · a grid seen from above, `topdown`.
- **Feeling:** the player feels in the groove by hitting a run of notes without thinking, because
  each press is judged against the song they hear and the music swells with the streak.

## Later, never in a one-shot

- A song editor and charting tool → not tested yet: ask for it after play and the AI will try it untested
- The player's own music, with notes found from its beats → not tested yet: ask for it after play and the AI will try it untested
- Licensed songs and a song list → grow it
- Leaderboards per song → needs a server: not built yet
- Haptics on each hit → not tested yet: ask for it after play and the AI will try it untested
- Drums, guitars or motion controllers → not tested yet: ask for it after play and the AI will try it untested
- Modifiers: faster notes, hidden notes → change it after play
- Two players on one keyboard, a versus song → change it after play

## In a mashup

Rhythm leads judgement timing and the music clock. Action leads responsive input and what a hit
does, and input is never held back to land on a beat. A roguelike leads the run, a dungeon moved
through on the beat. A story half leads the scenes between songs. A platformer half leads movement,
and the beat shapes only the hazards.
