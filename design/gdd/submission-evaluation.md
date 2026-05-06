# Submission & Evaluation

> **Status**: Designed (skeleton 2026-05-05; lean review revisions applied 2026-05-06)
> **Author**: kjuioqq8@gmail.com + game-designer + systems-designer
> **Last Updated**: 2026-05-06
> **Layer**: Feature
> **Priority**: MVP
> **Implements Pillar**: 1 (Truth Is Weighted) + Anti-Pillar 가드 (정답/오답 이분 평가 거부)
> **Source Concept**: design/gdd/game-concept.md
> **Position in Index**: #9 in design order
> **Architectural Backing**: ADR-0007 (Submission Evaluation Algorithm) — Proposed 2026-05-06 — closes OQ-2 4건; ADR-XXXX (v1+ Chain Coherence Algorithm) deferred

---

## 1. Overview

*Submission & Evaluation*은 플레이어가 #7 Brief Editor에서 작성한 상고이유서(채택한 처분 + 인용한 Library ID 목록 + (v1+) 추론 체인 데이터)를 입력받아 *가중 평가*를 수행하는 코어 평가 시스템이다. case-data-schema가 케이스마다 보유하는 `scoring_weights` Dictionary와 `correct_disposition` / `correct_citations`를 기준 데이터로, 플레이어 제출물에 대해 5개 subscore(MVP 활성: `disposition_match` + `core_citation_coverage` + `redundant_citation_penalty` / v1+ 활성: `chain_coherence` + `precedent_seniority_bonus`)를 계산하고 `case.scoring_weights[k] × subscores[k]`로 가중 합산한 단일 점수와 함께 *결정문 결과*(파기/기각/각하/파기환송)·*subscore 항목별 한 줄 코멘트*를 산출한다. 핵심 설계 원칙은 ADR-0003에서 케이스 측이 결정한 *알고리즘은 코드, 가중치는 데이터* — 본 GDD는 알고리즘 명세를 정의하고 가중치는 case .tres에 외부화된다. Pillar 1(*진실은 가중치다*)의 직접 구현체이며, Anti-Pillar 가드로 `case_disposition_match_minimum_weight = 0.4` 잠금에 의해 *처분만으로 결판이 나지 않도록*(최소 60%는 인용 + 추론 측에서 결정) 강제한다. MVP는 단순 정답 비교(처분 일치 + 인용 매칭률 + 무관 인용 페널티)로 가설 검증에 집중하고, "추론 체인의 질" 측 평가(`chain_coherence`)는 v1+로 분리되어 자문가 검수 후 본격 도입한다 — 이 *MVP/v1+ 분리선*이 본 GDD의 핵심 디자인 결정이다. 책임 경계: 본 GDD는 *평가 알고리즘*만 정의하며, 결정문 *연출*은 #10 Verdict Reveal Sequence, 결과 *보존·재플레이*는 #11 Career Progression의 책임이다.

---

## 2. Player Fantasy

