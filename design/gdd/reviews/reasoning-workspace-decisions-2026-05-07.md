# Reasoning Workspace — Design Gate Decisions (2026-05-07)

> 2026-05-07 design-review (MAJOR REVISION NEEDED) 응답으로 작성된 3 design gate 결정 기록.
> 각 결정은 BLOCKING 항목을 닫고 cascade revision의 잠금 입력으로 작용한다.

---

## Gate ① — Tree (Forest) 잠금 (DAG 라벨 폐기)

**BLOCKING 대응**: §3.1 Rule 1 "DAG" vs single `parent_id` 스키마 모순 (game-designer + systems-designer)

### 결정

**케이스 종속 multi-root tree (forest)** 잠금. "DAG" 라벨은 GDD 전체에서 폐기.

- 가설 노드 자체는 forest of trees: `parent_id: String` (single) + `children: Array[String]`
- 다중 루트 허용 (`parent_id == ""` 노드 복수 OK — 병렬 가설)
- evidence (`library_id` 문자열 배열) 측에서 many-to-many 관계 허용 — 동일 `library_id`가 *다른* 노드에 동시 존재 가능 (Rule 4 기존 정책 유지)

### Rationale

1. **데이터 스키마 자체가 forest (tree of trees)** — `parent_id: String` 필드는 단일 부모. 진정한 DAG는 `parent_ids: Array[String]` 가 필요한데 그 전환은 chain_data export·invariant·serialization 모든 지점에서 cascade 비용 폭증.
2. **Player Fantasy의 "같은 판시 단락을 다른 가지에 옮겨붙이면" 약속은 *evidence 차원*의 many-to-many** — 가설 트리 자체가 DAG일 필요 없음. Rule 4 (`동일 ID 중복: 같은 노드 내 차단 / 다른 노드에 동일 ID는 허용`)가 이 약속을 이미 이행한다.
3. **Pillar 4 영속성 — Forest serialization은 well-defined** (각 노드 1개 부모 ID만 저장). True DAG 직렬화는 노드별 부모 set + 토폴로지컬 정렬 필요로 #3 Save/Load 의존성 비용 증가.
4. **Invariant 3 (Acyclicity)는 이미 tree property로 정의** — "≤ MAX_DEPTH 단계 내 root 도달"이 트리 사이클 부재의 충분 조건. DAG에서는 더 일반적인 cycle detection (DFS visited set) 필요.
5. **"DAG" 라벨은 *문서 부정확*** — 실제 동작은 forest. 라벨 정정만으로 BLOCKING 해소.

### Cascade impact

- §3.1 Rule 1 첫 문장: "DAG" → "케이스 종속 multi-root tree (forest)"
- §3.1 Rule 2: "다중 루트 허용 (병렬 가설 — `parent_id == ""`인 노드 복수 OK)" — 명시적 forest 정의 추가
- §5.2 EC `chain_data DAG 계약 보유 — 사이클 허용 시 직렬화 루프` → "chain_data forest 계약 보유" (정정)
- §4.3 `chain_coherence` 수식: forest 가정에 맞춰 `node_count == 1` div-zero 방어 (Gate ② 와 별도지만 같은 cascade)

### Pillar 4 약속 재해석

§2 Player Fantasy 두 번째 단락의 "같은 판시 단락을 다른 가지에 옮겨붙이면 그쪽이 굵어진다"는 이제 다음 두 메커니즘으로 분리되어 이행:

1. **Evidence 첨부 many-to-many** (Rule 4) — 동일 `library_id`가 다른 노드에 *동시* 존재 (move 아닌 add).
2. **Evidence 시각 가중** (Gate ② 결정의 bottom evidence rule) — 첨부된 evidence 수에 비례한 시각 굵기.

