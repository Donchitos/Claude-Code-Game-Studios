# Arquitetura da Fatia Vertical — Clube do Bairro

Rigor mínimo: contrato de implementação, **não** é ADR, control manifest nem TR registry. Godot 4.7 / GDScript. 6 semanas, exatamente 1 decisão por semana. **Nenhum número é hardcoded em `.gd`** — todo valor vem de `data/economy.json`; strings de decisão/outcome são literais.

## Fluxo de dados

`data/economy.json` → `FileAccess` + `JSON.parse_string` → `Dictionary cfg` → `ClubState.new(cfg)` → `apply_decision(decisão)` → `MatchResult.compute_force/points_for` → sinais `turn_resolved` / `run_ended` → Labels e painel em `main.gd`. Sem autoload/singleton: `ClubState` é `RefCounted` puro, sem nó e sem conhecer a UI. O smoke usa o mesmo `ClubState` direto, sem cena.

## Schema de `data/economy.json` (chaves exatas)

| Chave | Valor | Uso |
|---|---|---|
| `schema_version`, `title` | `1`, `"Clube do Bairro"` | metadados |
| `weeks`, `target_points`, `starting_cash` | `6`, `7`, `5000` | duração, meta, caixa inicial |
| `salary`, `austerity_salary` | `1200`, `600` | salário normal / com corte |
| `gate_receipts.base`, `gate_receipts.per_level` | `800`, `400` | bilheteria |
| `reinforcement.cost`, `reinforcement.strength_bonus` | `1500`, `1` | reforço |
| `facility.upgrade_cost`, `facility.max_level`, `facility.start_level` | `2000`, `3`, `1` | instalação |
| `match.starters_strength`, `match.crowd_penalty` | `1`, `1` | força por titular / por corte |
| `match.win_threshold`, `match.draw_threshold` | `3`, `2` | limiares da partida |
| `match.points_win`, `match.points_draw`, `match.points_loss` | `3`, `1`, `0` | pontos por resultado |
| `bankruptcy_below` | `0` | limite de falência (`cash <`) |
| `decisions` | `["escalar_titulares", "contratar_reforco", "melhorar_instalacao", "cortar_gastos"]` | decisões válidas |

## Contrato por arquivo

**`src/match_result.gd` (T4)** — `class_name MatchResult`, apenas funções `static`, sem estado.
- `static func compute_force(started: bool, reinforcements: int, facility_level: int, cut_costs: bool, cfg: Dictionary) -> int` = `started*cfg.match.starters_strength + reinforcements*cfg.reinforcement.strength_bonus + (facility_level - cfg.facility.start_level) - (1 if cut_costs else 0)*cfg.match.crowd_penalty`.
- `static func points_for(force: int, cfg: Dictionary) -> int`: `force >= cfg.match.win_threshold → cfg.match.points_win`; senão `>= cfg.match.draw_threshold → cfg.match.points_draw`; senão `cfg.match.points_loss`.

**`src/club_state.gd` (T4)** — `class_name ClubState extends RefCounted`; sem autoload.
- Campos públicos: `config: Dictionary`, `week: int`, `cash: int`, `points: int`, `facility_level: int`, `reinforcements: int`, `ended: bool`, `outcome: String`.
- Sinais: `turn_resolved(state: ClubState, summary: Dictionary)`, `run_ended(state: ClubState, outcome: String)`.
- Constantes: `OUTCOME_VICTORY = "victory"`, `OUTCOME_BANKRUPTCY = "bankruptcy"`, `OUTCOME_DEFEAT = "defeat"`; vazio `""` enquanto corre.
- `_init(config: Dictionary) -> void`: `week=1`, `cash=config.starting_cash`, `points=0`, `facility_level=config.facility.start_level`, `reinforcements=0`, `ended=false`, `outcome=""`.
- `apply_decision(decision: String) -> Dictionary`: se `is_finished()` → `{}` sem sinais. Ordem: custo → falência → partida/pontos → bilheteria − salário → falência → meta. Decisões exatas: `config.decisions` (`escalar_titulares`, `contratar_reforco`, `melhorar_instalacao`, `cortar_gastos`). Reforço debita `config.reinforcement.cost` e incrementa `reinforcements`; reforma debita `config.facility.upgrade_cost` e faz `min(N+1, config.facility.max_level)` (no máximo: sem custo e sem incremento); escalar/cortar são flags da semana. `force` usa `MatchResult`; `points_gained` usa `points_for`. Bilheteria − salário: `cash += cfg.gate_receipts.base + cfg.gate_receipts.per_level * facility_level - (cfg.austerity_salary se corte, senão cfg.salary)`. `cash_delta` = variação total da semana (antes da decisão → depois). Falência (`cash < cfg.bankruptcy_below`) após **qualquer** mutação encerra na hora: `outcome="bankruptcy"`, sem bilheteria/salário/partida subsequentes (`force=0`, `points_gained=0`) e prevalece sobre a semana final. Na semana `cfg.weeks` sobrevivente: `victory` se `points >= cfg.target_points`, senão `defeat`. Emite `turn_resolved` uma vez por decisão, sempre antes de `run_ended`.
- `summary`: `week, decision, force, points_gained, cash_delta, cash, total_points, facility_level, reinforcements, outcome`.
- `is_finished() -> bool` (retorna `ended`); `get_outcome() -> String`; `snapshot() -> Dictionary` com os campos públicos (cópia fresca).

**`src/main.gd` (T4)** — `extends Control`. `_ready()`: ler `res://data/economy.json` com `FileAccess`, instanciar `ClubState`, conectar os 4 botões (`pressed.connect(_on_decision.bind(<decisão>))`) e os 2 sinais. `@onready` para `$WeekLabel`, `$CashLabel`, `$PointsLabel`, `$FacilityLabel`, `$EndPanel/ResultLabel`, `$EndPanel/RestartButton`. `turn_resolved` atualiza os 4 Labels; `run_ended` desabilita os 4 botões, mostra `EndPanel` e preenche `ResultLabel`; reiniciar cria `ClubState.new(cfg)` novo, reconecta, reabilita e esconde o painel.

**`scenes/main.tscn` (T5)** — raiz única `Control` com `script = res://src/main.gd`; filhos diretos exatos: `WeekLabel`, `CashLabel`, `PointsLabel`, `FacilityLabel` (Labels), `EscalarButton`, `ContratarButton`, `MelhorarButton`, `CortarButton` (Buttons) e `EndPanel` (Panel, `visible = false`) contendo `ResultLabel` e `RestartButton`. T5 define depois `run/main_scene="res://scenes/main.tscn"`.

**`tests/smoke/run_smoke.gd` (T7)** — `extends SceneTree`; carrega o mesmo JSON e roda 3 cenários com `ClubState` puro: (1) vitória — reforço s1, reforma s2, escalar s3–s6 → 13 pts/`victory`; (2) falência — reforço s1, reforma s2, reforma s3 → caixa negativo na semana 3, `bankruptcy` em `week == 3`, `points_gained == 0`; (3) derrota — escalar titulares nas 6 semanas → **0 pts** (`F = 1 < cfg.match.draw_threshold`, pois escalar sozinho não atinge o limiar)/`defeat`. Usa `assert(cond, msg)` e guarda explícita com `quit(1)` em qualquer falha; só no sucesso imprime `SMOKE OK` e chama `quit(0)`.
