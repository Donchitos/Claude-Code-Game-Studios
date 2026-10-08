# /setup-engine — Section 6: Determine Knowledge Gap

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 6. Determine Knowledge Gap

Check whether the engine version is likely beyond the LLM's training data.

**Known approximate coverage** — the same figures the shipped
`docs/engine-reference/*/VERSION.md` files record:
- LLM knowledge cutoff: **May 2025**
- Godot: training data likely covers up to ~4.3
- Unity: training data likely covers up to ~2022 LTS (2022.3)
- Unreal: training data likely covers up to ~5.3

> **This table goes stale silently, and a stale table fails in the dangerous
> direction only if it is too *new*.** A cutoff left unchanged for a year after
> it stopped being true over-classifies risk — safe, but every project then pays
> for full reference docs it may not have needed.
> The opposite error is the harmful one: a cutoff claimed *later* than the model's
> actual one marks post-cutoff versions LOW RISK and suppresses the reference
> docs that exist to stop invented APIs.
>
> **If the model running this skill states an earlier training cutoff than the
> one above, do not trust the table.** Say so, and treat the engine version as
> `HIGH RISK` regardless of the comparison — a cutoff the model does not have is
> not a cutoff that was met.

Compare the user's chosen version against these baselines:

- **Within training data** → `LOW RISK` — reference docs optional but recommended
- **Near the edge** → `MEDIUM RISK` — reference docs recommended
- **Beyond training data** → `HIGH RISK` — reference docs required

Inform the user which category they're in and why.

---