"옮겨붙이면"의 운영 정의: 사용자가 evidence 카드를 한 노드에서 다른 노드로 *드래그하여 이동*하면 source 노드 evidence 배열에서 제거 + target 노드 배열에 추가 (UI 동작; data 측 effect는 두 step). 시각: source의 bottom rule 짧아지고 target의 bottom rule 길어진다.

---

## Gate ② — Bottom Evidence Rule (border thickness modulation 폐기)

**BLOCKING 대응**: §8.1.1 evidence_density 0.125px subpixel 인지 한계 + selection state가 weight signal 압도 (art-director + systems-designer)

### 결정

evidence 시각 신호를 **별도 channel로 분리** — 노드 카드 *하단 가로 룰 (underline mark)*의 *길이*가 evidence 수에 비례. 기존의 보더 두께 modulation 폐기.

### 사양

| 변수 | 값 |
|---|---|
| 위치 | 노드 카드 하단 edge — 카드 외곽 보더 안쪽 즉시 inset 0px |
| 두께 | 2.0px (고정) |
| 색상 | 잉크블랙 `#1A1A1A` (Art Bible §3 line weight 표 — 활성 line) |
| 길이 | `(len(n.evidence) / EVIDENCE_PER_NODE_CAP) × node_width` — MVP cap=5 기준 0%·20%·40%·60%·80%·100% 6단계 |
| 정렬 | 카드 좌측 edge에서 right-grow (한국어 인쇄 관례 좌→우) |
| 추가/제거 | 0.15초 linear width tween (Art Bible §7 "문서 간 전환 0.15초 페이드" 정합) |

### Rationale

1. **인지 임계 충족** — 200×48px 카드 기준 20% 단계 = 40px. 1080p 1:1 매핑에서도 명백히 구분. subpixel 문제 종결.
2. **Selection signal과 channel 분리** — selection은 외곽 보더 두께 (binary 0.5/2.0px). evidence는 하단 룰 길이 (continuous 6 step). 두 신호가 동시 발화해도 충돌 없음.
3. **Pillar 1 ("진실은 가중치다") 직접 구현** — "인용이 쌓일수록 *밑줄이 길어진다*"는 한국 법조 문서 관례 (중요 부분 밑줄)와 일치. 인쇄 미학 직접 차용.
4. **Art Bible §3 "배경색 변화 없음" 준수** — 룰은 line element, 배경 채우기 아님.
5. **색맹 가드 정합** — 길이라는 spatial cue 단독 사용. Art Bible §4 색 단독 의존 금지 정합.

### 폐기 / 변경

- **폐기**: §8.1.1 `evidence_density modulated` 행 (border 두께 ρ-modulation).
- **변경**: §4.4 `evidence_density(n)` 수식은 유지하되 의미 재정의 — "노드 하단 룰 길이의 비율 ρ ∈ [0,1]"로 사용. 보더 두께 modulation 언급 제거.
- **신규**: §7.3 knob `evidence_density_modulation_strength` (default 0.5) 폐기 → `evidence_rule_visible` (bool, default true) + `evidence_rule_thickness_px` (float, default 2.0, range 1.5–3.0).
- **AC-37**: 측정 protocol 보강 — "노드의 bottom rule 길이가 evidence 수와 일치 (0/1/3/5 케이스 각각 0%·20%·60%·100% width 일치, ±2px 허용)".

### 트레이드오프 — 검토 후 수용

- **장점**: 인지 가능, channel 분리, Pillar 1 직접 구현, 색맹 안전, 문서 미학 정합.
- **단점**: (a) 카드 하단 inner padding 미세 변경 — text vertical center 재조정 필요 (Art Bible §3.1 200×48px 기준 padding 확인 의무). (b) 기존 §8.1.1 modulation 행 + §7.3 knob 명세 cascade 수정 5개 지점.
- **수용**: 단점 (a)는 art-director가 §8.1.1 revision 시 padding 명시. 단점 (b)는 본 cascade 작업의 일부.

---

