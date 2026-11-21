// PROTOTYPE - NOT FOR PRODUCTION
// Question: @QUESTION@
// Date: @DATE@
// The tweak panel. The backquote key (left of 1), or ?tune in the address, opens a slider for
// each config.js value that has value, min, max and step, and a button for each option of a
// switch (a word value with options), in the file's order; the game reads them live through
// tune.<name>. Save keeps them in this browser and copies them as a block the person pastes to
// Claude, who writes them into config.js (one-shot-tune.sh); Reset goes back to the last saved
// values. On this computer only: a shared build leaves this file out (one-shot-share.sh), and
// on a page served from anywhere else it does nothing.
//
// An add-on, never in the first build: one-shot-new.sh <name> --add tune.js copies it in. Wire
// it with one line in index.html, right after the config.js script tag and before the game's
// own script:
//     <script src="tune.js"></script>
(() => {
  'use strict';
  const local = location.protocol === 'file:' || /^(localhost|127\.0\.0\.1|\[::1\])$/.test(location.hostname);
  if (!local || !window.CONFIG) return;
  const params = new URLSearchParams(location.search);
  const checked = !!(window.GAME_CLOCK || navigator.webdriver) || /Headless/.test(navigator.userAgent);
  const page = decodeURIComponent(location.pathname);
  const NAME = page.split('/').slice(-2, -1)[0] || 'game'; // the game's folder
  const STORE = 'tune:' + page;
  const isNum = c => ['value', 'min', 'max', 'step'].every(f => typeof c[f] === 'number');
  // A switch: a word value with two or more options, shown as a button each.
  const isPick = c => typeof c.value === 'string' && Array.isArray(c.options) && c.options.length > 1 && c.options.includes(c.value);
  const keys = Object.keys(CONFIG).filter(k => {
    const c = CONFIG[k];
    return c && typeof c === 'object' && (isNum(c) || isPick(c));
  });
  const picks = keys.filter(k => isPick(CONFIG[k]));
  const fits = (k, v) => picks.includes(k) ? CONFIG[k].options.includes(v) : typeof v === 'number';
  const base = {}; // config.js as written
  keys.forEach(k => { base[k] = CONFIG[k].value; });
  const snap = (k, v) => Number(Number(v).toFixed((String(CONFIG[k].step).split('.')[1] || '').length));
  const moved = k => dispatchEvent(new CustomEvent('tune', { detail: { key: k } })); // for a value the game reads once

  // A saved value stands only while config.js still holds the value it replaced: once Claude
  // writes it in, or config.js changes another way, this browser's copy is dropped.
  let saved = {};
  try { saved = JSON.parse(localStorage.getItem(STORE)) || {}; } catch (e) { saved = {}; }
  Object.keys(saved).forEach(k => {
    const s = saved[k];
    if (keys.includes(k) && s && s.was === base[k] && fits(k, s.value)) CONFIG[k].value = s.value;
    else delete saved[k];
  });
  const store = () => { try { localStorage.setItem(STORE, JSON.stringify(saved)); return true; } catch (e) { return false; } };
  store();

  // ---- The panel ------------------------------------------------------------------------
  const FONT = 'font:12px/1.5 ui-monospace,Menlo,Consolas,monospace;color:#eee;';
  const el = (tag, css, text) => {
    const e = document.createElement(tag);
    if (css) e.style.cssText = css;
    if (text != null) e.textContent = text;
    return e;
  };
  const hint = el('div', FONT + 'position:fixed;right:6px;bottom:4px;opacity:.45;pointer-events:none;z-index:2147483647', '` tune');
  hint.id = 'tune-hint';
  if (!checked) document.body.appendChild(hint);
  let panel = null, out = null, note = null, open = false;
  const rows = {};
  function show(k) {
    const v = CONFIG[k].value;
    if (rows[k].buttons) rows[k].buttons.forEach(b => { b.style.background = b.dataset.value === v ? '#357' : '#333'; });
    else rows[k].input.value = v;
    rows[k].num.textContent = v === base[k] ? String(v) : `${v} (was ${base[k]})`;
  }
  function block() { // what Save copies: the game, then each value that differs from config.js
    const lines = keys.filter(k => CONFIG[k].value !== base[k]).map(k => `${k} ${base[k]} → ${CONFIG[k].value}`);
    return lines.length ? [`Tuned in the panel: ${NAME}`].concat(lines).join('\n') : '';
  }
  function save() {
    saved = {};
    keys.forEach(k => { if (CONFIG[k].value !== base[k]) saved[k] = { value: CONFIG[k].value, was: base[k] }; });
    const kept = store() ? 'Saved in this browser. ' : 'Not saved: this browser keeps nothing. ';
    out.value = block();
    out.style.display = out.value ? 'block' : 'none';
    if (!out.value) { note.textContent = kept + 'Nothing differs from config.js.'; return; }
    const said = ok => { note.textContent = kept + (ok ? 'Copied: paste it to Claude and say keep.' : 'Press Ctrl+C to copy it, then paste it to Claude and say keep.'); };
    out.focus(); out.select();
    let copied = false;
    try { copied = document.execCommand('copy'); } catch (e) { copied = false; }
    if (copied || !navigator.clipboard) said(copied);
    else navigator.clipboard.writeText(out.value).then(() => said(true), () => said(false));
  }
  function reset() {
    keys.forEach(k => { CONFIG[k].value = saved[k] ? saved[k].value : base[k]; show(k); moved(k); });
    note.textContent = Object.keys(saved).length ? 'Back to the saved values.' : 'Back to config.js.';
  }
  function build() {
    panel = el('div', FONT + 'position:fixed;top:8px;right:8px;width:290px;max-height:calc(100vh - 16px);overflow:auto;box-sizing:border-box;padding:8px 10px;background:rgba(10,10,10,.88);border:1px solid #555;border-radius:4px;z-index:2147483647');
    panel.id = 'tune';
    panel.appendChild(el('div', 'font-weight:bold;margin-bottom:6px', `Tune ${NAME} · \` to close`));
    if (!keys.length) panel.appendChild(el('div', '', 'config.js has no values with min, max and step.'));
    keys.forEach(k => {
      const c = CONFIG[k], row = el(isPick(c) ? 'div' : 'label', 'display:block;margin:4px 0');
      const top = el('div', 'display:flex;justify-content:space-between'), num = el('span', 'color:#9cf');
      top.append(el('span', '', k), num);
      if (isPick(c)) {
        const bar = el('div', 'display:flex;gap:6px;margin-top:2px'), buttons = [];
        bar.dataset.pick = k;
        c.options.forEach(o => {
          const b = el('button', FONT + 'flex:1;border:1px solid #666;border-radius:3px;padding:2px', o);
          b.type = 'button'; b.dataset.value = o;
          b.addEventListener('click', () => { CONFIG[k].value = o; show(k); moved(k); b.blur(); });
          buttons.push(b);
        });
        bar.append(...buttons);
        row.append(top, bar);
        panel.appendChild(row);
        rows[k] = { buttons, num };
        show(k);
        return;
      }
      const input = el('input', 'width:100%;margin:2px 0 0');
      Object.assign(input, { type: 'range', min: c.min, max: c.max, step: c.step });
      input.dataset.key = k;
      input.addEventListener('input', () => { CONFIG[k].value = snap(k, input.value); show(k); moved(k); });
      input.addEventListener('pointerup', () => input.blur()); // the arrow keys go back to the game
      row.append(top, input);
      panel.appendChild(row);
      rows[k] = { input, num };
      show(k);
    });
    const button = (id, text, fn) => {
      const b = el('button', FONT + 'flex:1;background:#333;border:1px solid #666;border-radius:3px;padding:3px', text);
      b.id = id; b.addEventListener('click', fn);
      return b;
    };
    const bar = el('div', 'display:flex;gap:6px;margin-top:8px');
    bar.append(button('tune-save', 'Save', save), button('tune-reset', 'Reset', reset));
    note = el('div', 'margin-top:6px;color:#bbb');
    out = el('textarea', FONT + 'display:none;width:100%;box-sizing:border-box;margin-top:6px;background:#111;border:1px solid #555');
    out.id = 'tune-out'; out.readOnly = true; out.rows = 4;
    panel.append(bar, note, out);
    panel.addEventListener('keydown', e => e.stopPropagation()); // keys typed here stay out of the game
    document.body.appendChild(panel);
  }
  function toggle(on) {
    if (on && !panel) build();
    if (panel) panel.style.display = on ? 'block' : 'none';
    hint.style.display = on ? 'none' : '';
    open = on;
  }
  // On the window's capture, so it runs before the game's keys and the panel's own. A key with no
  // code (an on-screen or remote keyboard) is read by its character.
  addEventListener('keydown', e => { if ((e.code === 'Backquote' || (!e.code && e.key === '`')) && !e.repeat) { e.preventDefault(); toggle(!open); } }, true);
  if (params.has('tune')) toggle(true);
})();
