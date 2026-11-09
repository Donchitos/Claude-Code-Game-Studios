// PROTOTYPE - NOT FOR PRODUCTION
// Question: @QUESTION@
// Date: @DATE@
// Every tuning value lives here, each with value, min, max and step. The game reads them live
// through tune.<name> (index.html); the tweak panel, an add-on, writes them back here.
window.CONFIG = {
  seed: 1, // every gameplay random call reads rng(), seeded from this (or ?seed= in the address)
  volume: { value: 0.5, min: 0, max: 1, step: 0.05 },
  // The game's values: speeds, costs, waves, timers, the challenge's ramp. Every number a
  // designer would tune, with its unit in the comment.
};