## Gate ③ — Signal Topology Contract Lock (구체 emitter는 Workspace Layout ADR 위임)

**BLOCKING 대응**: §3.3 dual emitter 모호 + Browser autoload-or-scene 미명세 + drag-drop API 선택 미결 (godot-specialist B-1) + Rule 7 freeze 동기/비동기 모순 (godot-specialist B-2)

### 결정 — B-1: Signal contract lock + emitter 위임

§3.3에서 시그널의 **계약 (semantics + payload)**만 잠그고, 구체 *emitter (autoload vs scene node)*와 *전달 채널 (signal vs Godot native drag-drop API vs hybrid)*은 Workspace Layout ADR에 위임.

#### Locked contract (구체 emitter 무관)

| 시그널 의미 | 페이로드 | Workspace 측 책임 | 본 GDD 잠금 사항 |
|---|---|---|---|
| Drag started | `library_id: String` | DeskPane drop zone hint 활성 (Workspace State == ACTIVE 일 때만) | exactly-once delivery per drag-start; FROZEN/READ_ONLY 상태에서는 hint 비활성 |
| Drop completed | `library_id: String, viewport_position: Vector2` | hit-test → target node 결정 → Rule 4 정책 적용 | drop은 source가 어디든 Workspace Boundary에서 검증 |

§3.3 시그널 표의 "발신자" 컬럼은 본 GDD에서 **`Library Subsystem (실제 emitter는 Workspace Layout ADR 결정)`** 단일 라벨로 통일. Library §3.2 CitationDrop state는 시그널 발화 *책임*만 정의 — 어느 클래스가 emit 하는지는 ADR 결정.

#### Workspace Layout ADR 결정 사항 (deferred — TODO 명시)

- LibraryService autoload가 emit하는가, LibraryPane scene node가 emit하는가
- Godot 4.6 native drag-drop API (`_get_drag_data`/`_can_drop_data`/`_drop_data`)를 사용하는가
- "drag started" 만 signal로, "drop completed"는 native callback으로 분리하는 hybrid 채택 가능성

### 결정 — B-2: Freeze 동기 transition + async evaluation

§3.1 Rule 7 freeze 타이밍을 명시 잠금:

1. **Workspace state transition은 동기 (synchronous)**: Submit 클릭 → Workspace는 *즉시* (단일 frame 내) `ACTIVE → FROZEN` 전환 + chain_data Dictionary 빌드 + PlayerSubmission에 할당.
2. **`EvaluationService.submit(submission)` 호출은 동기적으로 발생**: chain_data 빌드 직후 동일 frame에서 호출. submit() 내부의 `EvaluationService.current_state` 머신은 비동기 진행 (ADR-0007 §2 5-state machine).
3. **Workspace는 submit() 반환을 await하지 않는다** — fire-and-forget. UI 차단은 FROZEN 상태가 보장 (입력 무시 + 오버레이 배너).
4. **상태 복귀는 시그널 콜백 한정**: `submission_rejected` → `FROZEN → ACTIVE`; `evaluation_completed` → `FROZEN → READ_ONLY`. Workspace는 `EvaluationService` 내부 진행을 polling 하지 않는다.

### Rationale

- **B-1 위임의 정당성**: 시그널 발신자/채널은 *UI scene tree topology*에 종속 — DeskPane이 LibraryPane의 sibling인지 child인지에 따라 native API가 자연 fit이거나 autoload signal이 필요. UI Foundation epic + Workspace Layout ADR이 scene tree를 결정하기 전에 잠그면 premature commitment.
- **B-1 contract lock의 충분성**: 본 GDD의 *행동 명세 (Rule 4 evidence 정책 + Workspace State guard + drop zone hint)*는 emitter-agnostic — 어떤 채널로 들어오든 동일하게 처리. 따라서 GDD 수준에서는 contract만으로 충분.
- **B-2 동기 transition 명시 필요성**: 현 Rule 7 텍스트가 "submit() 호출 직전 FROZEN 전환"을 명시했으나 *호출 완료* 와 혼동 가능. 동기/비동기 boundary를 명시하면 ADR-0007 §2 EvaluationService 5-state 머신과 자연 정합.

