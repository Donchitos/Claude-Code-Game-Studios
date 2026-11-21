// The tweak panel, on the dev server only: src/config.ts loads it behind
// import.meta.env.DEV, so `npm run dev` has it and no build does. The backquote
// key (left of 1), or ?tune in the address, opens a slider for each
// data/config.json value that has value, min, max and step, and a button for
// each option of a switch (a word value with options), in the file's order; the
// game reads them live. Save keeps them in this browser and copies them as a
// block the person pastes to Claude, who writes them into data/config.json and
// design/feel-log.md; Reset goes back to the last saved values. The one-shot's
// tune.js, ported: the same panel, keys and block.

import data from '../../data/config.json';

/** A data/config.json entry the panel may show. */
interface Entry {
  value: unknown;
  min?: unknown;
  max?: unknown;
  step?: unknown;
  options?: unknown;
}

/** The project folder's name: the pasted block names it, so it is never written into another game. */
const NAME = '@NAME@';

const CONFIG = data as unknown as Record<string, Entry>;
const local = location.protocol === 'file:' || /^(localhost|127\.0\.0\.1|\[::1\])$/.test(location.hostname);

if (local) {
  const params = new URLSearchParams(location.search);
  const checked = !!(window.GAME_CLOCK || navigator.webdriver) || /Headless/.test(navigator.userAgent);
  const STORE = 'tune:' + NAME;
  const isNum = (c: Entry): boolean => [c.value, c.min, c.max, c.step].every(f => typeof f === 'number');
  // A switch: a word value with two or more options, shown as a button each.
  const optionsOf = (c: Entry): string[] => (Array.isArray(c.options) ? c.options.map(String) : []);
  const isPick = (c: Entry): boolean => typeof c.value === 'string' && optionsOf(c).length > 1 && optionsOf(c).includes(c.value);
  const keys = Object.keys(CONFIG).filter(k => {
    const c = CONFIG[k];
    return !!c && typeof c === 'object' && (isNum(c) || isPick(c));
  });
  const picks = keys.filter(k => isPick(CONFIG[k]));
  const fits = (k: string, v: unknown): boolean => (picks.includes(k) ? optionsOf(CONFIG[k]).includes(String(v)) : typeof v === 'number');
  const base: Record<string, unknown> = {}; // data/config.json as written
  keys.forEach(k => { base[k] = CONFIG[k].value; });
  const snap = (k: string, v: string): number => Number(Number(v).toFixed((String(CONFIG[k].step).split('.')[1] || '').length));
  const moved = (k: string): void => { dispatchEvent(new CustomEvent('tune', { detail: { key: k } })); }; // for a value the game reads once

  // A saved value stands only while data/config.json still holds the value it
  // replaced: once Claude writes it in, or the file changes another way, this
  // browser's copy is dropped.
  type Saved = Record<string, { value: unknown; was: unknown }>;
  let saved: Saved = {};
  try { saved = (JSON.parse(localStorage.getItem(STORE) ?? 'null') as Saved | null) || {}; } catch { saved = {}; }
  Object.keys(saved).forEach(k => {
    const s = saved[k];
    if (keys.includes(k) && s && s.was === base[k] && fits(k, s.value)) CONFIG[k].value = s.value;
    else delete saved[k];
  });
  const store = (): boolean => { try { localStorage.setItem(STORE, JSON.stringify(saved)); return true; } catch { return false; } };
  store();

  // ---- The panel ------------------------------------------------------------------------
  const FONT = 'font:12px/1.5 ui-monospace,Menlo,Consolas,monospace;color:#eee;';
  const el = <K extends keyof HTMLElementTagNameMap>(tag: K, css?: string, text?: string): HTMLElementTagNameMap[K] => {
    const e = document.createElement(tag);
    if (css) e.style.cssText = css;
    if (text != null) e.textContent = text;
    return e;
  };
  const hint = el('div', FONT + 'position:fixed;right:6px;bottom:4px;opacity:.45;pointer-events:none;z-index:2147483647', '` tune');
  hint.id = 'tune-hint';
  if (!checked) document.body.appendChild(hint);
  let panel: HTMLDivElement | null = null, out: HTMLTextAreaElement | null = null, note: HTMLDivElement | null = null, open = false;
  const rows: Record<string, { input?: HTMLInputElement; buttons?: HTMLButtonElement[]; num: HTMLSpanElement }> = {};
  const show = (k: string): void => {
    const v = CONFIG[k].value, r = rows[k];
    if (r.buttons) r.buttons.forEach(b => { b.style.background = b.dataset.value === v ? '#357' : '#333'; });
    else if (r.input) r.input.value = String(v);
    r.num.textContent = v === base[k] ? String(v) : `${String(v)} (was ${String(base[k])})`;
  };
  const block = (): string => { // what Save copies: the game, then each value that differs from data/config.json
    const lines = keys.filter(k => CONFIG[k].value !== base[k]).map(k => `${k} ${String(base[k])} → ${String(CONFIG[k].value)}`);
    return lines.length ? [`Tuned in the panel: ${NAME}`].concat(lines).join('\n') : '';
  };
  const save = (): void => {
    if (!out || !note) return;
    const o = out, n = note;
    saved = {};
    keys.forEach(k => { if (CONFIG[k].value !== base[k]) saved[k] = { value: CONFIG[k].value, was: base[k] }; });
    const kept = store() ? 'Saved in this browser. ' : 'Not saved: this browser keeps nothing. ';
    o.value = block();
    o.style.display = o.value ? 'block' : 'none';
    if (!o.value) { n.textContent = kept + 'Nothing differs from data/config.json.'; return; }
    const said = (ok: boolean): void => { n.textContent = kept + (ok ? 'Copied: paste it to Claude and say keep.' : 'Press Ctrl+C to copy it, then paste it to Claude and say keep.'); };
    o.focus(); o.select();
    let copied = false;
    try { copied = document.execCommand('copy'); } catch { copied = false; }
    if (copied || !navigator.clipboard) said(copied);
    else navigator.clipboard.writeText(o.value).then(() => said(true), () => said(false));
  };
  const reset = (): void => {
    keys.forEach(k => { CONFIG[k].value = saved[k] ? saved[k].value : base[k]; show(k); moved(k); });
    if (note) note.textContent = Object.keys(saved).length ? 'Back to the saved values.' : 'Back to data/config.json.';
  };
  const build = (): HTMLDivElement => {
    const p = el('div', FONT + 'position:fixed;top:8px;right:8px;width:290px;max-height:calc(100vh - 16px);overflow:auto;box-sizing:border-box;padding:8px 10px;background:rgba(10,10,10,.88);border:1px solid #555;border-radius:4px;z-index:2147483647');
    p.id = 'tune';
    p.appendChild(el('div', 'font-weight:bold;margin-bottom:6px', `Tune ${NAME} · \` to close`));
    if (!keys.length) p.appendChild(el('div', '', 'data/config.json has no values with min, max and step.'));
    keys.forEach(k => {
      const c = CONFIG[k];
      const row = isPick(c) ? el('div', 'display:block;margin:4px 0') : el('label', 'display:block;margin:4px 0');
      const top = el('div', 'display:flex;justify-content:space-between'), num = el('span', 'color:#9cf');
      top.append(el('span', '', k), num);
      if (isPick(c)) {
        const bar = el('div', 'display:flex;gap:6px;margin-top:2px'), buttons: HTMLButtonElement[] = [];
        bar.dataset.pick = k;
        optionsOf(c).forEach(o => {
          const b = el('button', FONT + 'flex:1;border:1px solid #666;border-radius:3px;padding:2px', o);
          b.type = 'button'; b.dataset.value = o;
          b.addEventListener('click', () => { CONFIG[k].value = o; show(k); moved(k); b.blur(); });
          buttons.push(b);
        });
        bar.append(...buttons);
        row.append(top, bar);
        p.appendChild(row);
        rows[k] = { buttons, num };
        show(k);
        return;
      }
      const input = el('input', 'width:100%;margin:2px 0 0');
      Object.assign(input, { type: 'range', min: String(c.min), max: String(c.max), step: String(c.step) });
      input.dataset.key = k;
      input.addEventListener('input', () => { CONFIG[k].value = snap(k, input.value); show(k); moved(k); });
      input.addEventListener('pointerup', () => input.blur()); // the arrow keys go back to the game
      row.append(top, input);
      p.appendChild(row);
      rows[k] = { input, num };
      show(k);
    });
    const button = (id: string, text: string, fn: () => void): HTMLButtonElement => {
      const b = el('button', FONT + 'flex:1;background:#333;border:1px solid #666;border-radius:3px;padding:3px', text);
      b.id = id; b.addEventListener('click', fn);
      return b;
    };
    const bar = el('div', 'display:flex;gap:6px;margin-top:8px');
    bar.append(button('tune-save', 'Save', save), button('tune-reset', 'Reset', reset));
    note = el('div', 'margin-top:6px;color:#bbb');
    out = el('textarea', FONT + 'display:none;width:100%;box-sizing:border-box;margin-top:6px;background:#111;border:1px solid #555');
    out.id = 'tune-out'; out.readOnly = true; out.rows = 4;
    p.append(bar, note, out);
    p.addEventListener('keydown', e => e.stopPropagation()); // keys typed here stay out of the game
    document.body.appendChild(p);
    return p;
  };
  const toggle = (on: boolean): void => {
    if (on && !panel) panel = build();
    if (panel) panel.style.display = on ? 'block' : 'none';
    hint.style.display = on ? 'none' : '';
    open = on;
  };
  // On the window's capture, so it runs before the game's keys and the panel's own.
  addEventListener('keydown', e => { if ((e.code === 'Backquote' || (!e.code && e.key === '`')) && !e.repeat) { e.preventDefault(); toggle(!open); } }, true);
  if (params.has('tune')) toggle(true);
}
