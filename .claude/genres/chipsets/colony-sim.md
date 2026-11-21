# Chipset: colony-sim

There is no tested way to build deep simulation yet: a one-shot colony is a few colonists, one small
base and a day or two, with needs and moods kept few and readable, never a deep simulation.

**Camera:** `strategy`, flat from above with pan and zoom; `static` for a small base that fits
the window.

## Card defaults

- **named-colonists**: A few colonists, each with a name, a face and one or two traits that change
  how they act. Why: events happen to people the player knows, and that is where the stories come
  from. Break it when: the workers are a faceless swarm, an ant farm.
- **orders-not-steering**: You mark jobs, dig here, build that, carry this, and colonists take them
  by priority; the clock can be paused or sped up while you plan. Why: the player plans and the
  colony works, the heart of the genre. Break it when: one colonist is a hero you steer by hand, a
  survival game.
- **setbacks-not-endings**: A bad turn changes the game rather than ending it: the injured rest in
  bed, a burnt room is rebuilt, a lost fight costs supplies, and the run ends only when no one is
  left. Why: the colony's trouble is the story, not a reload. Break it when: the person asks for one
  life that ends the run.

## Feel

- **mood-with-reasons**: Each colonist's mood shows on them and lists its reasons, a good meal, a
  cold night, a friend hurt, each small and named. Why: the player reads how the colony feels and
  can act on it. Break it when: the workers are robots with no moods, a logistics colony.
- **watch-them-live**: Colonists walk to work, eat at the table, chat on breaks and sleep in their
  beds where you can watch, and clicking one shows what they are doing and why. Why: the colony runs
  on its own, and the cause of a problem is one click away. Break it when: the colony is run from
  reports.
- **stories-happen**: Small events start on their own, a quarrel between two who dislike each other,
  a breakdown at low mood, a stranger at the gate, and a log line names each one. Why: the colony
  writes its own stories, the reason the genre is played. Break it when: a calm build with no
  events.

## Feel variants

- **gentle**: Gentle: kind colonists, rare events, the slow build of a home.
- **harsh**: Harsh: raids, hunger and cold, a colony on the edge.
- **chaotic**: Chaotic: many events and odd traits, and the fun is in what goes wrong.

## Choices that shape the pitch

- **The setting:** a crash-landed crew on a strange world (default) · dwarves digging into a
  mountain · a base under the sea or in space, where air is the need.
- **The pressure:** a raid warned ahead, with time to prepare (default) · winter coming and food
  running short · none, a gentle build.
- **Stakes:** setbacks first, and the run ends when no one is left (default) · a goal to reach, a
  ship to build and leave on · none.
- **The map:** a small generated patch (default) · a hand-made one.
- **What the player sees:** flat from above with pan and zoom, `strategy` (default) · a small
  base that fits the window, `static`.
- **Feeling:** the player feels responsible for a few lives by planning around their moods and
  needs, because each colonist is named and the reasons for their mood are shown.

## Later, never in a one-shot

- Relationships, rivalries and gossip that spread → not tested yet: ask for it after play and the AI will try it untested
- Deep needs: temperature, air, sickness, wounds by body part → not tested yet: ask for it after play and the AI will try it untested
- A world map with several colonies → not tested yet: ask for it after play and the AI will try it untested
- Colonists who come back changed by what happened → not tested yet: ask for it after play and the AI will try it untested
- A storyteller that paces the events → add it as a feature
- Research and new buildings → grow it
- Trade with visitors and other settlements → add it as a feature

## In a mashup

The colony sim leads needs, moods and jobs. A city builder leads zones and roads when the colony
grows into a town. Survival-crafting leads one hero's hunger when the player steers a single
colonist. A tactics half leads the fight when a raid arrives. Management leads the money when the
colony trades.