### Cascade impact

- §3.3 시그널 표 "발신자" 컬럼: `LibraryService / LibraryPane` → `Library Subsystem (Workspace Layout ADR)`
- §3.3 페이로드/Workspace 측 처리는 변경 없음 (이미 emitter-agnostic).
- §3.1 Rule 7: "Freeze 트리거" 항목 동기 전이 + fire-and-forget 명시.
- §3.2 State machine 표 ACTIVE row: Submit 클릭 → FROZEN 전이의 동기성 명시.
- §6.4 Pending 의존성에 "Workspace Layout ADR — signal topology + drag-drop API decision" 추가.
- 신규 OQ entry: **OQ-W13 — signal topology + drag-drop API choice** (Workspace Layout ADR 위임).

### 위임 검증

Workspace Layout ADR이 본 contract를 위반하지 않으려면 다음 4 invariant를 보장해야 한다 (ADR 작성 시 본 결정 인용 의무):

1. Drag-start notification은 정확히 1회 per drag — 누락 시 drop zone hint 미활성, 중복 시 hint flicker.
2. Drop-completion notification 페이로드에 `library_id` + `viewport_position` (또는 동등 hit-target reference) 필수.
3. Workspace State == FROZEN/READ_ONLY 시 native drag-drop API의 `_can_drop_data` callback이 false 반환 의무 (또는 signal 채널의 drop 무시).
4. Library Subsystem은 Workspace의 hit-test 결과 (drop 수락/거부)를 직접 관찰하지 않음 — Workspace 자기 책임.

---

## Decision summary

| Gate | Decision | BLOCKING 닫힘 |
|---|---|---|
| ① | Forest of trees (DAG 라벨 폐기) | game-designer #1, systems-designer #1, EC §5.2 (chain_data 라벨) |
| ② | Bottom Evidence Rule (border modulation 폐기) | art-director #6, systems-designer #7 |
| ③ | Signal topology contract lock + Workspace Layout ADR 위임; freeze 동기 transition 명시 | godot-specialist B-1, godot-specialist B-2 |

남은 BLOCKING (§4.3 div-zero, §3.1 Rule 6 schema_version gate, AC-37/47/50 측정 protocol, AC-24 byte-identical, §9.4.1 Ctrl+drag 컨벤션, §3.1 Rule 2 depth ≤ 3 vs 4계층) — Cascade revision (Task #4) + Mechanical revision (Task #5)로 처리.

---

## Pillar 정합 자가검수 (post-decision)

Per `feedback_domain_authenticity` 메모리 — 결정 후 즉시 한국 상고심 도메인 + 5 Pillar 정합 sanity check.

- **Gate ①** Forest 잠금: ✅ 한국 상고심 변호사 사고 모델 — *상고이유 1·2·3 병렬 + 각 이유 아래 쟁점 분기*는 forest 자연 표현. DAG 모델이 요구하는 "한 쟁점이 두 상고이유의 자식"은 한국 법조 문서 관례 외 (공유 쟁점은 별도 메모로 표현; 트리 구조는 분리 유지).
- **Gate ②** Bottom Evidence Rule: ✅ 한국 법조 문서의 *밑줄 강조 관례* 직접 차용. 인쇄 미학 + Pillar 1 시각화. 위반 안전.
- **Gate ③** Contract lock + freeze 동기: ✅ 동기 freeze는 "submit 직후 사후 편집 차단"이라는 Pillar 1 가드를 frame-precision 으로 보장. ADR-0007 §3.2 forward-constraint와 1:1 정합.

3 결정 모두 5 pillar + 도메인 진정성 위반 없음.
