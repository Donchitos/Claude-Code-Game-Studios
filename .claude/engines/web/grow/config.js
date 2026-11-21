// Every tuning value, from data/config.json: each with value, min, max and step.
// The game's code reads them through window.CONFIG, as the one-shot did, until
// the grow step's TypeScript move gives it imports (src/config.ts). The tweak
// panel is on the dev server only: no build has it.
import data from '../data/config.json';

window.CONFIG = data;
if (import.meta.env.DEV) await import('./dev/tune');
