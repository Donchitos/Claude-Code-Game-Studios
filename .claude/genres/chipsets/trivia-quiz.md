# Chipset: trivia-quiz

There is no tested way to build large authored content yet: a one-shot uses a short, prepared set of questions
with checked answers.

**Camera:** `static`, the question and answer choices fill the screen.
**Online:** The first slice is a quiz on one screen, played alone or by friends taking turns.
Phone controllers, remote contestants and hosted live shows need a server: not built yet.

## Card defaults

- **choose-an-answer**: Present a question with answer alternatives to choose from. Why: the player
  can answer by recognising the fact, without a typing test. Break it when: recalling the answer
  without prompts is the challenge. [kahoot-1]
- **time-to-think**: Give each question an answer timer suited to its complexity. Why: a harder
  question needs room for thought. Break it when: the pitch is an untimed practice quiz. [kahoot-2]

## Feel

- **answer-reveal**: Show the correct answer after the question resolves. Why: uncertainty turns
  into confirmation or something learned. Break it when: answers stay hidden until a connected set
  of questions is finished. [kahoot-3]
- **answer-sounds**: Use distinct sounds for correct and incorrect answers, with a sound toggle.
  Why: the result is heard as well as read. Break it when: the quiz is deliberately silent.
  [kahoot-4]
- **finish-with-score**: End the quiz on the player's final score. Why: the session has a clear
  result to react to. Break it when: the quiz is for practice without scoring. [kahoot-5]

## Feel variants

- **quickfire**: Quick recall: an answer clock keeps each question moving toward its reveal.
  [kahoot-2], [kahoot-3]
- **reflective**: Thoughtful recall: remove the timer and give the player time to consider the
  alternatives. [kahoot-6]

## Choices that shape the pitch

- **Answering:** choose from written options (default) · type an answer · buzz in before
  local opponents.
- **Who plays:** play alone (default) · local players take turns · local teams discuss an
  answer · remote players, later.
- **Stakes:** a score at the end (default) · practice without points · wrong answers lead to
  a separate minigame, later.
- **Tone:** a plain quiz (default) · a comic host · a themed game show.
- **Feeling:** the player feels capable by recalling an answer before the reveal confirms it
  ([kahoot-3]).

## Later, never in a one-shot

- More topics, difficulty bands and fresh question sets → grow it
- Local buzzers and team turns → change it after play
- Spoken hosting and jokes tied to answers → grow it
- Typed answers with spelling and phrasing alternatives → add it as a feature
- Elimination minigames and a comeback finale → add it as a feature
- Phone controllers, remote matches and live shows → needs a server: not built yet

## In a mashup

The quiz leads questions, accepted answers and the reveal. A party half leads joining and
round scores. A horror half leads the host and consequences. An adventure half supplies places
and topics. A word half leads spelling when answers are typed; factual knowledge and spelling
need separate rules so the player knows what the question tests.