상고이유서 봉투를 닫고 *제출* 버튼을 누른 직후의 정적 — 이 게임에서 가장 짧고 가장 무거운 순간이다. 더는 추가 자료를 찾을 수도, 가설 트리를 다듬을 수도, 인용을 빼고 더할 수도 없다. 결정은 떠났고 며칠이 흐른다. 결정문 봉투가 책상에 도착하고(그 *연출*은 #10 책임), 봉투가 열리는 순간 플레이어가 보는 것은 처분 한 줄(*파기·기각·각하·파기환송*)과 — 그 *직후* 이 시스템이 산출하는 *subscore breakdown*이다. 처분 일치 여부, 인용한 법령·판례 중 어느 것이 핵심이었고 어느 것이 무관했는지, 어떤 인용을 누락했는지가 가중치별 막대로 펼쳐지고 *한 줄 코멘트*가 따라온다 — *이 인용은 핵심이었다 / 이 인용은 본 사건과 거리가 있다 / 핵심 판시 1건을 누락했다*. 플레이어가 받는 감각은 "정답을 맞췄다/틀렸다"가 아니라 *내 추론 체인의 무게가 어떻게 분포되었는가*다. 단일 정답을 채점받는 학원형 평가가 아닌, *법조계가 변호사를 평가하는 방식*에 가까운 구조 — 결론보다 그 결론에 도달한 가중 정당화가 채점된다. 이 감각이 Pillar 1(*진실은 가중치다*)을 player-facing으로 직접 구현하며, Anti-Pillar 가드("정답/오답 이분 평가 거부")의 가시화 지점이다. *케이스가 끝나도 따라온다*(Pillar 4)는 잔향은 결정문 처분만이 아니라 *어느 인용이 자기 추론에 깊이 박혔는가*에서 온다 — 다음 케이스에서 같은 판례를 만났을 때 플레이어는 *그때 그 판례*라는 잔향을 느낀다.

---

## 3. Detailed Rules

### 3.1 Core Rules

#### 3.1.1 Submission 입력 데이터 셋 (PlayerSubmission 클래스)

#7 Brief Editor가 *Submit* 트리거를 누른 시점에 본 시스템에 전달되는 입력 Resource:

| 필드 | 타입 | 의미 |
|------|------|------|
| `case_id` | String | 평가 대상 케이스의 ID (`case_data:[year]-[seq]`) |
| `player_disposition` | String | 플레이어가 채택한 처분 — `library_dispositions_court` enum 멤버 |
| `player_citations` | Array[String] | 플레이어가 인용한 Library ID 목록 (인용 순서 보존) |
| `chain_data` | Dictionary (v1+) | 추론 체인 노드·엣지·근거 인용 매핑 (#6 Workspace export) — MVP는 비어있음 |
| `submission_time_ms` | int | 작성 소요 시간 (텔레메트리용, 평가에는 미반영) |

PlayerSubmission도 mirror principle 적용 — 정적 타입 GDScript Resource 클래스 (ADR-0001/0003 패턴 mirror). 인용 순서는 보존되지만 평가 함수는 *순서 무관* (Set 비교 + 가중 매칭) — 순서는 #14 Retrospective Replay 표시용.

#### 3.1.2 Submission 검증 (Pre-evaluation Gate)

평가 시작 전 다음 검사 수행 — 미통과 시 *비활성화* 결과 반환 (계산 X, 콘솔 push_error):

1. `case_id`로 `CaseService`에서 활성 케이스 1건 조회 가능
2. `player_disposition`이 `library_dispositions_court` enum 멤버
3. `player_citations.size() >= 1` (빈 인용 거부 — EC-1)
4. `player_citations[*]`가 모두 `LibraryService.validate_citations()` 통과 (미존재 ID 거부 — EC-2)
5. **`chain_data` schema validation (reasoning-workspace 2026-05-07 cycle 2 BLOCKING closure — Pillar 1 silent regression dual-layer guard)** — `chain_data == {}` 또는 `chain_data["schema_version"] == 1`이면서 다음 allow-list 정합:
   - Top-level keys: `src/data/chain_data_schema.gd`의 `SCHEMA_V1_ALLOWED_FIELDS = ["schema_version", "nodes", "edge_count", "max_depth_reached", "total_evidence_count"]` 외 키 부재
   - 각 `nodes[i]` keys: `SCHEMA_V1_NODE_FIELDS = ["node_id", "label", "depth", "parent_id", "evidence", "memo_length", "child_count"]` 외 키 부재
   - 비허용 필드 검출 시 `submission_rejected("schema_violation:[field_name]")` emit + `push_error("chain_data schema_version=1 violation: forbidden field %s")`. 본 검증은 `src/data/chain_data_schema.gd`의 동일 const를 import하여 reasoning-workspace 빌더의 allow-list와 *single source of truth* 공유 — 양쪽 inline 정의는 forbidden_pattern `chain_data_schema_allow_list_duplication` (architecture.yaml registry 등록 의무).

검증 통과 시 §3.1.3로 진행, 실패 시 평가 중단 + UI에 *제출 거부* 메시지 (단순 정답 비교 의미가 사라지므로 평가 자체 X).

#### 3.1.3 5 Subscore 정의

각 subscore는 [0.0, 1.0] 범위 (penalty는 [-0.3, 0.0]). MVP/v1+ 활성 분리:

| Subscore | MVP/v1+ | 측정 대상 | 의미 |
|----------|---------|-----------|------|
| `disposition_match` | **MVP** | `player_disposition == case.correct_disposition` | 처분 일치 — 1.0 또는 0.0 (이산) |
| `core_citation_coverage` | **MVP** | player_citations ∩ correct_citations | 정답 인용 매칭률 (Set 기반 Jaccard 변형) |
| `redundant_citation_penalty` | **MVP** | player_citations \ correct_citations | 무관 인용 페널티 (음수 — Anti-Pillar 가드) |
| `chain_coherence` | **v1+** | chain_data 노드의 인용 근거 적합도 | 추론 체인 자체의 일관성 — 본 GDD MVP scope 외 (§OQ-1) |
| `precedent_seniority_bonus` | **v1+** | 인용한 판례의 court_grade 분포 | 전합 인용 보너스 — `case.scoring_weights[..].seniority_bonus = 0` 잠금 (Anti-Pillar 가드, case-data-schema AC-10 mirror) |

**MVP 동작 잠금**: MVP 모든 케이스의 `scoring_weights.chain_coherence = 0` + `scoring_weights.precedent_seniority_bonus = 0`. 가중치 0이므로 이 두 subscore는 평가 결과에 영향이 없음 — *알고리즘은 v1+에 대비해 5 키 모두 구현*하되 *데이터 가중치만 0*으로 잠금. 이 분리가 v1+ 활성 시 코드 변경 없이 데이터 변경만으로 이행 가능하게 만든다.

#### 3.1.4 Final Score 합산 + Verdict 결정

```
final_score = (disposition_match × W_disp)
            + (core_citation_coverage × W_core)
            + (redundant_citation_penalty × W_redund)   # 음수
            + (chain_coherence × W_chain)               # MVP=0
            + (precedent_seniority_bonus × W_senior)    # MVP=0
```

여기서 `W_*`는 `case.scoring_weights[k]`로부터 직접 읽음. final_score는 [0.0, 1.0] 범위로 정규화 (clamp).

**Verdict 결정** (game-concept 5 Pillar + case-data-schema `library_dispositions_court` 4 enum 멤버를 *플레이어 결과*에 매핑):

```
verdict = (
    "파기"      if (player_disposition == correct_disposition AND final_score >= 0.7)
    else "파기환송" if (player_disposition == correct_disposition AND final_score >= 0.3)
    else "기각"   if (player_disposition != correct_disposition AND final_score >= 0.3)
    else "각하"
)
```

이 매핑은 *Pillar 1 가시화* — 처분 일치만으로 "파기"가 보장되지 않는다. 인용·추론 측 가중 점수가 0.7 이상이어야 *파기* 카타르시스. 0.3-0.7 구간 처분 일치는 *파기환송* (방향은 맞았지만 근거가 부족 — disp 일치 신호는 보존되어 "다시 시도 가능" 학습 곡선 유지). 처분 불일치라도 0.3 이상은 *기각* (논거는 있었으나 결론이 빗나감). 0.3 미만은 *각하* (처분 일치 여부 무관 — 분석 자체가 성립 X).

한국 법조계 실무에서 *각하*는 절차적 부적법(관할권·당사자적격 결여) 전용이고 본안 부실은 *기각*이지만, 본 게임의 verdict label은 *플레이어 추론의 무게* 측면에서 재의미화된다 — final_score < 0.3은 *논거의 무게가 측정 가능한 임계 미달* 상태이므로 *각하*. 이 라벨 의미론은 OQ-7 변호사 자문 시 재검토.

#### 3.1.5 Comment Generation (한 줄 코멘트)

각 subscore에 대해 결정 트리로 단일 코멘트 1건 생성. *코멘트 내용은 외부 데이터*(MVP는 entities.yaml 또는 별도 .tres comment_templates) — 알고리즘은 *어느 코멘트를 보일지*만 결정. 본 GDD는 코멘트 *템플릿 키 목록*만 정의하고 한국어 본문은 콘텐츠 작성 시점에 작성:

| Subscore | 조건 | 템플릿 키 |
|----------|------|-----------|
| `disposition_match` | 1.0 | `comment.disp.match` |
| `disposition_match` | 0.0 | `comment.disp.miss` |
| `core_citation_coverage` | ≥ 0.8 | `comment.core.high` |
| `core_citation_coverage` | 0.4-0.8 | `comment.core.mid` |
| `core_citation_coverage` | < 0.4 | `comment.core.low` |
| `redundant_citation_penalty` | ≥ -0.05 | `comment.redund.clean` (penalty 거의 없음) |
| `redundant_citation_penalty` | < -0.05 | `comment.redund.bloat` (무관 인용 다수) |

총 코멘트 템플릿 7건 (disp: 2 + core: 3 + redund: 2). v1+ chain 코멘트는 별도. 코멘트 본문 톤은 #13 Persona System(멘토)이 작성 시 절제된 코멘트 — 본 GDD는 *문법 슬롯*만 정의.

#### 3.1.6 EvaluationResult (출력 데이터 셋)

평가 완료 시 본 시스템이 산출하는 출력 Resource:

| 필드 | 타입 | 의미 |
|------|------|------|
| `case_id` | String | 평가 대상 케이스 ID |
| `final_score` | float | [0.0, 1.0] 정규화 |
| `verdict` | String | 결정문 처분 — `library_dispositions_court` 4 enum 멤버 |
| `subscores` | Dictionary | 5 키 → float (penalty 음수 허용) |
| `weighted_contributions` | Dictionary | 5 키 → float (각 subscore × weight, 합 = final_score) |
| `comments` | Array[String] | 활성 템플릿 키 → 본문 치환된 코멘트 목록 |
| `correct_set` | Array[String] | player가 매칭한 correct_citations (UI 표시용) |
| `missed_set` | Array[String] | player가 누락한 correct_citations |
| `redundant_set` | Array[String] | player가 인용했지만 무관한 citations |
| `evaluated_at` | int | Unix timestamp ms |

EvaluationResult는 #10 Verdict Reveal Sequence가 봉투 연출 입력으로 사용하고, #11 Career Progression이 케이스북에 보존하며, #14 Retrospective Replay가 subscore breakdown 표시에 사용한다. 또한 mirror principle 적용 (정적 타입 Resource — ADR-0001/0003 패턴).

### 3.2 States and Transitions

본 시스템은 *호출형 평가 함수*가 아니라 *상태를 가진 서비스*다 (`EvaluationService` autoload). case lifecycle (`Submitted` → `Resolved`)와 별도의 평가 *진행* 상태:

| State | 설명 | 트리거 |
|-------|------|--------|
| `Idle` | 평가 대기 — Submission 미수신 | 초기 상태, Reporting 후 복귀 |
| `Validating` | §3.1.2 검증 수행 | `submit(submission)` 호출 |
| `Computing` | §3.1.3 + §3.1.4 평가 계산 | Validating 통과 |
| `Reporting` | §3.1.5 + §3.1.6 결과 산출 + 시그널 emission | Computing 완료 |
| `Done` | EvaluationResult 시그널 송출, Idle 복귀 대기 | Reporting 완료 |

검증 실패 시 Validating → `Idle` 복귀 + `submission_rejected(reason)` 시그널. 정상 흐름은 Idle → Validating → Computing → Reporting → Done → Idle.

이 상태 머신은 case-file-browser §AC-20 메모 휘발 정책의 *Workspace 측 동치 정책*에 영향: 본 시스템 진입(=`submit()` 호출) 시점에 #6 Workspace의 메모 영역은 *불가변 스냅샷*으로 freeze된다 (재제출 차단 — case lifecycle `Submitted` 상태 잠금과 mirror). 즉 *제출 후에는 추론 트리 수정 X* — Pillar 1 가드 (제출 후 후속 수정으로 사후 정당화 방지). **[#6 forward-constraint]**: #6 Reasoning Workspace 디자인 시 본 freeze 계약(submit() 시점에 workspace memo 불가변)을 #6 측 행동 계약에 통합 필수 — 본 GDD가 #6 v1+ 디자인의 *행동 계약 일부*를 사전 잠금.

### 3.3 Interactions with Other Systems

- **#1 Case Data Schema**: `CaseService.get_case(case_id)` → `correct_disposition` + `correct_citations` + `scoring_weights` 입력. 본 시스템은 케이스 데이터를 *읽기 전용*으로만 접근.
- **#5 Case File Browser**: Browser 상태 `SubmissionPending` ↔ 본 시스템 `Validating`/`Computing`/`Reporting`. EvaluationResult 산출 후 `evaluation_completed(result)` 시그널 → Browser가 `VerdictArrived`로 전이. (case-file-browser entities.yaml `case_browser_states` 정합)
- **#6 Reasoning Workspace** (v1+): `chain_data` Dictionary 입력. MVP는 빈 Dict 허용. v1+ chain_coherence 활성 시 인터페이스 본격 사용.
- **#7 Brief Editor**: PlayerSubmission 구성·전달. Editor가 *Submit* 버튼을 누르면 `EvaluationService.submit(submission)` 호출. Editor는 본 시스템에서 결과를 받지 않음 (Editor의 책임 종결).
- **#10 Verdict Reveal Sequence**: `evaluation_completed(result)` 시그널 → #10이 봉투 도착·페이드인·인장·*파기/기각* 큰 글자 연출 시퀀스 트리거. 본 시스템은 *결과 데이터*만 제공, 연출 X.
- **#11 Career Progression**: EvaluationResult를 케이스북(player career data)에 보존. final_score가 평판(#12) 입력. 재플레이 시 보존 정책은 #11 OQ (case-data-schema OQ-6 mirror).
- **#12 Reputation System** (VS): final_score → 평판 변화량 매핑. 본 GDD scope 외, #12에서 결정.
- **#14 Retrospective Replay** (Alpha): EvaluationResult.subscores + correct_set/missed_set/redundant_set을 보존. 결정문 도착 시점의 *플레이어 추론 vs 정답*을 시각화 (Disco Elysium 풍 가중 분기 표시).

---

## 4. Formulas

### 4.1 disposition_match

처분 일치 — 단순 이산 비교.

`disposition_match = 1.0 if (player_disposition == case.correct_disposition) else 0.0`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `player_disposition` | p_d | String | enum | 플레이어 채택 처분 (`library_dispositions_court`) |
| `correct_disposition` | c_d | String | enum | 케이스 정답 처분 |

**Output Range:** {0.0, 1.0} (이산). 빈 처분은 §3.1.2 Pre-evaluation Gate에서 거부됨.

**Example:** player_disposition="파기", correct_disposition="파기" → 1.0. player_disposition="기각", correct_disposition="파기" → 0.0.

### 4.2 core_citation_coverage

정답 인용 매칭률. *holding-N 부분 매칭* 정책 적용 — 플레이어가 `case:.../holding-1`을 인용하고 정답이 `case:.../holding-1`이면 정확 매칭, 플레이어가 `case:...` 전체 인용하고 정답이 `case:.../holding-N`이면 *부분 매칭 0.5*.

```
core_citation_coverage = (Σ_c match_score(c, player_citations)) / |correct_citations|
where match_score(c, P) = max(citation_similarity(p, c) for p in P)
      citation_similarity(p, c):
          1.0 if p == c
          0.5 if same_case_id(p, c) AND (p_or_c is whole_case AND other is holding)
          0.0 otherwise
```

**수식 방향**: 정답 인용(c) 측을 순회 — 자연 cap [0,1] (각 c는 최대 1.0 기여 + 분모 |C|로 정규화) + 표준 recall 의미론 (정답 covering 측 평가). 반대 방향(player 측 순회)은 |P| > |C| 시 1.0 초과 위험 + 같은 case의 다중 holding 인용으로 외관적 과장 가능 — 의도적으로 회피.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `player_citations` | P | Array[String] | size 1-15 | 플레이어 인용 목록 |
| `correct_citations` | C | Array[String] | size 3-15 | 케이스 정답 인용 목록 |
| `match_score(c, P)` | μ | float | 0.0–1.0 | c가 P 어느 항목과 가장 잘 매칭되는 점수 |
| `citation_similarity(p, c)` | σ | float | {0.0, 0.5, 1.0} | 두 인용 ID의 형태별 일치도 |

**Output Range:** [0.0, 1.0] (자연 cap — clamp 불필요). 0.0 = 정답 인용 1건도 매칭 안 됨, 1.0 = 모든 정답 인용을 정확히 인용.

**Example (MVP 잠금)**: 정답 `[law:civil-act-art-100, case:2024da12345/holding-1, case:2024do6789]`. 플레이어 `[law:civil-act-art-100, case:2024da12345, case:2024da99999]` → match_scores per c: [1.0 (law 정확), 0.5 (whole vs holding-1 부분), 0.0 (미인용)] → coverage = 1.5/3 = 0.5.

**Note**: holding-N의 holding-N+1 부분 매칭은 0.0 (다른 holding은 다른 판시) — 같은 case 내 모든 holding을 매칭으로 보면 인용의 변별력 사라짐.

### 4.3 redundant_citation_penalty

무관 인용 페널티. *플레이어가 인용했지만 정답에 없는* 인용에 비례한 음수 점수. Anti-Pillar 가드 — 인지 과부하 방지 + Pillar 3 (사고 만이 압박이다) 가드 (스팸 인용 = 무차별 시도 회피).

```
redundant_count = |player_citations \ matched_set|
where matched_set = {p in P | max(citation_similarity(p, c) for c in C) > 0}
redundant_ratio = redundant_count / |player_citations|
redundant_citation_penalty = -min(0.3, redundant_ratio × 0.5)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `redundant_count` | r | int | 0-15 | 매칭 실패한 인용 수 |
| `redundant_ratio` | ρ | float | 0.0–1.0 | 무관 인용 비율 |
| `redundant_citation_penalty` | π | float | -0.3–0.0 | 페널티 (clamp at -0.3) |

**Output Range:** [-0.3, 0.0]. cap=-0.3 — 무관 인용 다수여도 평가 자체가 무력화되지 않도록 (50% 무관 = -0.25 페널티).

**Example 1** (50% 무관): 플레이어 6 인용 중 정답 매칭 3건 + 무관 3건 → ρ = 0.5, π = -min(0.3, 0.5×0.5) = -min(0.3, 0.25) = **-0.25**.

**Example 2** (100% 무관 — cap 작동): 플레이어 5 인용 모두 무관 → ρ = 1.0, π = -min(0.3, 1.0×0.5) = -min(0.3, 0.5) = **-0.3** (cap 도달).

### 4.4 chain_coherence (v1+)

*MVP scope 외* — `case.scoring_weights.chain_coherence = 0` 잠금이므로 final_score 영향 0. 알고리즘은 v1+ 자문 검수 후 본격 정의 (§OQ-1). 임시 스텁:

```
chain_coherence_v1plus = TBD  # OQ-1 — chain node 인용 적합도 + 전이 일관성 평가
chain_coherence_mvp = 0.0     # 모든 MVP 케이스에서 가중치 0이므로 사실상 미사용
```

**Output Range (MVP)**: 0.0 (잠금). v1+ 활성화 트리거는 자문가 검수 + chain 평가 알고리즘 ADR (case-data-schema OQ-2의 v1+ 측 closure).

### 4.5 precedent_seniority_bonus (v1+)

*MVP scope 외* — `case.scoring_weights.precedent_seniority_bonus = 0` 잠금 (case-data-schema AC-10 + entities.yaml `case_disposition_match_minimum_weight` mirror). v1+ 알고리즘 스텁:

```
seniority_bonus_v1plus = avg(library_get(c).court_grade_weight for c in matched_set)
seniority_bonus_mvp = 0.0
```

`court_grade_weight`는 Library §7.3에서 정의 (현재 0 잠금). v1+ 활성화 트리거는 Library OQ-5 + case OQ-2의 *공동 결정*.

### 4.6 final_score 합산

```
final_score = clamp(
    weights.disposition_match × subscores.disposition_match +
    weights.core_citation_coverage × subscores.core_citation_coverage +
    weights.redundant_citation_penalty × subscores.redundant_citation_penalty +  # 음수
    weights.chain_coherence × subscores.chain_coherence +                          # MVP=0
    weights.precedent_seniority_bonus × subscores.precedent_seniority_bonus,       # MVP=0
    0.0, 1.0
)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `weights.*` | w_k | float | 0.0–1.0 (penalty 0.0–0.3) | case.scoring_weights[k] |
| `subscores.*` | s_k | float | -0.3–1.0 | §4.1-4.5 결과 |
| `final_score` | F | float | 0.0–1.0 | clamp 후 |

**Output Range**: [0.0, 1.0] (clamp).

**Normalization Constraint** (§7.2 Tuning Knobs guard):
- positive weights 합 (`w_disp + w_core + w_chain + w_senior`) ≤ 1.0
- penalty weight (`w_redund`) 별도 관리 — 0.0–0.3 안전 범위

**MVP 가중치 합 추정** (w_chain = w_senior = 0): w_disp + w_core ≤ 1.0. 예시 잠금: w_disp = 0.4 (case_disposition_match_minimum_weight 잠금) + w_core = 0.5 + w_redund = 0.1 + 나머지 0.

**Example (MVP 워크드)**: case `case_data:2026-001` 가중치 = `{disp:0.4, core:0.5, redund:0.1, chain:0.0, senior:0.0}`. 플레이어 결과 = `{disp:1.0, core:0.5, redund:-0.25, chain:0.0, senior:0.0}` → 0.4×1.0 + 0.5×0.5 + 0.1×(-0.25) + 0 + 0 = 0.4 + 0.25 - 0.025 = **0.625**. clamp 후 0.625. verdict 결정 룰 §3.1.4 적용 → player_disposition == correct_disposition AND 0.625 ∈ [0.5, 0.7) → **파기환송**.

### 4.7 Verdict 결정 함수

§3.1.4를 형식화:

```
verdict(player_disp, correct_disp, final_score) =
    "파기"      if player_disp == correct_disp AND final_score >= 0.7
    "파기환송"  if player_disp == correct_disp AND 0.3 <= final_score < 0.7
    "기각"      if player_disp != correct_disp AND final_score >= 0.3
    "각하"      otherwise
```

**Threshold rationale (§7.1 Tuning Knobs)**:
- 0.7 = "파기" cutoff: 인용·근거가 정답 처분과 일관되게 강할 때만 카타르시스 (Pillar 1 가드).
- 0.3 = "파기환송" 하한 (disp 일치 시): 처분 방향은 맞고 약간의 근거가 있음 — 다시 시도 가능한 시그널, 학습 곡선 보존.
- 0.3 = "기각" 하한 (disp 불일치 시): 처분은 빗나갔으나 논거는 있음 — 학습 곡선 보존. (파기환송과 기각은 0.3 임계값을 공유하나 분기 조건이 다름 — disp 일치 여부.)
- 0.3 미만 = "각하": 논거의 무게가 측정 가능한 임계 미달 — 처분 일치 여부 무관, 명확한 negative feedback.

**4 Verdict 분포 균형**: MVP playtest 5인 + 시드 케이스 평가 시 4 verdict가 모두 surface 되도록 케이스 가중치 튜닝 권장.

---

## 5. Edge Cases

- **EC-1: 빈 인용 제출 (`player_citations.size() == 0`)**
  - **If** PlayerSubmission이 인용 0건이면, **then** §3.1.2 Pre-evaluation Gate에서 *제출 거부* + UI 메시지 "최소 1건의 인용이 필요합니다" 표시 + 콘솔 push_warning. 평가 자체 미수행, 케이스 lifecycle은 `InProgress` 유지 (Submitted 진입 X). 플레이어는 #7 Brief Editor로 복귀하여 인용 추가 후 재제출. 디자인 이유: 빈 인용 평가는 *모든 케이스에서 동일 final_score 0.0* — 변별력 없는 No-op이므로 사전 차단이 명확한 negative feedback.

- **EC-2: 미존재 Library ID 인용**
  - **If** `player_citations`에 `LibraryService.validate_citations()` 미통과 ID 1건 이상이면, **then** §3.1.2 Pre-evaluation Gate에서 *제출 거부* + UI에 *어느 ID가 미존재인지* 표시 + 콘솔 push_error("Submission rejected: invalid Library IDs: %s"). #7 Brief Editor 측 책임 — Editor가 인용 추가 시점에 검증하므로 이 EC는 *방어적 가드*. case-data-schema EC-1 mirror.

- **EC-3: `player_disposition` enum 위반**
  - **If** `player_disposition`이 `library_dispositions_court` enum 외 값이면, **then** §3.1.2 Pre-evaluation Gate에서 *제출 거부* + 콘솔 push_error. #7 Brief Editor 측 책임 — Editor UI는 enum 4 멤버만 선택 가능해야 함. 이 EC는 *방어적 가드*.

- **EC-4: `case.scoring_weights` 정규화 위반 (positive weights 합 > 1.0)**
  - **If** 평가 시점에 `w_disp + w_core + w_chain + w_senior > 1.0`이면, **then** 콘솔 push_warning("Case %s: scoring_weights normalization violated, sum=%f") + 평가는 진행 (final_score는 clamp at 1.0로 안전). 이 EC는 *케이스 콘텐츠 작성 가드* — case-data-schema가 `_validate_and_register()` 단계에서 사전 검증하는 것이 이상적이지만 본 GDD scope 외. 

- **EC-5: 모든 인용이 무관 (`matched_set.size() == 0`)**
  - **If** `core_citation_coverage = 0.0` AND `redundant_count == player_citations.size()`이면, **then** 평가 *진행*. 결과는 final_score = w_disp × disp_match + 0 + w_redund × (penalty cap -0.3). disposition만으로 판정. 코멘트는 `comment.core.low` + `comment.redund.bloat` 활성. UI에 *모든 인용이 본 사건과 거리가 있다*는 강한 negative 코멘트 표시. 디자인 이유: 처분만 맞춰서 *카타르시스 파기*는 안 되도록 — Pillar 1 가드 (인용 매칭 0.0 → final_score 최대 = 0.4 잠금 → "파기" 0.7 미달 → "파기환송" — disp 일치 신호는 보존되어 다시 시도 가능 시그널). disp 불일치 + 인용 매칭 0.0 → final_score = 0 + redund penalty < 0.3 → "각하".

- **EC-6: case 비활성화 상태에서 제출 시도**
  - **If** `CaseService.get_case(case_id).is_active == false` (case-data-schema EC-1·2·3 발동 케이스)이면, **then** §3.1.2 Pre-evaluation Gate에서 *제출 거부* + UI 에러. 이 EC는 *프로세스 가드* — 비활성화 케이스는 #5 Browser에서 진입 자체가 차단되어야 하지만 (Browser §EC) 본 시스템도 방어적 가드.

- **EC-7: 평가 중 `EvaluationService` 재호출 (이중 제출)**
  - **If** State가 `Validating`/`Computing`/`Reporting` 중에 두 번째 `submit()` 호출되면, **then** 두 번째 호출 *거부* + 콘솔 push_warning("Evaluation in progress: re-submit ignored"). #5 Browser·#7 Editor가 *Submit 버튼 비활성화*로 사전 차단해야 함 — 이 EC는 *방어적 가드*.

- **EC-8: 재평가 (`Resolved` 상태에서 같은 case_id 재제출)**
  - **If** case lifecycle이 `Resolved` 상태이고 같은 `case_id`로 `submit()` 호출되면, **then** *재평가 허용* — EvaluationResult 새로 산출하고 `evaluation_completed` 시그널 emission. **항상 재계산 원칙** (캐시 X — AC-23이 byte-identical 결정성을 보장하므로 캐시 불필요 + 결정성 단순함 + 가중치 데이터 변경 시 자동 반영). 단 #11 Career Progression의 결과 보존 정책(case-data-schema OQ-6)이 결정 — *첫 결과만 보존* / *모든 시도 보존* / *최고 점수 보존* 중 하나. 본 시스템은 매번 평가를 수행하고 *결과 영속화*는 #11 책임.

- **EC-9: `chain_data`가 누락된 v1+ 케이스 평가 (호환성)**
  - **If** v1+ 케이스가 `chain_coherence` 가중치 > 0인데 `chain_data == {}`이면, **then** subscore = 0.0 적용 + 콘솔 push_warning. v1+ 활성 시 #6 Workspace가 chain_data를 정상 export 보장해야 함 — 이 EC는 *마이그레이션 안전망*.

---

## 6. Dependencies

| 시스템 | 관계 | 양방향 메모 |
|--------|------|-------------|
| #1 Case Data Schema | HARD — `case.correct_disposition` + `correct_citations` + `scoring_weights` 입력 | case-data-schema §3.3에서 본 GDD 명시 ✓, §OQ-2가 본 GDD에 위임 ✓ |
| #20 Legal Reference Library | HARD — `LibraryService.validate_citations()` (EC-2 방어적 가드) | Library §3.3에서 외부 호출 인터페이스 명시 ✓ |
| #5 Case File Browser | HARD — Browser `SubmissionPending` ↔ 본 시스템 활성 / `evaluation_completed` 시그널 → Browser `VerdictArrived` 전이 | Browser §3.2 + §AC-20·AC-21에서 본 시스템 위임 ✓ |
| #7 Brief Editor | HARD — PlayerSubmission 구성·전달 (`EvaluationService.submit(submission)`) | Brief Editor 미디자인 — 본 GDD §3.1.1 PlayerSubmission 인터페이스가 #7 디자인의 *입력 계약* |
| #6 Reasoning Workspace | SOFT (MVP) / HARD (v1+) — `chain_data` 입력. MVP는 빈 Dict 허용. **§3.2 freeze 계약** (submit() 시점에 workspace memo 불가변 스냅샷) — #6 측 행동 의무 | Workspace 미디자인 — 본 GDD §3.1.1 chain_data 슬롯 + §3.2 freeze 계약이 #6 v1+ 디자인의 *입력·행동 계약* |
| #10 Verdict Reveal Sequence | HARD — `evaluation_completed(result)` 시그널 → #10 봉투 연출 | #10 미디자인 — 본 GDD §3.1.6 EvaluationResult가 #10의 *입력 계약* |
| #11 Career Progression | HARD — EvaluationResult 보존 + final_score → 평판 입력 | #11 미디자인 — case-data-schema OQ-6과 *공동 결정* (재플레이 보존 정책) |
| #12 Reputation System (VS) | SOFT — final_score → 평판 변화량 | #12 미디자인 — 본 GDD scope 외 |
| #14 Retrospective Replay (Alpha) | HARD — EvaluationResult.subscores + matched/missed/redundant sets 보존 + 시각화 | #14 미디자인 — 본 GDD §3.1.6 EvaluationResult가 *완전한 회고 입력* |
| #13 Persona System (VS) | SOFT — 코멘트 톤이 멘토 페르소나 영향 가능 | #13 디자인 시 코멘트 템플릿 본문 작성 책임 |
| #15 Source Citation (v1+) | SOFT — Library ID 출처 표시 (player가 인용한 ID도 출처 노출 가능) | v1+ — 본 GDD scope 외 |

본 GDD가 의존하는 ADR:
- ADR-0001 (Library Storage Format) — `LibraryService.validate_citations()` 인터페이스 + 정적 타입 Resource 패턴 mirror
- ADR-0001 Amendment 1 + 1.1 — Library ID 형식·holding 분리 패턴
- ADR-0003 (Case Data Storage Format) — `CaseFile` 13 필드 + scoring_weights 외부화 결정 + autoload 순서 + mirror principle

본 GDD가 trigger하는 *향후 ADR 후보*:
- **ADR-0007 (Submission Evaluation Algorithm)**: PlayerSubmission/EvaluationResult/CommentTemplates Resource 정적 타입 트리, EvaluationService autoload (THIRD position + heuristic guard), entities.yaml verdict 임계값 외부화 + per-case override 금지, comment_templates.tres 위치. **Proposed 2026-05-06** (godot-specialist 검증 완료 — autoload await deadlock 가드 + AC-22 측정 박법 보정 포함).
- **ADR-XXXX (v1+ Chain Coherence Algorithm)**: 추론 체인 평가 알고리즘 정의 — 자문가 검수 + #6 Workspace 디자인 후 진입.

---

## 7. Tuning Knobs

### 7.1 Verdict 임계값 (글로벌 잠금)

| 노브 | MVP 기본 | 안전 범위 | 너무 낮으면 | 너무 높으면 |
|------|----------|-----------|-------------|-------------|
| `verdict_threshold_pagi` | 0.7 | 0.6-0.8 | "파기" 카타르시스 흔해짐 → Pillar 1 변별력 ↓ | "파기" 도달 불가능 → 좌절 |
| `verdict_threshold_low` | 0.3 | 0.2-0.4 | 파기환송(disp 일치)·기각(disp 불일치) 모두 흔해짐 → 학습 곡선 약화 | "각하" 빈번 → 좌절 + 첫 30분 이탈 |

이 2 임계값은 **글로벌 잠금** — entities.yaml `submission_verdict_thresholds` constant로 등록 권장. 케이스별 override는 *원칙적으로 X* (Pillar 1 가드: 모든 케이스가 동일 평가 룰). 파기환송과 기각은 동일 0.3 임계값(`verdict_threshold_low`)을 공유 — 분기 조건은 player_disp == correct_disp 여부.

### 7.2 case.scoring_weights 정규화 가드 (per-case)

| 노브 | MVP 기본 | 안전 범위 | 잠금 |
|------|----------|-----------|------|
| `w_disp` (`disposition_match`) | 0.4 | 0.4-0.6 | **≥ 0.4 잠금** (case-data-schema AC-9 — `case_disposition_match_minimum_weight`) |
| `w_core` (`core_citation_coverage`) | 0.4-0.5 | 0.3-0.6 | positive weights 합 ≤ 1.0 |
| `w_redund` (`redundant_citation_penalty`) | 0.1 | 0.0-0.3 | 별도 — penalty weight |
| `w_chain` (`chain_coherence`) | **0.0 (MVP 잠금)** | 0.0 (v1+ unblock) | case-data-schema OQ-2 + Library OQ-5 공동 결정 |
| `w_senior` (`precedent_seniority_bonus`) | **0.0 (MVP 잠금)** | 0.0 (v1+ unblock) | case-data-schema AC-10 mirror — Anti-Pillar |

**MVP 가중치 시드 추천 (per-case)**:
- 단순 케이스 (difficulty 1-2): `{disp:0.5, core:0.4, redund:0.1, chain:0, senior:0}` — 처분 측 비중 높음
- 표준 케이스 (difficulty 3): `{disp:0.4, core:0.5, redund:0.1, chain:0, senior:0}` — 인용 측 비중 높음
- 어려운 케이스 (difficulty 4-5): `{disp:0.4, core:0.5, redund:0.1, chain:0, senior:0}` — 표준과 동일 (MVP), v1+에서 chain 활성

### 7.3 Subscore Penalty Cap

| 노브 | MVP 기본 | 안전 범위 | 의미 |
|------|----------|-----------|------|
| `redundant_penalty_cap` | -0.3 | -0.5 ~ -0.2 | redundant_citation_penalty 하한 (§4.3) |
| `redundant_ratio_multiplier` | 0.5 | 0.3-0.8 | `penalty = -min(cap, ratio × multiplier)` (§4.3) |

너무 약하면 스팸 인용 페널티 사라짐 (Pillar 3 가드 약화), 너무 강하면 학습 곡선 좌절.

### 7.4 Comment Templates (콘텐츠 노브)

| 노브 | 위치 | 의미 |
|------|------|------|
| `comment_templates.tres` | `assets/data/evaluation/` | 코멘트 템플릿 키 → 한국어 본문 매핑 (§3.1.5 7-키 셋) |
| `comment_max_length_chars` | 80 | 한 줄 코멘트 최대 길이 (UI 가독성) — 한글 80자 ≈ #10 Verdict Reveal Sequence UI 패널 폭 2줄 추정. #10 디자인 시 mockup 폭 결정으로 재검토 (현재 추정값) |

코멘트 본문 톤은 #13 Persona System 디자인 시 결정. MVP는 *중립적·간결*한 톤 (멘토 미도입 상태).

### 7.5 v1+ Unblock 트리거 가드

- `chain_coherence` 활성화는 *모든* MVP 케이스의 `w_chain = 0` → v1+ 단계에서 케이스 별로 ≥ 0.1로 변경 시 활성. 단일 케이스 활성 X — 일괄 마이그레이션. Library OQ-5와 case OQ-2가 *동일 결정*.
- `precedent_seniority_bonus` 활성화는 Library §7.3 `court_grade_weight` 활성화와 *동일 결정*. 한 곳에서 결정, 두 곳에서 동시 활성.

이 가드의 의미: MVP 동안 이 두 subscore는 *코드는 구현되어 있지만 가중치 0으로 사실상 미사용*. v1+ 활성 시 코드 변경 없이 데이터(per-case scoring_weights) + 글로벌 config 변경만으로 이행 가능.

---

## 8. Acceptance Criteria

### 8.1 Pre-evaluation Gate (§3.1.2)

- **AC-1**: **GIVEN** PlayerSubmission이 `player_citations.size() == 0`일 때, **WHEN** `EvaluationService.submit()` 호출, **THEN** `submission_rejected("empty_citations")` 시그널 emission + EvaluationResult 미생성 + 콘솔 push_warning (EC-1).
- **AC-2**: **GIVEN** PlayerSubmission이 미존재 Library ID 1건 보유, **WHEN** submit() 호출, **THEN** `submission_rejected("invalid_library_id")` + push_error("Submission rejected: invalid Library IDs: %s") (EC-2).
- **AC-3**: **GIVEN** PlayerSubmission의 `player_disposition`이 `library_dispositions_court` 외 값, **WHEN** submit() 호출, **THEN** `submission_rejected("invalid_disposition")` + push_error (EC-3).
- **AC-4**: **GIVEN** `case.scoring_weights` positive 합이 1.0 초과, **WHEN** evaluate(), **THEN** push_warning + 평가 진행 + final_score는 clamp at 1.0 (EC-4).

### 8.2 Subscore 정확성 (§4)

- **AC-5**: **GIVEN** player_disposition == correct_disposition, **WHEN** evaluate(), **THEN** subscores.disposition_match == 1.0 (§4.1).
- **AC-6**: **GIVEN** player_disposition != correct_disposition, **WHEN** evaluate(), **THEN** subscores.disposition_match == 0.0 (§4.1).
- **AC-7**: **GIVEN** player_citations = [law:civil-act-art-100, case:2024da12345, case:2024da99999] AND correct_citations = [law:civil-act-art-100, case:2024da12345/holding-1, case:2024do6789], **WHEN** evaluate(), **THEN** subscores.core_citation_coverage == 0.5 (= (1.0 + 0.5 + 0.0)/3 — 정답 c 측 순회 §4.2 워크드).
- **AC-8**: **GIVEN** matched_set.size() == 3 AND player_citations.size() == 6 (3 redundant), **WHEN** evaluate(), **THEN** subscores.redundant_citation_penalty == -0.25 (-min(0.3, 0.5×0.5)) (§4.3 워크드).
- **AC-9**: **GIVEN** MVP 모든 케이스, **WHEN** evaluate(), **THEN** subscores.chain_coherence == 0.0 AND subscores.precedent_seniority_bonus == 0.0 (MVP 잠금 §3.1.3).

### 8.3 Final Score + Verdict (§4.6, §4.7)

- **AC-10**: **GIVEN** subscores = {disp:1.0, core:0.5, redund:-0.25, chain:0, senior:0} AND weights = {disp:0.4, core:0.5, redund:0.1, chain:0, senior:0}, **WHEN** evaluate(), **THEN** final_score == 0.625 (§4.6 워크드).
- **AC-11**: **GIVEN** player_disp == correct_disp AND final_score >= 0.7, **WHEN** verdict() 결정, **THEN** verdict == "파기".
- **AC-12**: **GIVEN** player_disp == correct_disp AND 0.3 <= final_score < 0.7, **WHEN** verdict(), **THEN** verdict == "파기환송".
- **AC-13**: **GIVEN** player_disp != correct_disp AND final_score >= 0.3, **WHEN** verdict(), **THEN** verdict == "기각".
- **AC-14**: **GIVEN** final_score < 0.3 (disp 일치 여부 무관), **WHEN** verdict(), **THEN** verdict == "각하" (disp 일치 + 저점 / disp 불일치 + 저점 양 분기 통합).

### 8.4 EvaluationResult 출력 (§3.1.6)

- **AC-15**: **GIVEN** submit() 호출이 검증 통과, **WHEN** Reporting 상태 진입, **THEN** `evaluation_completed(EvaluationResult)` 시그널 1회 emission + EvaluationResult.subscores · weighted_contributions · comments · correct_set · missed_set · redundant_set 모두 채워짐.
- **AC-16**: **GIVEN** EvaluationResult, **WHEN** weighted_contributions.values().sum() 계산, **THEN** 결과 == final_score (정규화 검증).

### 8.5 상태 머신 (§3.2)

- **AC-17**: **GIVEN** EvaluationService State == Idle AND submit(valid_submission) 호출, **WHEN** 다음 frame, **THEN** State 전이 Idle → Validating → Computing → Reporting → Done → Idle (단일 frame 내 또는 다중 frame across).
- **AC-18**: **GIVEN** State ∈ {Validating, Computing, Reporting} AND 두 번째 submit() 호출, **WHEN** 두 번째 호출 발생, **THEN** 두 번째 호출 거부 + push_warning("Evaluation in progress") (EC-7).

### 8.6 Pillar / Anti-Pillar 가드

- **AC-19**: **GIVEN** matched_set.size() == 0 (모든 인용 무관) AND player_disp == correct_disp AND case 가중치 = MVP 표준 시드 (w_disp=0.4, w_core=0.5, w_redund=0.1, w_chain=w_senior=0), **WHEN** evaluate(), **THEN** final_score == 0.37 (= 0.4×1.0 + 0.5×0.0 + 0.1×(-0.3) — redundant_ratio=1.0이므로 penalty cap 도달) AND verdict == "파기환송" (Pillar 1 가드 — disp 일치 신호는 보존되지만 인용 부재로 파기 0.7 미달, 카타르시스 차단; EC-5).
- **AC-20**: **GIVEN** MVP 모든 케이스의 case.scoring_weights, **WHEN** disposition_match weight 측정, **THEN** w_disp >= 0.4 (case-data-schema `case_disposition_match_minimum_weight` 잠금 mirror — 본 시스템은 *읽는 측*).

### 8.7 성능 (release build)

- **AC-21**: **GIVEN** 평균 케이스 (correct_citations 6 + player_citations 6), **WHEN** submit() → evaluation_completed 시그널, **THEN** 경과 시간 ≤ 50ms (Pillar 3 *사고만이 압박이다* — 평가 지연이 인위적 압박감 X).
- **AC-22**: **GIVEN** EvaluationService, **WHEN** `OS.get_static_memory_usage()` baseline 후 100회 evaluate() 반복 + 종료 후 delta 측정, **THEN** (delta / 100) ≤ 256 KB per evaluation. 단일 호출 측정은 Godot GC defer + `Performance.get_monitor` 샘플링 노이즈로 부정확 — averaging 필수 (ADR-0007 Risk 6). gdunit4 native hook 부재 시 manual evidence — `production/qa/evidence/eval-memory-[date].md`에 baseline·iteration·평균 delta 기록.

### 8.8 결정성 (Test-Standards 준수)

- **AC-23**: **GIVEN** 동일 PlayerSubmission + 동일 case, **WHEN** 두 번 evaluate() 호출, **THEN** 두 EvaluationResult가 byte-identical (random 사용 X, time-dependent 사용 X — `evaluated_at`은 Reporting 시점 timestamp이므로 비교 제외) (test-standards Determinism 준수).

---

## Open Questions

- **OQ-1 (deferred to v1+)**: `chain_coherence` subscore 알고리즘 정의 — 추론 트리 노드의 인용 근거 적합도, 부모-자식 전이 일관성, 중복 가설 페널티 등. 자문가 검수 필수 (variation 평가 알고리즘은 법학·인지심리 도메인 깊이 의존). #6 Reasoning Workspace 디자인 + 자문 회의 후 별도 ADR로 정의. case-data-schema OQ-2의 v1+ 측 closure.

- **OQ-2 (closed by ADR-0007 Proposed 2026-05-06)**: ADR-0007 (Submission Evaluation Algorithm) §1·2·3·4 잠금 — (a) Resource 트리는 src/data/ + class_name/extends Resource/@export (mirror ADR-0001/0003); (b) EvaluationService autoload THIRD position + entry_count()/case_count() heuristic guard (await pre-fire deadlock 방어); (c) verdict 임계값은 design/registry/entities.yaml `submission_verdict_thresholds`에 외부화 + per-case override 금지 forbidden_pattern 등록; (d) comment_templates.tres는 assets/data/evaluation/ + CommentTemplates Resource (Dictionary[String, String]). ADR-0007 Accepted 후 OQ-2 closed.

- **OQ-3 (deferred to #13 Persona System)**: 코멘트 본문 톤 — MVP는 중립적·간결, 멘토 도입 후(VS) 멘토 페르소나의 *결*을 코멘트에 반영할지. 결정 입력은 #13 디자인 시 본 GDD §3.1.5 7-키 셋 검토.

- **OQ-4 (deferred to #11 Career Progression)**: 재플레이 결과 보존 정책 — 첫 결과만 / 모든 시도 / 최고 점수 (case-data-schema OQ-6 mirror). 본 시스템은 매번 평가 수행하고 영속화는 #11 책임 — #11 디자인 시 결정.

- **OQ-5 (deferred to #14 Retrospective Replay)**: EvaluationResult가 제공하는 matched_set/missed_set/redundant_set의 *시각화 방식* — 가중 분기 표시 (Disco Elysium 풍) vs 단순 리스트 + 색상 코딩. Alpha 단계 #14 디자인 시 결정.

- **OQ-6 (deferred to #12 Reputation System)**: final_score → 평판 변화량 매핑 함수. VS 단계 #12 디자인 시 결정. 본 GDD scope 외.

- **OQ-7 (deferred to playtest)**: 4 verdict 임계값 (0.7 / 0.5 / 0.3) 튜닝 — MVP 5인 playtest에서 4 verdict 분포 측정 후 보정. 자문가 검수 시 *변호사가 보기에 verdict 라벨이 합리적인가* 확인 (예: "파기환송" 임계값이 실제 법조계 감각과 일치하는지).

- **OQ-8 (deferred to ADR)**: comment_templates.tres 형식 — Dictionary 기반 단순 매핑 vs 조건 분기 트리 (i18n 대비) — ADR 시점에 결정. MVP는 한국어 단일 언어이므로 단순 매핑으로 충분.

- **OQ-9 (deferred to v1+)**: holding-N 부분 매칭 0.5 점수의 변별력 — 자문가 시점에서 *법조계가 판례 인용을 holding 단위로 다룰 때*의 가중치가 본 GDD 가정과 일치하는지. 변호사 자문 회의 항목 추가 권장.
