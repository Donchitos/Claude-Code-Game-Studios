// one-shot-driver.js — put in front of a one-shot's own scripts by one-shot-run.sh; never part
// of the game. It fixes time and chance before the game loads, plays the game by its fixed step
// with real key and pointer events, and prints what happened as console rows "RUN|<kind>|...",
// which one-shot-run.sh turns into TSV. It measures and reports; whether a row is a failure is
// the skill's call.
//
// The address says what to play (one-shot-run.sh writes it):
//   log=<input log>   replay these inputs: Enter, ArrowRight:1.5, ArrowLeft+Space:0.5, wait:2,
//                     click:640,360 (a point of the window), click:text=Clock_in (the button
//                     whose words are these, underscores for spaces, scrolled into view first)
//   bot=end|lose      play with window.BOT.end or .lose from bot.js, step by step
//   stop=<step>       stop at this step; cap=<seconds> the longest a bot run plays
//   quiet=<step>      from this step on, send no input
//   press=<key>       with quiet: press this one key (event.code) at the quiet step, held two
//                     steps as a log's press is (a click:x,y once), and nothing after it
//   trace=<step>      from this step on, draw the screen after every step and report its hash
//                     (frame rows): two runs compared step by step show when they part
//   seed=<n>          the game's seed; Math.random gets its own seed from it
//   limit=<ms>        real time before a run is cut, default 150000
//   audio=<seconds>   render the game's sound offline when the run stops, at most this long
//   hookless=1        a game without window.game: its requestAnimationFrame and timers are taken
//                     over and stepped on the check's clock (scene and state rows read hookless)
// Pads: a key code Pad<1-4><A|B|Start|Up|Down|Left|Right|TurnL|TurnR> holds a virtual pad's
// button or stick (navigator.getGamepads()), so a bot plays a game read from a pad; a pad
// connects on its first press, as a real one shows after a button.
// A log may also hold wheel:x,y,<notches> (a real wheel event at a point; + zooms in).
// Loop rows: each step, window.game.events is emptied into the loop() steps the game logged; at
// the end, loop rows (act, result, reward, repeat, fail, restart), first rows (state.beat's show,
// try and test), ending rows (state.gained on over and results) and digits rows (each font that
// drew a number: one width or not).
// The game is stepped without drawing (window.game.step(1, false)) and drawn once a second
// of play and where it stops, so a run's speed is the game's logic, not its drawing; the steps
// alone are timed for the steptime row (steps, mean and slowest ms). The frametime row times each
// once-a-second drawing in play, with its step, until the pixels are done: the samples, the mean
// and slowest ms, the step of the slowest, and how many took over 16.7 ms and over 50 ms. Every run
// gives the game an offline audio context on the check's clock, reports the WebGL renderer it
// gets and each save it makes, and marks the spans where state.staged is set.
// The pressure row: the game's state.margin through play (1 safe, 0 lost), its lowest, where,
// its mean and the share of play at or under 0.25; numbers only, never how hard it feels.
(function () {
  'use strict';
  var q = new URLSearchParams(location.search);
  var realNow = performance.now.bind(performance);
  var started = realNow();
  var REAL_LIMIT = Number(q.get('limit')) || 150000; // ms of real time before a run is cut
  var STEP = 1 / 60;
  var t = 0;                         // simulated seconds since the page loaded
  var stepNo = 0;

  // ---- Time and chance, fixed before the game loads ----------------------------------------
  window.GAME_CLOCK = { now: function () { return t; } };
  performance.now = function () { return t * 1000; };

  // ---- Hookless: a game without window.game, stepped through its own loop ------------------
  // hookless=1 takes over requestAnimationFrame and the timers before the game loads: nothing of
  // the game's runs on the real clock, and each step of the run moves the check's clock 1/60 s,
  // fires the timers that are due, then the frames asked for before it. The game draws in its own
  // frames. Not covered (named in the door's record): CSS animations, Web Workers, pointer lock.
  var realSetTimeout = window.setTimeout.bind(window);
  var hookless = null;
  if (q.get('hookless') === '1') {
    var frames = [], timers = [], nextId = 1;
    window.requestAnimationFrame = function (fn) { var id = nextId++; frames.push({ id: id, fn: fn }); return id; };
    window.cancelAnimationFrame = function (id) { frames = frames.filter(function (f) { return f.id !== id; }); };
    var arm = function (fn, ms, args, every) {
      var id = nextId++, wait = Math.max(0, Number(ms) || 0);
      timers.push({ id: id, fn: fn, args: args, due: t * 1000 + wait, every: every ? Math.max(1, wait) : 0 });
      return id;
    };
    window.setTimeout = function (fn, ms) { return arm(fn, ms, [].slice.call(arguments, 2), false); };
    window.setInterval = function (fn, ms) { return arm(fn, ms, [].slice.call(arguments, 2), true); };
    window.clearTimeout = window.clearInterval = function (id) { timers = timers.filter(function (x) { return x.id !== id; }); };
    var call = function (fn, args) { if (typeof fn === 'function') fn.apply(window, args); else if (typeof fn === 'string') (0, eval)(fn); };
    hookless = {
      scene: 'hookless',
      state: {},
      // One step, the clock already moved by the run: the due timers fire in order, then the
      // frames asked for before this step. step(0) only draws: the frames run at the same time,
      // so a canvas a resize wiped is drawn again with no time passing.
      step: function (n) {
        if (!n) { var again = frames; frames = []; again.forEach(function (f) { f.fn(t * 1000); }); return; }
        var now = t * 1000 + 1e-6;
        for (var guard = 0; guard < 1000; guard++) {
          var due = timers.filter(function (x) { return x.due <= now; }).sort(function (a, b) { return a.due - b.due || a.id - b.id; })[0];
          if (!due) break;
          if (due.every) due.due += due.every; else timers = timers.filter(function (x) { return x !== due; });
          call(due.fn, due.args);
        }
        var batch = frames; frames = [];
        batch.forEach(function (f) { f.fn(t * 1000); });
      },
    };
  }
  var EPOCH = Date.UTC(2026, 0, 1, 12);
  Date.now = function () { return EPOCH + Math.floor(t * 1000); };
  var mseed = ((Number(q.get('seed')) || 1) * 2654435761) >>> 0;
  Math.random = function () { // mulberry32, apart from the game's own rng()
    mseed = (mseed + 0x6D2B79F5) | 0;
    var x = Math.imul(mseed ^ (mseed >>> 15), mseed | 1);
    x ^= x + Math.imul(x ^ (x >>> 7), x | 61);
    return ((x ^ (x >>> 14)) >>> 0) / 4294967296;
  };

  function row() {
    var a = Array.prototype.slice.call(arguments).map(function (v) {
      return String(v).replace(/[|\r\n\t]/g, ' ');
    });
    console.log('RUN|' + a.join('|'));
  }
  window.addEventListener('error', function (e) { row('error', stepNo, e.message || 'error'); });

  // ---- Sound: one offline context on the check's clock ---------------------------------------
  // The game's AudioContext is an OfflineAudioContext whose currentTime is the check's clock, so
  // sound scheduled on the audio clock lands where it would in play, and a game timed by its
  // audio clock moves (a real context stays suspended with no person's gesture). Only a run
  // given audio=<seconds> renders it, once the run stops.
  var AUDIO_SECS = Math.min(120, Number(q.get('audio')) || 0), AUDIO_RATE = 22050; // 600 s failed to render
  var OAC = window.OfflineAudioContext || window.webkitOfflineAudioContext;
  var actx = null, mediaUsed = false;
  function audioContext() {
    if (actx) return actx;
    actx = new OAC(2, Math.max(1, Math.round((AUDIO_SECS || 1) * AUDIO_RATE)), AUDIO_RATE);
    Object.defineProperty(actx, 'currentTime', { get: function () { return t; } });
    Object.defineProperty(actx, 'state', { get: function () { return 'running'; } });
    ['resume', 'suspend', 'close'].forEach(function (k) { actx[k] = function () { return Promise.resolve(); }; });
    actx.baseLatency = 0; actx.outputLatency = 0;
    actx.getOutputTimestamp = function () { return { contextTime: t, performanceTime: t * 1000 }; };
    actx.createMediaElementSource = function () { mediaUsed = true; return actx.createGain(); };
    return actx;
  }
  if (OAC) {
    var FakeAudio = function () { return audioContext(); };
    window.AudioContext = FakeAudio; window.webkitAudioContext = FakeAudio;
    Object.defineProperty(window, 'GAME_AUDIO', { configurable: true, get: audioContext });
    // A plain `param.value = v` lands at the render's start in an offline context, so a mute
    // set at 30 s would silence the whole render: it is set at the check's clock instead, and
    // reads back as set.
    var pv = Object.getOwnPropertyDescriptor(AudioParam.prototype, 'value');
    Object.defineProperty(AudioParam.prototype, 'value', {
      configurable: true,
      get: function () { return this.__v !== undefined ? this.__v : pv.get.call(this); },
      set: function (v) { this.__v = v; try { this.setValueAtTime(v, t); } catch (e) { pv.set.call(this, v); } },
    });
  }
  // An <audio> element cannot join the render, and play() without a person's gesture is refused;
  // it is counted and resolved, never played.
  HTMLMediaElement.prototype.play = function () { mediaUsed = true; return Promise.resolve(); };
  function renderAudio(secs, done) {
    if (!AUDIO_SECS) return done();
    if (!OAC) { row('audio', 'media'); return done(); }
    if (!actx) { row('audio', mediaUsed ? 'media' : 'none'); return done(); }
    // The render runs on the audio thread. Headless Chrome on a time budget moves its virtual
    // clock to the end as soon as the page is idle and takes the picture then, so the page is
    // kept busy until the render is back (one-shot-run.sh gives this run a long budget). A slice
    // is a fixed count of work, never a wait on the clock: when the budget runs out the page's
    // clocks stop dead inside a task (performance.now and Date.now both froze mid-slice in a 3D
    // game, and a wait on them never ended). At most 2,000 slices.
    var rendering = true, slices = 0;
    (function busy() {
      if (!rendering || ++slices > 2000) return;
      for (var k = 0, x = 0; k < 2e6; k++) x += k & 7; // hold the virtual clock
      realSetTimeout(busy, x < 0 ? 1 : 0);
    })();
    var finish = done; done = function () { rendering = false; finish(); };
    OAC.prototype.startRendering.call(actx).then(function (buf) {
      var n = Math.min(buf.length, Math.round(Math.min(secs, AUDIO_SECS) * AUDIO_RATE));
      var chs = [], c, i, peak = 0, clipped = 0, sum = 0;
      for (c = 0; c < buf.numberOfChannels; c++) chs.push(buf.getChannelData(c));
      for (c = 0; c < chs.length; c++) for (i = 0; i < n; i++) {
        var a = Math.abs(chs[c][i]); if (a > peak) peak = a; if (a >= 1) clipped++; sum += a * a;
      }
      // Silent: 100 ms windows below -60 dBFS. A sound: a 10 ms window above -40 dBFS and
      // twice the one before, at least 50 ms after the last.
      function win(from, len) { var m = 0; for (var k = 0; k < chs.length; k++) { var s = 0; for (var j = from; j < from + len && j < n; j++) s += chs[k][j] * chs[k][j]; m = Math.max(m, Math.sqrt(s / len)); } return m; }
      var silent = 0, wins = 0, sounds = 0, prev = 0, lastOn = -1e9, W100 = 2205, W10 = 220; // whole samples at 22,050 Hz
      for (i = 0; i + W100 <= n; i += W100) { wins++; if (win(i, W100) < 0.001) silent++; }
      for (i = 0; i + W10 <= n; i += W10) {
        var r = win(i, W10);
        if (r > 0.01 && r > 2 * prev && i - lastOn >= 1100) { sounds++; lastOn = i; }
        prev = r;
      }
      var db = function (v) { return v > 0 ? (20 * Math.log10(v)).toFixed(1) : '-inf'; };
      row('audio', (n / AUDIO_RATE).toFixed(1), db(peak), clipped, db(Math.sqrt(sum / Math.max(1, n * chs.length))), wins ? Math.round(100 * silent / wins) : 100, sounds);
      if (mediaUsed) row('audio', 'media');
      done();
    }, function (e) { row('audio', 'failed', e && e.message ? e.message : String(e)); done(); });
  }

  // ---- WebGL: which renderer drew it ---------------------------------------------------------
  var getCtx = HTMLCanvasElement.prototype.getContext, glSeen = false;
  HTMLCanvasElement.prototype.getContext = function (kind) {
    var c = getCtx.apply(this, arguments);
    if (!glSeen && /webgl/i.test(String(kind))) {
      glSeen = true;
      var r = 'none: the browser gave no WebGL context';
      if (c) { try { var ext = c.getExtension('WEBGL_debug_renderer_info'); r = ext ? c.getParameter(ext.UNMASKED_RENDERER_WEBGL) : c.getParameter(c.RENDERER); } catch (e) { r = '-'; } }
      row('webgl', r);
    }
    return c;
  };

  // ---- Saves: what the game keeps for a second visit ------------------------------------------
  var savedKeys = {}, savedAny = false;
  try {
    var setItem = Storage.prototype.setItem;
    Storage.prototype.setItem = function (k) {
      if (this === window.localStorage && !savedKeys[k]) { savedKeys[k] = 1; savedAny = true; row('saved', stepNo, 'localstorage', k); }
      return setItem.apply(this, arguments);
    };
  } catch (e) { /* no storage here */ }
  try {
    var idbOpen = indexedDB.open;
    indexedDB.open = function (name) { savedAny = true; row('saved', stepNo, 'indexeddb', name); return idbOpen.apply(indexedDB, arguments); };
  } catch (e) { /* no IndexedDB here */ }

  // ---- Text: every fillText and strokeText is measured while a frame is recorded -------------
  var recording = false, texts = [], blits = new Map(), loops = loopMeter();
  var C2D = window.CanvasRenderingContext2D && CanvasRenderingContext2D.prototype;
  var probe = document.createElement('canvas').getContext('2d', { willReadFrequently: true });
  function rgba(style) { // any CSS colour to [r, g, b, a]; null for gradients and patterns
    if (typeof style !== 'string') return null;
    probe.clearRect(0, 0, 1, 1); probe.fillStyle = '#000'; probe.fillStyle = style;
    probe.fillRect(0, 0, 1, 1);
    var d = probe.getImageData(0, 0, 1, 1).data;
    return [d[0], d[1], d[2], d[3] / 255];
  }
  function lum(c) { // WCAG relative luminance
    function ch(v) { v /= 255; return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
    return 0.2126 * ch(c[0]) + 0.7152 * ch(c[1]) + 0.0722 * ch(c[2]);
  }
  function ratio(a, b) { var x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); }
  function pageBg() {
    var els = [document.body, document.documentElement];
    for (var i = 0; i < els.length; i++) {
      var c = els[i] && rgba(getComputedStyle(els[i]).backgroundColor);
      if (c && c[3] > 0) return c;
    }
    return [255, 255, 255, 1];
  }
  function blend(c, under) {
    var a = c[3];
    return [c[0] * a + under[0] * (1 - a), c[1] * a + under[1] * (1 - a), c[2] * a + under[2] * (1 - a), 1];
  }
  // The colour behind a box of canvas pixels: the median by luminance, transparent pixels
  // standing for the page behind the canvas.
  function behind(ctx, x0, y0, x1, y1) {
    var cw = ctx.canvas.width, ch = ctx.canvas.height;
    x0 = Math.max(0, Math.floor(x0)); y0 = Math.max(0, Math.floor(y0));
    x1 = Math.min(cw, Math.ceil(x1)); y1 = Math.min(ch, Math.ceil(y1));
    if (x1 <= x0 || y1 <= y0) return null;
    var d;
    try { d = ctx.getImageData(x0, y0, x1 - x0, y1 - y0).data; } catch (e) { return null; }
    var bg = pageBg(), px = [], n = d.length / 4, stride = Math.max(1, Math.floor(n / 4000));
    for (var i = 0; i < n; i += stride) {
      var c = blend([d[i * 4], d[i * 4 + 1], d[i * 4 + 2], d[i * 4 + 3] / 255], bg);
      px.push([lum(c), c]);
    }
    px.sort(function (a, b) { return a[0] - b[0]; });
    return px[Math.floor(px.length / 2)][1];
  }
  function corners(m, x0, y0, x1, y1) {
    var pts = [[x0, y0], [x1, y0], [x0, y1], [x1, y1]].map(function (p) {
      return [m.a * p[0] + m.c * p[1] + m.e, m.b * p[0] + m.d * p[1] + m.f];
    });
    var xs = pts.map(function (p) { return p[0]; }), ys = pts.map(function (p) { return p[1]; });
    return [Math.min.apply(null, xs), Math.min.apply(null, ys), Math.max.apply(null, xs), Math.max.apply(null, ys)];
  }
  function measure(ctx, s, x, y, kind) {
    s = String(s);
    if (!s.trim()) return;
    var m = ctx.measureText(s), hg = ctx.measureText('Hg');
    var box = corners(ctx.getTransform(), x - m.actualBoundingBoxLeft, y - m.actualBoundingBoxAscent,
      x + m.actualBoundingBoxRight, y + m.actualBoundingBoxDescent);
    var tm = ctx.getTransform(), scaleY = Math.hypot(tm.c, tm.d);
    var glyph = (hg.actualBoundingBoxAscent + hg.actualBoundingBoxDescent) * scaleY; // canvas px
    var colour = rgba(kind === 'fill' ? ctx.fillStyle : ctx.strokeStyle);
    var bg = behind(ctx, box[0], box[1], box[2], box[3]);
    var r = null;
    if (colour && bg) r = ratio(blend([colour[0], colour[1], colour[2], colour[3] * ctx.globalAlpha], bg), bg);
    texts.push({ canvas: ctx.canvas, s: s, box: box, glyph: glyph, ratio: r });
  }
  if (C2D) {
    ['fillText', 'strokeText'].forEach(function (name) {
      var orig = C2D[name];
      C2D[name] = function (s, x, y) {
        if (recording) { try { measure(this, s, x, y, name === 'fillText' ? 'fill' : 'stroke'); } catch (e) { row('measurefail', e.message); } }
        if (/[0-9]/.test(String(s))) loops.font(this.font);
        return orig.apply(this, arguments);
      };
    });
    var origDraw = C2D.drawImage;
    C2D.drawImage = function (img) { // a buffer canvas drawn onto another: remember where it went
      if (recording && img && (img instanceof HTMLCanvasElement || (window.OffscreenCanvas && img instanceof OffscreenCanvas))) {
        var a = arguments, sw = img.width, sh = img.height, sx = 0, sy = 0, dx, dy, dw, dh;
        if (a.length >= 9) { sx = a[1]; sy = a[2]; sw = a[3]; sh = a[4]; dx = a[5]; dy = a[6]; dw = a[7]; dh = a[8]; }
        else if (a.length >= 5) { dx = a[1]; dy = a[2]; dw = a[3]; dh = a[4]; }
        else { dx = a[1]; dy = a[2]; dw = sw; dh = sh; }
        blits.set(img, { target: this.canvas, m: this.getTransform(), sx: sx, sy: sy, kx: dw / sw, ky: dh / sh, dx: dx, dy: dy });
      }
      return origDraw.apply(this, arguments);
    };
  }
  // Canvas pixels to window pixels, through at most three buffer canvases.
  function toWindow(canvas, box) { // ky: window pixels per canvas pixel, down the whole chain
    var scale = 1;
    for (var hop = 0; hop < 4; hop++) {
      if (canvas.isConnected) {
        var r = canvas.getBoundingClientRect();
        if (!r.width || !r.height) return null;
        var kx = r.width / canvas.width, ky = r.height / canvas.height;
        return { box: [r.left + box[0] * kx, r.top + box[1] * ky, r.left + box[2] * kx, r.top + box[3] * ky], ky: ky * scale,
          clip: [Math.max(0, r.left), Math.max(0, r.top), Math.min(innerWidth, r.right), Math.min(innerHeight, r.bottom)] };
      }
      var b = blits.get(canvas);
      if (!b) return null;
      var bx = [b.dx + (box[0] - b.sx) * b.kx, b.dy + (box[1] - b.sy) * b.ky, b.dx + (box[2] - b.sx) * b.kx, b.dy + (box[3] - b.sy) * b.ky];
      box = corners(b.m, bx[0], bx[1], bx[2], bx[3]);
      scale *= b.ky * Math.hypot(b.m.c, b.m.d);
      canvas = b.target;
    }
    return null;
  }
  function textRows(scene) {
    var groups = [];
    texts.forEach(function (tx) {
      var w = toWindow(tx.canvas, tx.box);
      var item = { s: tx.s, ratio: tx.ratio, mapped: !!w };
      if (w) {
        item.box = w.box; item.clip = w.clip;
        item.h = tx.glyph * w.ky * 1080 / innerHeight;
      }
      // A string drawn twice in about one place (an outline, a shadow) is one text: it reads
      // when any of its layers stands out from what is behind it.
      var g = groups.find(function (o) {
        return o.s === item.s && o.mapped && item.mapped && Math.abs(o.box[0] - item.box[0]) < 6 && Math.abs(o.box[1] - item.box[1]) < 6;
      });
      if (g) { if (item.ratio !== null && (g.ratio === null || item.ratio > g.ratio)) g.ratio = item.ratio; }
      else groups.push(item);
    });
    var unmapped = 0;
    groups.forEach(function (g) {
      if (!g.mapped) { unmapped++; return; }
      var inside = g.box[0] >= g.clip[0] - 1 && g.box[1] >= g.clip[1] - 1 && g.box[2] <= g.clip[2] + 1 && g.box[3] <= g.clip[3] + 1;
      row('text', scene, 'canvas', g.box.map(Math.round).join(','), g.h.toFixed(1),
        g.ratio === null ? '-' : g.ratio.toFixed(2), inside ? 'inside' : 'outside', g.s.slice(0, 60));
    });
    if (unmapped) row('textunmapped', scene, unmapped);
    // HTML text over or around the game
    var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    var seen = new Set(), node;
    while ((node = walker.nextNode())) {
      var el = node.parentElement;
      if (!el || seen.has(el) || !node.nodeValue.trim() || /^(SCRIPT|STYLE|NOSCRIPT)$/.test(el.tagName)) continue;
      seen.add(el);
      var cs = getComputedStyle(el);
      if (cs.visibility === 'hidden' || cs.display === 'none' || Number(cs.opacity) === 0) continue;
      var range = document.createRange(); range.selectNodeContents(node);
      var rr = range.getBoundingClientRect();
      if (!rr.width || !rr.height) continue;
      probe.font = cs.font;
      var hg = probe.measureText('Hg');
      var h = (hg.actualBoundingBoxAscent + hg.actualBoundingBoxDescent) * 1080 / innerHeight;
      var fg = rgba(cs.color), bg = null, p = el;
      while (p && p.nodeType === 1) {
        var c = rgba(getComputedStyle(p).backgroundColor);
        if (c && c[3] > 0) { bg = c; break; }
        p = p.parentElement;
      }
      if (!bg) { // nothing behind it in the page: the game's canvas under its middle, else the page
        var under = document.elementsFromPoint(rr.left + rr.width / 2, rr.top + rr.height / 2).filter(function (e) { return e.tagName === 'CANVAS'; })[0];
        if (under) {
          var ur = under.getBoundingClientRect(), kx = under.width / ur.width, ky = under.height / ur.height;
          var uctx = null;
          try { uctx = under.getContext('2d'); } catch (e) { uctx = null; }
          if (uctx) bg = behind(uctx, (rr.left - ur.left) * kx, (rr.top - ur.top) * ky, (rr.right - ur.left) * kx, (rr.bottom - ur.top) * ky);
        }
        if (!bg) bg = pageBg();
      }
      var r2 = fg ? ratio(blend([fg[0], fg[1], fg[2], fg[3] * Number(cs.opacity)], bg), bg) : null;
      var inside = rr.left >= -1 && rr.top >= -1 && rr.right <= innerWidth + 1 && rr.bottom <= innerHeight + 1;
      row('text', scene, 'html', [rr.left, rr.top, rr.right, rr.bottom].map(Math.round).join(','), h.toFixed(1),
        r2 === null ? '-' : r2.toFixed(2), inside ? 'inside' : 'outside', node.nodeValue.trim().slice(0, 60));
    }
  }

  // ---- The screen: a hash for "did it change", and blank detection ------------------------
  // Make every canvas finish its drawing (a 1x1 read of each), so a frame's time includes it.
  function flush() {
    var tmp = document.createElement('canvas'); tmp.width = tmp.height = 1;
    var tctx = tmp.getContext('2d', { willReadFrequently: true });
    document.querySelectorAll('canvas').forEach(function (cv) {
      if (!cv.width || !cv.height) return;
      try { tctx.drawImage(cv, 0, 0, 1, 1); tctx.getImageData(0, 0, 1, 1); } catch (e) { /* tainted */ }
    });
  }

  function screen() {
    var h = 2166136261, first = null, varied = false, any = false;
    document.querySelectorAll('canvas').forEach(function (cv) {
      if (!cv.width || !cv.height) return;
      var r = cv.getBoundingClientRect();
      if (!r.width || !r.height) return;
      any = true;
      var tmp = document.createElement('canvas'); tmp.width = Math.min(cv.width, 640); tmp.height = Math.round(tmp.width * cv.height / cv.width) || 1;
      var tctx = tmp.getContext('2d', { willReadFrequently: true });
      try { tctx.drawImage(cv, 0, 0, tmp.width, tmp.height); } catch (e) { return; }
      var d = tctx.getImageData(0, 0, tmp.width, tmp.height).data;
      if (first === null) first = [d[0], d[1], d[2]];
      for (var i = 0; i < d.length; i += 4) {
        h = Math.imul(h ^ d[i], 16777619); h = Math.imul(h ^ d[i + 1], 16777619); h = Math.imul(h ^ d[i + 2], 16777619);
        if (!varied && (d[i] !== first[0] || d[i + 1] !== first[1] || d[i + 2] !== first[2])) varied = true;
      }
    });
    var txt = document.body.innerText || '';
    for (var j = 0; j < txt.length; j++) h = Math.imul(h ^ txt.charCodeAt(j), 16777619);
    return { hash: (h >>> 0).toString(16), blank: any ? !varied && !txt.trim() : !txt.trim() };
  }

  // ---- Input: real events, so the game's own listeners are what is tested ------------------
  var KEY = { Space: ' ', Enter: 'Enter', Escape: 'Escape', Tab: 'Tab', Backspace: 'Backspace',
    ShiftLeft: 'Shift', ShiftRight: 'Shift', ControlLeft: 'Control', ControlRight: 'Control', AltLeft: 'Alt', Backquote: '`' };
  var KEYCODE = { Space: 32, Enter: 13, Escape: 27, Tab: 9, Backspace: 8, ArrowLeft: 37, ArrowUp: 38, ArrowRight: 39,
    ArrowDown: 40, ShiftLeft: 16, ShiftRight: 16, ControlLeft: 17, ControlRight: 17, AltLeft: 18, Backquote: 192 };
  function keyOf(code) {
    if (KEY[code]) return KEY[code];
    if (/^Key[A-Z]$/.test(code)) return code.slice(3).toLowerCase();
    if (/^Digit[0-9]$/.test(code)) return code.slice(5);
    return code;
  }
  function keyCodeOf(code) {
    if (KEYCODE[code]) return KEYCODE[code];
    if (/^Key[A-Z]$/.test(code)) return code.charCodeAt(3);
    if (/^Digit[0-9]$/.test(code)) return code.charCodeAt(5);
    return 0;
  }
  function sendKey(type, code) {
    var ev = new KeyboardEvent(type, { code: code, key: keyOf(code), bubbles: true, cancelable: true });
    var kc = keyCodeOf(code);
    Object.defineProperty(ev, 'keyCode', { get: function () { return kc; } });
    Object.defineProperty(ev, 'which', { get: function () { return kc; } });
    var target = document.activeElement && document.activeElement !== document.body ? document.activeElement : document;
    target.dispatchEvent(ev);
  }
  function wheel(x, y, notches) { // + zooms in, as a person's wheel turned away from them
    var target = document.elementFromPoint(x, y) || document.body;
    target.dispatchEvent(new WheelEvent('wheel', { bubbles: true, cancelable: true, clientX: x, clientY: y, deltaY: -100 * notches, deltaMode: 0 }));
  }
  function click(x, y, at) { // at: the element to send to; else the one at the point
    var target = at || document.elementFromPoint(x, y) || document.body;
    var o = { bubbles: true, cancelable: true, clientX: x, clientY: y, button: 0, buttons: 1, pointerId: 1, isPrimary: true, pointerType: 'mouse' };
    if (window.PointerEvent) target.dispatchEvent(new PointerEvent('pointerdown', o));
    target.dispatchEvent(new MouseEvent('mousedown', o));
    o.buttons = 0;
    if (window.PointerEvent) target.dispatchEvent(new PointerEvent('pointerup', o));
    target.dispatchEvent(new MouseEvent('mouseup', o));
    target.dispatchEvent(new MouseEvent('click', o));
  }
  // A click on the first button, link or [role=button] whose words are these (underscores for
  // spaces; an exact match first, else one that holds them), scrolled into view first: a start
  // button below the window cannot be reached by a point of it. False when none is found.
  function clickText(words) {
    var want = words.replace(/_/g, ' ').replace(/\s+/g, ' ').trim().toLowerCase(), hit = null, part = null;
    var all = document.querySelectorAll('button, a, [role="button"], input[type="button"], input[type="submit"], [onclick]');
    for (var i = 0; i < all.length && !hit; i++) {
      if (!all[i].getClientRects().length) continue; // not on the page yet: a person could not press it
      var t = (all[i].innerText || all[i].value || all[i].getAttribute('aria-label') || '').replace(/\s+/g, ' ').trim().toLowerCase();
      if (t === want) hit = all[i]; else if (!part && t && t.indexOf(want) >= 0) part = all[i];
    }
    hit = hit || part;
    if (!hit) return false;
    hit.scrollIntoView({ block: 'center', inline: 'center' });
    var r = hit.getBoundingClientRect();
    click(r.left + r.width / 2, r.top + r.height / 2, hit); // to the button itself: a layer over it would take a point
    return true;
  }
  var held = new Set(), sent = 0;
  // Virtual pads (Pad1A, Pad2Left ...): the standard mapping's buttons, the left stick on axes 0
  // and 1, the right stick's x on axis 2. A pad connects on its first press.
  var vpads = [], VB = { A: 0, B: 1, Start: 9, Up: 12, Down: 13, Left: 14, Right: 15 };
  var isPad = function (k) { return /^Pad[1-4](A|B|Start|Up|Down|Left|Right|TurnL|TurnR)$/.test(k); };
  function padHold(k, on) {
    var n = Number(k.charAt(3)) - 1, what = k.slice(4), p = vpads[n];
    if (!p) {
      p = vpads[n] = { index: n, id: 'virtual pad ' + (n + 1), connected: true, mapping: 'standard', timestamp: 0, on: new Set() };
      try { window.dispatchEvent(Object.assign(new Event('gamepadconnected'), { gamepad: p })); } catch (e) { /* no event */ }
    }
    if (on) p.on.add(what); else p.on.delete(what);
  }
  try {
    Object.defineProperty(navigator, 'getGamepads', { configurable: true, value: function () {
      var out = [null, null, null, null];
      vpads.forEach(function (p) {
        if (!p) return;
        var h = function (w) { return p.on.has(w) ? 1 : 0; }, buttons = [];
        for (var i = 0; i < 17; i++) buttons.push({ pressed: false, touched: false, value: 0 });
        Object.keys(VB).forEach(function (w) { if (h(w)) buttons[VB[w]] = { pressed: true, touched: true, value: 1 }; });
        out[p.index] = { index: p.index, id: p.id, connected: true, mapping: 'standard', timestamp: t * 1000, buttons: buttons,
          axes: [h('Right') - h('Left'), h('Down') - h('Up'), h('TurnR') - h('TurnL'), 0] };
      });
      return out;
    } });
  } catch (e) { /* the browser keeps its own */ }
  function hold(keys) { // keys: the codes to hold this step, plus any "click:x,y"
    var want = new Set();
    keys.forEach(function (k) {
      var c = /^click:(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)$/.exec(k);
      var ct = !c && /^click:text=(\S+)$/.exec(k);
      var wh = !c && !ct && /^wheel:(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?),(-?\d+)$/.exec(k);
      if (c) { click(Number(c[1]), Number(c[2])); sent++; } else if (ct) { if (clickText(ct[1])) sent++; }
      else if (wh) { var nn = Number(wh[3]), sg = nn < 0 ? -1 : 1; for (var wi = 0; wi < Math.abs(nn); wi++) wheel(Number(wh[1]), Number(wh[2]), sg); sent++; }
      else if (k) want.add(k);
    });
    held.forEach(function (k) { if (!want.has(k)) { if (isPad(k)) padHold(k, false); else sendKey('keyup', k); held.delete(k); } });
    want.forEach(function (k) { if (!held.has(k)) { if (isPad(k)) padHold(k, true); else sendKey('keydown', k); held.add(k); sent++; } });
  }

  // An input log as a list of steps: what to hold at each step.
  function parseLog(text, gap) { // gap: the empty steps after each key, 2
    var plan = [], cur = 0, bad = [];
    gap = gap == null ? 2 : gap;
    function at(i) { while (plan.length <= i) plan.push([]); return plan[i]; }
    text.trim().split(/\s+/).filter(Boolean).forEach(function (tok) {
      var m;
      if ((m = /^wait:(\d+(?:\.\d+)?)$/.exec(tok))) { cur += Math.round(Number(m[1]) / STEP); return; }
      if ((m = /^click:(?:-?\d+(?:\.\d+)?,-?\d+(?:\.\d+)?|text=\S+)$/.exec(tok))) { at(cur).push(tok); cur += 4; return; }
      if ((m = /^wheel:-?\d+(?:\.\d+)?,-?\d+(?:\.\d+)?,-?\d+$/.exec(tok))) { at(cur).push(tok); cur += 4; return; }
      if ((m = /^([A-Za-z0-9+]+)(?::(\d+(?:\.\d+)?))?$/.exec(tok))) {
        var keys = m[1].split('+'), n = m[2] ? Math.max(1, Math.round(Number(m[2]) / STEP)) : 2;
        for (var i = 0; i < n; i++) at(cur + i).push.apply(at(cur + i), keys);
        cur += n + gap; return;
      }
      bad.push(tok);
    });
    at(cur);
    return { plan: plan, bad: bad, length: cur };
  }

  // ---- The game's state: numbers that are no longer numbers ------------------------------
  var nonfinite = new Set();
  function walk(o, path, depth) {
    if (depth > 4 || o === null || typeof o !== 'object') return;
    Object.keys(o).slice(0, 200).forEach(function (k) {
      var v = o[k], p = path ? path + '.' + k : k;
      if (typeof v === 'number' && !isFinite(v) && !nonfinite.has(p)) { nonfinite.add(p); row('nonfinite', stepNo, p, String(v)); }
      else if (v && typeof v === 'object') walk(v, p, depth + 1);
    });
  }
  function brief(o) {
    try {
      return JSON.stringify(o, function (k, v) {
        if (Array.isArray(v) && v.length > 6) return '[' + v.length + ' items]';
        if (typeof v === 'number' && !Number.isInteger(v)) return Math.round(v * 100) / 100;
        return v;
      }).slice(0, 200);
    } catch (e) { return '-'; }
  }
  // What the bot sees: the scene and a copy of the state, so it plays by keys and clicks
  // and can never change the game.
  function view(g) {
    var copy;
    try { copy = structuredClone(g.state); } catch (e) {
      try { copy = JSON.parse(JSON.stringify(g.state)); } catch (e2) { copy = {}; }
    }
    return Object.freeze({ scene: g.scene, state: copy });
  }

  // ---- The loop: the loop() steps window.game.events logged each step, measured --------------
  // window.game.events holds the game's log of loop steps (act, result, reward); it is emptied
  // after every step. state.beat and state.gained give the first minute and the ending; each
  // font that draws a digit is measured for one-width digits. Numbers only; the floors are the
  // self-check's.
  function loopMeter() {
    var marks = {}, beats = {}, beat = null, fails = 0, restarts = 0, endings = [];
    var firstReward = -1, repeat = 0, actInTry = 0, fonts = {};
    var f = function (x) { return (Math.round(x * 1000) / 1000).toString(); };
    var take = function (e, s) {
      if (!e || typeof e !== 'object' || e.kind !== 'loop') return;
      var k = String(e.step); if (!marks[k]) marks[k] = { n: 0, first: s }; marks[k].n++;
      if (k === 'reward' && firstReward < 0) firstReward = s;
      if (k === 'act' && firstReward >= 0) repeat++;
      if (k === 'act' && beat === 'try') actInTry++;
    };
    return {
      font: function (font) { // a font that drew a digit: are its digits one width?
        if (font in fonts) return;
        try {
          var c = document.createElement('canvas').getContext('2d'); c.font = font;
          var w = '0123456789'.split('').map(function (d) { return c.measureText(d).width; });
          fonts[font] = Math.max.apply(null, w) - Math.min.apply(null, w);
        } catch (e) { fonts[font] = -1; }
      },
      step: function (g, s) {
        var ev; try { ev = g.events; } catch (e) { ev = null; } // a step's events belong to the beat they happened in
        if (ev && ev.length) ev.splice(0, ev.length).forEach(function (e) { take(e, s); });
        var b; try { b = g.state && g.state.beat; } catch (e) { b = undefined; }
        if (b !== undefined && b !== null && String(b) !== beat) { beat = String(b); if (!(beat in beats)) beats[beat] = s; }
      },
      scene: function (from, to, s, g) {
        if (to === 'over') fails++;
        if ((from === 'over' || from === 'results') && to === 'play') restarts++;
        if (to === 'over' || to === 'results') { var gn = ''; try { gn = g.state && g.state.gained ? String(g.state.gained) : ''; } catch (e) { gn = ''; } endings.push([to, gn]); }
      },
      rows: function (run, hasHook) {
        Object.keys(fonts).forEach(function (ft) { row('digits', run, ft, fonts[ft] < 0 ? 'unmeasured' : fonts[ft] < 0.01 ? 'tabular' : 'proportional', f(Math.max(0, fonts[ft]))); });
        // The core loop: act, result, reward or progress, then repeat or fail, then a restart
        if (!hasHook) row('loop', run, 'none', 'no window.game.events: the starter check hooks were removed');
        else if (!Object.keys(marks).length) row('loop', run, 'none', 'no loop() step was marked');
        else {
          ['act', 'result', 'reward'].forEach(function (k) { var m = marks[k]; row('loop', run, k, m ? m.n : 0, m ? m.first : '-'); });
          row('loop', run, 'repeat', repeat); row('loop', run, 'fail', fails); row('loop', run, 'restart', restarts);
        }
        // The first minute and the ending
        if (!Object.keys(beats).length) row('first', run, 'none', 'no state.beat');
        else {
          row('first', run, 'show', 'show' in beats ? beats.show : '-', 'try', 'try' in beats ? beats.try : '-', 'test', 'test' in beats ? beats.test : '-');
          row('first', run, 'act-in-try', actInTry);
        }
        endings.forEach(function (x) { row('ending', run, x[0], x[1] ? 'gained' : 'none', x[1] || '-'); });
      },
    };
  }

  // ---- The run --------------------------------------------------------------------------
  window.addEventListener('load', function () {
    var g = hookless || window.game;
    if (hookless) row('hookless', window.game ? 'the game has window.game; its own loop is stepped' : 'no window.game: the game is stepped through its own loop');
    if (!g || typeof g.step !== 'function') { row('not_assessed', 'window.game.step is missing: the starter check hooks were removed'); row('done', 0, '-', 'no hooks'); return; }
    var loopHook = !hookless && !!window.game && ('events' in window.game);
    var mode = q.get('bot') ? 'bot' : 'log', want = q.get('bot'), bot = null, log = null;
    if (mode === 'bot') {
      bot = window.BOT && window.BOT[want];
      if (typeof bot !== 'function') { row('not_assessed', 'bot.js has no BOT.' + want); row('done', 0, g.scene, 'no bot'); return; }
    } else {
      log = parseLog(q.get('log') || '', 2);
      if (log.bad.length) row('badinput', log.bad.join(' '));
    }
    var stopAt = q.has('stop') ? Number(q.get('stop')) : (mode === 'log' ? log.length + 30 : Infinity);
    var cap = Math.round((Number(q.get('cap')) || 600) / STEP);
    var quiet = q.has('quiet') ? Number(q.get('quiet')) : Infinity;
    var press = q.get('press') || '', pressFor = /^click:/.test(press) ? 1 : 2;
    var traceFrom = q.has('trace') ? Number(q.get('trace')) : Infinity;
    var scene = g.scene, reason = 'stopped', endAt = -1, endScene = '', playInput = false, leftEnd = false;
    var lastHash = screen().hash, lastChange = 0, sentAtChange = 0, staged = '';
    var simMs = 0, simMax = 0, simSteps = 0; // real time of step(1, false) alone: the steptime row
    var pr = { n: 0, sum: 0, min: Infinity, at: 0, low: 0 }; // state.margin in play: the pressure row
    var ft = { n: 0, sum: 0, max: 0, at: 0, o16: 0, o50: 0 }; // play frames, step and draw: the frametime row
    var ua = navigator.userAgent.match(/(HeadlessChrome|Edg|Chrome|Chromium)\/[0-9.]+/);
    row('ua', ua ? ua[0] : navigator.userAgent);
    row('scene', 0, scene); row('state', 0, scene, brief(g.state));
    for (stepNo = 0; ; stepNo++) {
      if (stepNo >= stopAt) { reason = 'stop'; break; }
      if (stepNo >= cap) { reason = 'cap'; break; }
      if ((stepNo & 63) === 0 && realNow() - started > REAL_LIMIT) { reason = 'real time'; break; }
      var keys = [];
      if (stepNo < quiet) {
        if (mode === 'bot') {
          try { keys = bot(view(g)) || []; } catch (e) { row('botfail', stepNo, e.message); reason = 'bot failed'; break; }
        } else if (stepNo < log.plan.length) keys = log.plan[stepNo];
      } else if (press && stepNo < quiet + pressFor) keys = [press];
      var before = sent;
      hold(keys);
      if (sent > before && g.scene === 'play' && !playInput) { playInput = true; row('playinput', stepNo, keys.join('+')); }
      var s0 = realNow();
      try { t += STEP; g.step(1, false); } catch (e) { row('crash', stepNo, e && e.message ? e.message : String(e)); reason = 'crash'; break; }
      var sd = realNow() - s0; simMs += sd; simSteps++; if (sd > simMax) simMax = sd;
      if (loopHook) loops.step(g, stepNo + 1);
      // Pressure: the game's state.margin in play, 1 safe and 0 lost (health left, food before the
      // stores run out, distance to the wall). Counted, never judged: the skill reads the numbers.
      var mg = g.state && g.state.margin;
      if (g.scene === 'play' && typeof mg === 'number' && isFinite(mg)) { pr.n++; pr.sum += mg; if (mg < pr.min) { pr.min = mg; pr.at = stepNo + 1; } if (mg <= 0.25) pr.low++; }
      if (stepNo >= traceFrom) { // the frame a person would see after this step
        try { g.step(0); } catch (e) { row('crash', stepNo + 1, e && e.message ? e.message : String(e)); reason = 'crash'; break; }
        row('frame', stepNo + 1, screen().hash);
      }
      if (g.scene !== scene) {
        if (loopHook) loops.scene(scene, g.scene, stepNo + 1, g);
        scene = g.scene; row('scene', stepNo + 1, scene); row('state', stepNo + 1, scene, brief(g.state));
        if (endAt >= 0 && !leftEnd && scene !== endScene) { row('left', stepNo + 1, endScene, scene); leftEnd = true; stopAt = Math.min(stopAt, stepNo + 61); }
        if (endAt < 0 && (scene === 'results' || scene === 'over') && mode === 'bot') { endAt = stepNo + 1; endScene = scene; row('end', endAt, scene); stopAt = Math.min(stopAt, endAt + 300); }
      }
      // A staged failure: the game sets state.staged while it shows one, and clears it when it
      // recovers. Whether the brief declares one is the skill's call, never the game's.
      var st = g.state && g.state.staged;
      if (st && !staged) { staged = String(st); row('staged', stepNo + 1, g.scene, staged); }
      else if (!st && staged) { staged = ''; row('recovered', stepNo + 1, g.scene); }
      // Stuck: the screen has not changed for ten seconds while new input went in. A timer
      // ticking in the state does not count; a player sees the screen.
      if ((stepNo % 60) === 59) {
        var f0 = realNow();
        try { g.step(0, true, 0.5); } catch (e) { row('crash', stepNo + 1, e && e.message ? e.message : String(e)); reason = 'crash'; break; }
        if (g.scene === 'play') { // this step's logic plus its drawing, flushed to pixels: one frame's cost
          flush(); var fd = sd + realNow() - f0;
          ft.n++; ft.sum += fd; if (fd > ft.max) { ft.max = fd; ft.at = stepNo + 1; }
          if (fd > 1000 / 60) ft.o16++; if (fd > 50) ft.o50++;
        }
        walk(g.state, '', 0);
        var now = screen().hash;
        if (now !== lastHash) { lastHash = now; lastChange = stepNo; sentAtChange = sent; }
        else if (stepNo - lastChange >= 600 && sent > sentAtChange) { row('stuck', stepNo + 1, scene, ((stepNo - lastChange) * STEP).toFixed(0), staged ? 'staged' : ''); lastChange = stepNo; sentAtChange = sent; }
      }
    }
    if (endAt >= 0 && !leftEnd && reason !== 'crash') row('noexit', stepNo, endScene);
    if (staged && reason !== 'crash') row('norecover', stepNo, g.scene, staged);
    // Keys written without setItem (localStorage.x = ...) still count as a save.
    try { if (!savedAny && window.localStorage.length) row('saved', stepNo, 'localstorage', '(' + window.localStorage.length + ' keys)'); } catch (e) { /* no storage */ }
    hold([]);
    walk(g.state, '', 0);
    row('state', stepNo, g.scene, brief(g.state));
    if (!hookless) loops.rows(mode === 'bot' ? want : 'log', loopHook);
    if (pr.n) row('pressure', pr.min.toFixed(2), pr.at, (pr.sum / pr.n).toFixed(2), Math.round(pr.low * 100 / pr.n), pr.n);
    else row('pressure', 'none', 'the game set no number state.margin in play');
    row('steptime', simSteps, (simSteps ? simMs / simSteps : 0).toFixed(3), simMax.toFixed(3));
    if (ft.n) row('frametime', ft.n, (ft.sum / ft.n).toFixed(1), ft.max.toFixed(1), ft.at, ft.o16, ft.o50);
    else row('frametime', 'none', 'no frame was drawn in play');
    row('done', stepNo, g.scene, reason, (stepNo * STEP).toFixed(1), Math.round(realNow() - started));
    // The frame is drawn and measured now, and again on every resize: headless Chrome sets the
    // window to its final size just before the screenshot, and a game that resizes its canvas
    // on that event has wiped it. one-shot-run.sh keeps the last measurement.
    var crashed = reason === 'crash';
    function measureFrame() {
      row('measured', innerWidth + 'x' + innerHeight);
      recording = true; texts = [];
      if (!crashed) { try { g.step(0); } catch (e) { crashed = true; row('crash', stepNo, e && e.message ? e.message : String(e)); } }
      recording = false;
      textRows(g.scene);
      var sc = screen();
      row('screen', stepNo, g.scene, sc.hash, sc.blank ? 'blank' : 'drawn');
    }
    measureFrame();
    window.addEventListener('resize', measureFrame);
    renderAudio(stepNo * STEP, function () {});
  });
})();
