# Chipset: auto-battler

There is no tested way to build deep simulation yet: a one-shot uses a small roster with simple automatic
attacks and fixed opponent teams.

**Camera:** `static`, the board and shop fit the window; `strategy` for a wider battlefield.
**Online:** The first slice fights teams stored with the game. Live opponents, shared draft
pools and teams uploaded by other players need a server: not built yet.

## Card defaults

- **draft-then-watch**: Recruit a team between rounds, then let its units fight without attack
  inputs. Why: the fight tests the team the player chose. Break it when: the player steers a fighter
  during combat, an action game with automatic allies. [teamfighttactics-1]
- **shop-tradeoffs**: Buy units with a limited gold budget, so the opening shop asks what to leave
  behind. Why: buying everything removes the choice. Break it when: the roster is given and the
  whole puzzle is where to put it. [teamfighttactics-2]
- **formation-matters**: Arrange the team on the board before deploying it. Why: where a unit starts
  is part of the plan. Break it when: combat has no positions, only a collection of effects
  resolving in order. [mechabellum-1]
- **units-combine**: Give units abilities that work with other units in the roster. Why: the team
  offers combinations worth trying. Break it when: each unit is self-contained and the challenge is
  only its position. [superautopets-1]

## Feel

- **planning-breath**: Let the player finish shopping and arranging before starting combat, with no
  planning countdown. Why: the player can think through a change. Break it when: a shared round
  clock is part of the contest. [superautopets-2]
- **spells-read**: Give abilities visible effects that can be followed through the fight. Why:
  watching explains which part of the team worked. Break it when: combat is deliberately reduced to
  a text report. [teamfighttactics-3]
- **inspect-a-unit**: Selecting a unit opens its ability and traits while planning. Why: the player
  can check the rules behind a combination. Break it when: the roster is so plain that each unit's
  full rules already fit beside it. [teamfighttactics-4]

## Feel variants

- **planner**: Calm planner: untimed preparation, then watch the formation do its work.
  [superautopets-2], [mechabellum-1]
- **combo**: Clever combinations: recruit units for how their abilities work together.
  [superautopets-1]

## Choices that shape the pitch

- **The team:** units bought between rounds (default) · a fixed roster to arrange · items on
  a board that fight through their effects.
- **Positions:** a board with a front and back (default) · an ordered line · a wide field of
  squads, with the simulation built later.
- **Stakes:** a short run against stored teams (default) · an isolated formation puzzle · a
  contest against live players, later.
- **What the player sees:** board and shop together, `static` (default) · an angled battlefield
  with pan and zoom, `strategy`.
- **Feeling:** the player feels clever by choosing a team whose abilities work together, then seeing
  that combination win the fight, because the fight shows each ability in the order it goes off
  ([superautopets-1]).

## Later, never in a one-shot

- A larger roster and more opponent teams → grow it
- Equipment crafting and branching unit upgrades → add it as a feature
- Interest, streak income and a shared shop pool → add it as a feature
- Faster combat playback → change it after play
- Large armies with autonomous pathfinding → not tested yet: ask for it after play and the AI will try it untested
- Live matches, ranking and uploaded opponent teams → needs a server: not built yet

## In a mashup

The auto-battler leads recruiting, placement and automatic fights. A roguelike leads the run
and its rewards. A creature collector leads who joins the roster and how they grow. A card
half leads the offers in the shop. An economy half leads income and prices; combat still tests
what the player bought and where they put it.
