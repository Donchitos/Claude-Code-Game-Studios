// Vitest: the rules in src/game/, run in Node with no browser.
import { describe, expect, it } from 'vitest';
import config from '../../data/config.json';
import { FIELD, STEP, makeRng, newState, update } from '../../src/game/rules';

const tuning = { speed: config.speed.value };

describe('makeRng', () => {
  it('repeats the same numbers for the same seed', () => {
    const a = makeRng(7), b = makeRng(7);
    const first = [a(), a(), a()];
    expect([b(), b(), b()]).toEqual(first);
    expect(first.every(n => n >= 0 && n < 1)).toBe(true);
  });
});

describe('update', () => {
  it('moves the square by its speed in one second', () => {
    const s = newState(), x0 = s.x;
    for (let i = 0; i < 60; i++) update(s, { dx: 1, dy: 0 }, tuning, STEP);
    expect(s.x - x0).toBeCloseTo(tuning.speed, 6);
    expect(s.t).toBeCloseTo(1, 6);
  });

  it('keeps the square inside the field', () => {
    const s = newState();
    for (let i = 0; i < 600; i++) update(s, { dx: -1, dy: 1 }, tuning, STEP);
    expect(s.x).toBe(0);
    expect(s.y).toBe(FIELD.h - FIELD.size);
  });
});
