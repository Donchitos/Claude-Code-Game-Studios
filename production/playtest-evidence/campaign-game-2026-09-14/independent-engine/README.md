# Independent engine review provenance

Reviewer task: `01a09f37-603d-7513-8d7e-a4ab59584c1c` (independent Godot/engine reviewer). Content/Profile author only copied these final logs, scripts and hash manifest from `/tmp/campaign_review*`; the copied test results were not authored or rerun by the content worker.

**Final follow-up:** B changed four files after the captured run. A fresh independent reviewer completed a targeted four-file delta review; see [final-delta-review.md](final-delta-review.md). The old full approval remains bound to 80344; this does not relabel the newer code as having had another full review.

Reported verdict: **APPROVED WITH SUGGESTIONS**, no remaining confirmed P1/P2 in the reviewed scope. Exit-time 2 ObjectDB / 1 resource warnings warrant test-cleanup investigation; they do not establish a steady-state memory leak.

The captured combined code/content hash is `80344fabc5d84fbbde69d9471485faaee986a7e5159cd11e7ff3d633807a62b8`; per-file hashes are preserved verbatim. Its catalog hash is `5957087f594365fc554e762edd31ef97294bf5bc4d456d108b46e548a8a58223`. The later frozen catalog `71d615925151600c8a1255808f20a03d5d44f5fa4efd9f047874e231f45949ca` updates player-facing descriptions; do not relabel the older evidence as having run against the new byte hash. Follow-up reviewer confirmation, if supplied, must retain its own provenance.

Coverage: nine targeted counterexamples; 11 malicious codec cases; real `/tmp` dual-slot save at tick 237, new Storage/Profile, restore and exact advance to tick 437; 1000 transient-grid/full-scan oracle comparisons; root input flow; CPU tick performance (Apple M4 / Godot 4.7.1, 180 enemies × 400 projectiles, warmup 120 ticks, 600 samples). Performance is neither rendered FPS nor disk IO or Windows hardware evidence.

See `../` for separate independent QA journey evidence. Synthetic/high-HP probes are not a fresh-profile 64-mission campaign run.
