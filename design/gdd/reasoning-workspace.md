# Reasoning Workspace

> **Status**: Designed — 2nd Cascade Revision Applied (2026-05-07; design-review MAJOR REVISION NEEDED 2nd cycle → 22 BLOCKING + 50 IMPORTANT resolved via mechanical cascade; 3rd review cycle scheduled)
> **Author**: kjuioqq8@gmail.com + game-designer + ux-designer + systems-designer + art-director + audio-director + qa-lead + godot-specialist + accessibility-specialist (review)
> **Last Updated**: 2026-05-07 (2nd cascade)
> **Decision Log**: `design/gdd/reviews/reasoning-workspace-decisions-2026-05-07.md` (3 gates, 1st cascade) + `design/gdd/reviews/reasoning-workspace-decisions-2026-05-07-cycle2.md` (2nd cascade — Pillar 2 / 인장빨강 lockdown / AccessKit floor / KB CitationDrop)
> **Layer**: Feature
> **Priority**: MVP
> **Implements Pillar**: 1 (Truth Is Weighted) + 3 (Only Thought Pressures)
> **Source Concept**: design/gdd/game-concept.md
> **Position in Index**: #6 — 7th in design order (Feature Layer #1)
> **Architectural Backing**: ADR-0007 (Submission Evaluation Algorithm) — chain_data 입력 계약 + freeze 스냅샷 forward-constraint; ADR-0004 (Korean Text Rendering) — Theme type variations + RichTextLabel scroll virtualization; **ADR-0008 (Workspace Layout — Proposed 2026-05-07)** — DeskPane Control hierarchy + CitationDrop hybrid signal topology + MemoPanel inline/fallback + Tree panning Camera2D + Gamepad two-step (Gate ③ 4 invariant + OQ-W5/W9/W10/W13 closure)
> **Effort**: L (4+ sessions per systems-index)

---

## 1. Overview

*Reasoning Workspace*는 플레이어가 한 케이스의 *추론을 구성하는 책상*이다 — 가설 트리, 자유 메모, Library에서 드래그한 evidence, 그리고 그 모든 것이 하나의 `chain_data` Dictionary로 export되는 freeze 스냅샷을 호스팅한다. Browser §3.6 `WorkspaceHandoff` 상태에서 DeskPane 통제권을 받으며, 케이스 lifecycle `InProgress` 동안 플레이어가 시간을 가장 길게 보내는 화면(Browser 다음 player-facing #2)이다. 데이터 측 책임은 — (a) `case.id` 단위 진행 Resource (가설 노드·메모·evidence·연결 그래프 보존), (b) `EvaluationService.submit()` 호출 시점의 불가변 `chain_data` 스냅샷 export (**ADR-0007 §3.2** freeze forward-constraint, 사후 정당화 방지 Pillar 1 가드), (c) Library `CitationDrop` 상태의 drop target 정책. 플레이어 측 경험은 Disco Elysium *Thought Cabinet* 결의 가설 트리 구성·재배치 + 노드별 자유 메모·evidence 첨부로, 본인의 *법리 직감*이 트리 깊이·인용 가중치로 정량화되는 자각을 만든다 — Pillar 1(*진실은 가중치다*)을 player-facing으로 시각화하는 핵심 시스템이며, Pillar 3(*사고 만이 압박이다*)이 시간 압박 0의 차분한 흐름으로 직접 구현되는 무대다. 시각·텍스트 렌더링은 **ADR-0004**(Theme type variations + RichTextLabel scroll virtualization)을 따르고, 위젯 트리 구체는 #2 UI Foundation 및 후속 *Workspace Layout ADR*에 위임된다 (본 GDD는 시각·인터랙션·데이터 계약 잠금에 집중).

## 2. Player Fantasy

1심·2심 판결문을 충분히 읽고 책상 앞에 앉으면, 가설 트리는 처음에 비어 있다. 후보 상고이유를 하나 적고, Library에서 끌어온 판시 단락을 그 아래 노드에 얹는다. 증거 카드 하나가 가설 노드 위에 얹히는 순간, 트리의 한 변이 굵어지는 게 보인다. 같은 판시 단락을 다른 가지에 옮겨붙이면 그쪽이 굵어진다. 어느 가지도 결정적이지 않다는 사실이, 손 끝에서 천천히 분명해진다 — 어느 인용이 더 무겁게 앉는가. 책상 위에서, 그 무게만으로 결론이 기운다.

작업이 길어지면 어느 시점에 한 시간을 들여 키워둔 가지를 지우게 된다. 메모도, 인용도, 그 아래 달아둔 판례 세 건도 함께 사라진다. 처음 들였던 시간이 아깝다는 감각과, 이 가지로는 쟁점이 서지 않는다는 판단이 같은 무게로 놓인다. 누구도 재촉하지 않는다. 지울지 남길지를 정하는 일만 책상 위에 남아 있다 — 시간 압박이 아닌 *판단의 무게*가 곧 압박이다.

제출 직전, 트리 전체가 한 번 더 눈에 들어온다. 어떤 노드는 인용이 두텁고, 어떤 노드는 메모만 길다. 누르면 모든 메모와 연결이 그대로 굳는다. 사후의 수정도, 더 나은 정리도 허락되지 않는다. 지금 놓인 가중치가 곧 제출되는 추론이라는 사실 앞에서, 한 번 더 읽고, 한 번 더 망설인다. 이 망설임 — 시간 압박 0의 게임에서 *유일하게 마련된 압박감* — 이 Reasoning Workspace가 만드는 핵심 감각이다.

## 3. Detailed Design

### 3.1 Core Rules

**Rule 1 — HypothesisNode 모델**: 가설 트리는 *케이스 종속 multi-root tree (forest)* — 각 노드는 정확히 하나의 부모(또는 루트)와 0+ 자식을 보유. 루트가 복수 허용되어 forest of trees 구조 (다중 상고이유 병렬 표현). 각 노드는 다음 필드를 보유한다.

| 필드 | 타입 | 의미 |
|---|---|---|
| `node_id` | String | 케이스 내 고유 — UUID v4 생성 (재정렬·삭제 후에도 chain_data 스냅샷 내 참조 안정) |
| `label` | String | 플레이어 입력 가설 제목 — 최대 60자 |
| `memo` | String | 자유 메모 — 최대 500자 (Rule 5) |
| `evidence` | Array[String] | Library ID 배열 — 최대 5개 (Rule 4) |
| `parent_id` | String | 부모 node_id — 루트는 빈 문자열 `""` |
| `children` | Array[String] | 자식 node_id 목록 |

시각: 200×48px 직사각형, border-radius 2px, 선택 2px 잉크블랙 / 미선택 0.5px 그레이 (Art Bible §3.1). **Label 표시 정책 (200×48px 물리 제약)**: Pretendard Regular 14pt 기준 카드 inner box(좌우 패딩 8px 차감 후 184px)에 단일 행 표시 가능 한국어 글자 수는 약 13–15자 (글자 폭 12–14px 평균). Rule 5의 60자 cap은 *입력·저장* 한계 — *표시* 시점에는 inner box width 초과분을 ellipsis(`…`) truncation. 전체 label은 (a) 노드 hover 또는 keyboard focus 시 tooltip / popover로 표시 (200ms hover delay), (b) 인라인 편집 진입 시 `TextEdit` 한 줄 전체 표시 (가로 스크롤 또는 자동 줄바꿈은 §9 ratify), (c) F2 list view (§9.4.2) — flat indented text 모드에서 full label 노출. Truncation 발생 시 시각 indicator: ellipsis 자체가 표지자 (Art Bible 인쇄 컨벤션 정합).

**Rule 2 — Forest 구조 + MVP 깊이 제한**: 다중 루트 허용 (병렬 가설 — `parent_id == ""`인 노드 복수 OK; 본 GDD 전반에서 "tree"는 일반 명사이며 데이터 구조는 forest of trees). 깊이(depth) = 자기가 속한 root에서 해당 노드까지의 엣지 수. **MVP 깊이 ≤ 3** (루트=0 / 자식=1 / 손자=2 / 증손자=3) — "상고이유 → 쟁점 → 판례 근거" 3계층 표현 허용. 깊이 4+ 노드 추가 시도는 차단 + "이 가지는 더 깊이 나눌 수 없습니다" hint. 한국 상고심 4계층 추론(상고이유→쟁점→판례→학설/세부논거)에서 *학설/세부논거* 계층은 노드의 `memo` 본문(Rule 5)에 포함 — 트리 깊이 인플레이션 없이 추론 디테일 보존.

**Rule 3 — 노드 추가/이동/삭제**:
- **추가**: DeskPane 빈 공간 더블클릭 → 새 루트 노드. 기존 노드의 "+" 버튼 클릭 → 자식 노드 추가. 깊이 제한(Rule 2) 검사 후 허용.
- **이동**: **Plain drag from node body** — modifier 키 없음 (macOS/Windows 플랫폼 컨벤션 정합; Ctrl+drag은 macOS에서 컨텍스트 메뉴, Windows Explorer에서 복사 의미로 충돌하여 폐기). Drop discrimination은 *드래그 source*로 결정 — 노드 본문 source = 이동 / LibraryPane 카드 source = evidence 첨부 (Rule 4). 다른 노드 위에 드롭 → drop target의 자식으로 재배치. 깊이 3 초과 유발 시 차단. 빈 공간 드롭 → 루트 승격 (`parent_id = ""`). **Discoverable surface 의무**: (a) 노드 호버 시 cursor `grab`(잡기) 변환, drag 시작 후 `grabbing` 변환 (CSS-equiv `cursor` 속성, Godot `Control.MOUSE_CURSOR_DRAG`); (b) 노드 우클릭 컨텍스트 메뉴에 "이동" 항목 — 선택 후 다음 클릭 위치로 이동 (KB+M 사용자에 명시 발견 경로 + 키보드 사용자에 fallback). Click vs drag 구별은 §7.2 `node_drag_threshold_px` (default 8px) 임계 적용.
- **삭제**: 노드 선택 후 `Delete` 키 또는 컨텍스트 메뉴 "삭제". 자식·손자 포함 서브트리 전체 삭제. 삭제 전 *확인 다이얼로그* 의무 — "이 가지와 하위 [N]개 노드가 함께 삭제됩니다. 계속하시겠습니까?" (Pillar 3 — *cut* anchor 보존; 가벼운 삭제는 Section 2 판타지 침해).
- **레이블 편집**: 노드 더블클릭 → 인라인 텍스트 입력 (60자 cap). Enter 또는 외부 클릭으로 확정.

**Rule 4 — Evidence 첨부 (CitationDrop 정책)**:
- **동일 ID 중복**: *같은 노드* 내 차단 / *다른 노드*에 동일 ID는 허용 (같은 판례가 두 가지를 모두 지지 가능).
- **노드당 최대 evidence 수**: **5개** (MVP 초기값, Tuning Knob 노출). 6번째 거부 + "이 노드에는 인용을 5개까지만 첨부할 수 있습니다" hint.
- **허용 Library ID 타입**: `law:...` (LibraryLawEntry) + `case:.../holding-N` (LibraryHolding). 판결 전체(`case:...` LibraryPrecedentEntry root) 드롭 거부 + "판시 단락(holding) 단위로 인용해주세요" 안내 (Library §3.1.2 합성 ID 정책 정합).
- **드롭 타겟 인식**: §3.3 시그널 계약 참조.

**Rule 5 — 노드별 자유 메모**: 노드 클릭 → DeskPane 메모 패널 (위치는 §9 UI Requirements 결정 위임 — OQ-W5)의 포커스 이동.
- **표시**: `RichTextLabel scroll_active=true` (ADR-0004 forbidden_pattern `label_for_long_body_text` 정합 — 10+ 라인 본문 Label 금지).
- **편집**: `TextEdit` 위젯.
- **Theme**: `&"MemoLabel"` (표시) / `&"MemoEdit"` (편집) Theme type variation 의무 (ADR-0004 forbidden_pattern `inline_theme_override_without_type_variation` 정합).
- **글자 수**: ≤ 500자.
- **포맷**: Plain text MVP (마크다운 v1+ — OQ-W6 검토).

**Rule 6 — chain_data Export 스키마**: `EvaluationService.submit()` 호출 시 Workspace는 다음 구조의 Dictionary를 `PlayerSubmission.chain_data`에 채운다.

```python
chain_data = {
  "schema_version": 1,                # int — v1+ 구조 변경 시 마이그레이션 식별자
  "nodes": [
    {
      "node_id": "uuid-string",
      "label": "상고이유 1 — 법리 오해",
      "depth": 0,                     # int — 0=루트, 최대 3
      "parent_id": "",                # 루트는 ""
      "evidence": [                   # Library ID 배열, 노드당 최대 5
        "case:2019do1234/holding-1",
        "law:criminal-act-art-250"
      ],
      "memo_length": 87,              # int — 메모 본문은 미포함 (Pillar 1 가드), 길이만
      "child_count": 2                # int — 즉시 자식 수 (손자 포함 X)
    }
    # ... 추가 노드
  ],
  "edge_count": 4,                    # int — 전체 부모-자식 엣지 수
  "max_depth_reached": 2,             # int — 트리 실제 최대 깊이
  "total_evidence_count": 7           # int — 전체 노드 evidence 합산 (중복 ID 포함)
}
```

MVP에서 `chain_data == {}` 빈 Dict 허용 (ADR-0007 §1 정합). v1+ chain_coherence subscore 알고리즘이 `nodes[].evidence`, `depth`, `edge_count`를 소비. **메모 본문은 chain_data에 미포함** (Pillar 1 가드 — 평가는 인용·구조 가중치, 글쓰기 실력 X). v1+ 메모 텍스트 분석 도입 시 schema_version=2 bump + `memo_text` 필드 추가 (OQ-W3).

**Schema validation — dual-layer guard (Pillar 1 silent regression 방어)**:

**단일 source of truth (godot-specialist Item 7 BLOCKING closure)**: schema_version=1 허용 필드 allow-list는 `src/data/chain_data_schema.gd`의 `const SCHEMA_V1_ALLOWED_FIELDS` (top-level: `["schema_version", "nodes", "edge_count", "max_depth_reached", "total_evidence_count"]`) + `const SCHEMA_V1_NODE_FIELDS` (노드별: `["node_id", "label", "depth", "parent_id", "evidence", "memo_length", "child_count"]`)에 정의. Workspace 빌더와 EvaluationService Pre-evaluation Gate가 *동일 const를 import*. 양쪽 inline 정의는 forbidden_pattern `chain_data_schema_allow_list_duplication` (architecture.yaml registry 등록 의무).

1. **Builder-side allow-list** (본 GDD 책임): chain_data 빌더는 export Dict 생성 직후 import한 const 집합과 비교 검증. 비허용 필드 발견 시 `submission_rejected("schema_violation:[field_name]")` emit + `EvaluationService.submit()` *호출 자체 차단* (Pre-evaluation 도달 X). EC §5.6 fuzz test (AC-52) 커버.
2. **EvaluationService Pre-evaluation Gate** (ADR-0007 §3.1.2 책임 — submission-evaluation §3.1.2 5번째 검증 step): submission-evaluation §3.1.2 Pre-evaluation Gate가 동일 const를 *독립적으로* 재검증 (2nd cycle BLOCKING #13 closure — 본 cascade revision 시 submission-evaluation §3.1.2에 5th check 추가 의무). 양쪽 const drift는 컴파일 타임 import 실패로 즉시 surface.

**chain_data 빌드 normative (godot-specialist Item 8 BLOCKING closure)**: chain_data Dictionary는 *fully constructed new Dict*로 생성 — 라이브 `HypothesisNode` 그래프나 `WorkspaceData` 필드에 대한 reference 보유 금지. Godot Dictionary는 reference type이므로 freeze 후 라이브 데이터 mutation이 chain_data에 silent 반영될 수 있다. `WorkspaceData.build_chain_data()`는 모든 노드 dict를 `{"node_id": n.node_id, "label": n.label, ...}` 신규 dict literal로 채워 반환해야 하며, `nodes` 배열 또한 신규 Array — `WorkspaceData.nodes.duplicate()` 또는 등가. AC-24 deep-equality 검증의 step (1)이 이를 catch하나, 본 normative는 *구현 의무*로 명시.

**nodes[] 배열 canonical ordering (systems-designer F3 BLOCKING closure)**: `chain_data.nodes` 배열은 다음 순서로 직렬화 — (1) 루트(`parent_id == ""`)를 `node_id` 사전식 순서로 정렬, (2) 각 루트에 대해 BFS 순회 (각 깊이 단계에서 자식을 `node_id` 사전식 정렬), (3) 결과 시퀀스를 `nodes` 배열로 출력. 이로써 동일 워크스페이스 상태의 두 chain_data 빌드는 동일 `nodes` 순서를 보장 — AC-24 JSON.stringify 비교가 결정적이다. 위반 시 AC-24 deep-equality 가 false negative를 생성한다.

**Rule 7 — Freeze 동작** (ADR-0007 §3.2 forward-constraint 이행):
- **Freeze 동기 트랜지션 (synchronous, single-frame)**: Submit 클릭 처리는 단일 프레임 내 다음 순서로 진행 — (a) `ACTIVE → FROZEN` 상태 전환, (b) chain_data Dictionary 빌드 + Schema validation (Rule 6 builder-side), (c) `PlayerSubmission.chain_data` 할당, (d) `EvaluationService.submit(submission)` 호출. (a)(b)(c)는 동일 frame에서 atomic. Workspace는 submit() 반환을 await하지 않는다 — fire-and-forget. UI 차단은 FROZEN 상태가 보장 (입력 무시 + 오버레이 배너).
- **Freeze 범위**: 가설 트리 전체 (노드 구조·레이블·parent-child 관계) + 모든 노드의 evidence + 모든 노드의 memo. WorkspaceData Resource는 *불가변 스냅샷* — Write 경로 닫힘.
- **Freeze 중 인터랙션**: 모든 입력 무시 + "제출이 처리 중입니다" 오버레이 배너. Submit 버튼은 `EvaluationService.current_state != IDLE` 동안 비활성 (ADR-0007 forbidden_pattern `submit_during_active_evaluation` 정합).
- **Freeze 해제 (asynchronous via signal callbacks)**: Workspace는 EvaluationService 내부 진행을 polling 하지 않으며 시그널 콜백으로만 상태 복귀 — `submission_rejected` 시그널 수신 → FROZEN → ACTIVE 복귀 (재편집 허용); `evaluation_completed` 시그널 수신 → FROZEN → READ_ONLY (영구 아카이브).

### 3.2 States and Transitions

Workspace 자체 상태 머신 (case lifecycle / Browser screen state와 분리 — *작업 가능성* 측 상태):

| State | 의미 | 진입 조건 | 종료 조건 |
|---|---|---|---|
| `INACTIVE` | DeskPane 비활성 — Browser CatalogIdle/BriefOpen/FactsOpen 동안 Workspace 미마운트 | 게임 시작 / 다른 케이스 진행 / 케이스 종결 후 | `workspace_handoff_started` 시그널 수신 → `ACTIVE` |
| `ACTIVE` | 일반 작업 — 트리·메모·evidence 모두 편집 가능. 플레이어가 시간을 가장 길게 보내는 상태 | `workspace_handoff_started` 또는 `submission_rejected` | Submit 클릭 → `FROZEN` (**동기 single-frame 전이** — Rule 7 (a)→(d) atomic) / `workspace_handoff_ended(reason: "paused")` Browser emit → `INACTIVE` (재진입 가능) |
| `FROZEN` | 평가 진행 중 — chain_data 스냅샷 export 후 모든 입력 무시. 오버레이 배너 표시 | Submit 클릭 시 동기 전이 (Rule 7 — chain_data 빌드 → submit() 호출 모두 동일 frame) | `submission_rejected` → `ACTIVE` 복귀 (async signal callback) / `evaluation_completed` → `READ_ONLY` (async signal callback) |
| `READ_ONLY` | 평가 완료 후 영구 아카이브. #14 Retrospective Replay 열람 인터페이스의 데이터 소스 | `evaluation_completed` 수신 | `workspace_handoff_ended(reason: "submitted")` Browser emit → Browser `VerdictArrived` 진입 → 본 Workspace `INACTIVE` |

**상태 전이 그래프**:

```
[INACTIVE]
    │ workspace_handoff_started(case_id)
    ▼
[ACTIVE] ──Submit 클릭──▶ [FROZEN]
    ▲                        │
    │                        │ submission_rejected
    └────────────────────────┘
                             │ evaluation_completed
                             ▼
                        [READ_ONLY]
                             │
                             │ workspace_handoff_ended(reason: "submitted")
                             ▼
                        [INACTIVE]
```

ACTIVE → INACTIVE (`reason: "paused"`)는 플레이어가 다른 케이스로 이탈할 때 — 트리 상태는 `#3 Save/Load`가 직렬화하므로 재진입 시 동일 상태 복원 (Rule 8).

### 3.3 Interactions with Other Systems

#### WorkspaceHandoff 시그널 명세 (Browser §6 OQ-5 closure)

| 시그널 | 발신자 | 수신자 | 발화 조건 | 페이로드 |
|---|---|---|---|---|
| `workspace_handoff_started(case_id)` | Browser (#5) | Workspace (#6) | "맡습니다" 클릭 → FactsOpen → WorkspaceHandoff 전이 | `case_id: String` |
| `workspace_handoff_ended(case_id, reason)` | Workspace (#6) | Browser (#5) | Submit 완료 또는 플레이어 이탈 | `case_id: String, reason: String` (`"submitted"` \| `"paused"`) |

`reason: "submitted"` → Browser `SubmissionPending` 전이. `reason: "paused"` → Browser `WorkspaceHandoff` 유지 (재진입 가능).

#### CitationDrop 시그널 명세 (Library §3.2 ↔ Workspace)

LibraryPane은 Browser가 통제하지만 drop target인 가설 노드는 DeskPane(Workspace)에 있다. 경계 시그널:

| 시그널 의미 | 발신자 | 수신자 | 발화 조건 | 페이로드 |
|---|---|---|---|---|
| `citation_drag_started(library_id)` | Library Subsystem ¹ | Workspace | 플레이어가 LibraryPane 카드 드래그 시작 | `library_id: String` |
| `citation_dropped(library_id, viewport_position)` | Library Subsystem ¹ | Workspace | 드롭 발생 (DeskPane 영역) | `library_id: String, viewport_position: Vector2` |

¹ **발신자 구체 (autoload `LibraryService` vs scene node `LibraryPane`)와 전달 채널 (signal vs Godot 4.6 native drag-drop API `_get_drag_data`/`_can_drop_data`/`_drop_data` vs hybrid)는 Workspace Layout ADR (미작성)에 위임**. 본 GDD는 의미·페이로드·exactly-once delivery 계약만 잠근다 — Workspace 처리 로직은 emitter-agnostic. 위임 검증 invariant 4건은 `design/gdd/reviews/reasoning-workspace-decisions-2026-05-07.md` Gate ③ 참조.

**Workspace 측 처리**:
- `citation_drag_started` 수신 → DeskPane drop zone 하이라이트 활성 (workspace State == ACTIVE 시만).
- `citation_dropped` 수신 → viewport_position을 DeskPane 로컬 좌표로 변환 → hit-test로 target node 결정 → Rule 4 정책 적용 (중복·cap·타입 검증). 유효 노드 미히트 시 drop 무시 + "노드 위에 드롭해주세요" hint.
- Workspace State == FROZEN 또는 READ_ONLY 시 drop zone 하이라이트 비활성 + 드롭 자체 차단.

#### 기타 시스템과의 인터랙션

| 시스템 | 관계 | 인터페이스 |
|---|---|---|
| **#1 Case Data Schema** | Read-only | `CaseService.get_case(case_id) -> CaseFile`. correct_disposition / correct_citations / scoring_weights에 본 시스템 *접근 안 함* (평가는 #9 책임 — 정보 격리로 사후 정당화 방지). |
| **#20 Legal Reference Library** | Read-only | `LibraryService.get_entry(id)` (evidence 카드 표시), `LibraryService.get_holding(synthesized_id)` (holding 단위 인용). CitationDrop 시그널 2종. |
| **#3 Save/Load** | Read+Write 위임 | `workspace_state_changed` 시그널 emit → Save/Load가 직렬화 시점 결정. **저장 빈도 정책은 #3 GDD 위임** (OQ-W4). 게임 종료 시 마지막 emit 기준 저장 상태 복원. |
| **#7 Brief Editor** | chain_data 입력 계약 제공 | Brief Editor가 `node.evidence` 배열에서 `{{cite:<library_id>}}` 토큰을 자동 생성 (Library `library_brief_cite_token` constant 정합). |
| **#9 Submission & Evaluation** | chain_data export | `EvaluationService.submit(PlayerSubmission)` 호출 시 chain_data가 PlayerSubmission.chain_data로 전달 (ADR-0007 §1 정합). Freeze 행동 계약 (ADR-0007 §3.2 forward-constraint) 본 GDD가 이행. |
| **#14 Retrospective Replay (Alpha)** | READ_ONLY 데이터 소스 | 결정문 도착 후 워크스페이스 아카이브 열람. *본 GDD scope 외* — #14 위임. |

#### Persistence 정책 (Rule 8 — §3.1에서 인용)

- **세션 간 저장**: `WorkspaceData` Resource는 케이스 `InProgress` 기간 동안 #3 Save/Load가 직렬화. Workspace 자체는 저장 호출 X — 상태 변경 시 `workspace_state_changed` 시그널만 emit.
- **게임 종료 시**: `InProgress` 케이스의 Workspace는 마지막 emit 기준 저장 상태 복원. 미저장 변경(emit 사이)은 유실 허용 (MVP — 명시적 저장 버튼 v1+ 검토).
- **Resolved 케이스 재플레이**: 새 `WorkspaceData` 인스턴스 생성 — 이전 트리·메모·evidence 초기화 (Browser §3.8 정합). 이전 인스턴스는 케이스 결과 아카이브의 일부로 #14가 보관 인터페이스 제공.

## 4. Formulas

### 4.1 chain_data Derivation Formulas (MVP — submission-time export)

다음 5개 수식은 freeze 시점에 `chain_data` Dictionary의 각 파생 필드가 어떻게 계산되는지 정의한다. 모든 수식은 인메모리 `HypothesisNode` 그래프에 대해 작용하며, export Dictionary는 결과만 포함하고 중간 구조는 포함하지 않는다.

---

**depth(node)**

The `depth` formula is defined as:

`depth(n) = 0 if n.parent_id == "" else depth(parent(n)) + 1`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `n` | n | node ref | — | The target HypothesisNode |
| `n.parent_id` | pid | String | `""` or UUID | Empty string indicates a root node |
| `depth(n)` | d | int | 0–3 | Edge distance from nearest ancestor with `parent_id == ""` |

**Output Range:** 0 to MAX_DEPTH (=3, MVP). §4.2 Tree Structural Invariant이 ≤ 3 재귀 단계 내 종료를 보장 — depth > 3 노드는 ACTIVE 상태에서 존재 불가.

**Example (4-node tree):** Root A (`parent_id=""`): depth=0. Child B (`parent_id=A`): depth=1. Grandchild C (`parent_id=B`): depth=2. Great-grandchild D (`parent_id=C`): depth=3.

---

**max_depth_reached**

The `max_depth_reached` formula is defined as:

`max_depth_reached = max(depth(n) for n in nodes)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `nodes` | N | Array[node] | size ≥ 0 | Freeze 시점의 모든 HypothesisNodes |
| `depth(n)` | d_n | int | 0–3 | 노드별 깊이 (위 정의) |
| `max_depth_reached` | D | int | 0–3 | 트리 실제 최대 깊이 |

**Output Range:** 0 to 3. 트리가 루트만 있는 경우 0. 빈 워크스페이스(nodes=[])는 convention상 0 — 이 경우 chain_data는 `{}` (ADR-0007 §1 빈 Dict 허용).

**Example:** 위 4-node 트리 (A·B·C·D): max(0, 1, 2, 3) = **3**.

---

**edge_count**

The `edge_count` formula is defined as:

`edge_count = |{n ∈ nodes : n.parent_id != ""}|`

동등하게: 루트가 아닌 노드 수. 트리에서는 각 비루트 노드가 정확히 한 개의 부모 엣지에 기여한다.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `nodes` | N | Array[node] | size ≥ 0 | Freeze 시점의 모든 HypothesisNodes |
| `n.parent_id` | pid | String | `""` or UUID | 비빈값은 부모 엣지 보유 |
| `edge_count` | E | int | 0–unbounded | 전체 forest의 부모-자식 엣지 총합 |

**Output Range:** 0 to (node_count − root_count). 원리상 무제한이나 실용상 ≤ node_count − 1. 빈 워크스페이스는 0.

**Example:** 4-node 트리 (A 루트, B/C/D 비루트): parent_id != "" 노드 = {B, C, D} → edge_count = **3**.

---

**total_evidence_count**

The `total_evidence_count` formula is defined as:

`total_evidence_count = Σ_{n ∈ nodes} len(n.evidence)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `nodes` | N | Array[node] | size ≥ 0 | Freeze 시점의 모든 HypothesisNodes |
| `len(n.evidence)` | e_n | int | 0–5 | 노드 n의 evidence 배열 길이 (Rule 4 cap) |
| `total_evidence_count` | T | int | 0–(5 × node_count) | 노드별 evidence 합산; 노드 간 중복 ID는 별개 카운트 |

**Output Range:** 0 to 5 × node_count. 다른 노드에 첨부된 동일 Library ID는 각각 카운트 (단일 holding이 두 가지에 인용되면 = 2). ADR-0007 §1 평가 계약과 일치.

**Example:** A(2 evidence), B(0), C(3), D(1) → total = 2+0+3+1 = **6**.

---

**child_count(node)**

The `child_count` formula is defined as:

`child_count(n) = len(n.children)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `n.children` | ch | Array[String] | size 0–unbounded | 즉시 자식 node_ids 배열 (재귀 X) |
| `child_count(n)` | k | int | 0–unbounded | 직속 자식 수만; 손자 제외 |

**Output Range:** 0 to unbounded (분기 인수에 MVP cap 없음). 리프 노드는 0.

**Example:** A.children=[B], B.children=[C], C.children=[D], D.children=[] → child_count: A=1, B=1, C=1, D=**0**.

---

### 4.2 Tree Structural Invariants

다음 4개 술어는 ACTIVE 상태에서 항상 참이어야 하며, freeze 빌드 단계에서 chain_data export 직전에 재검증된다. 어떤 mutation 시도가 invariant를 위반할 경우 *변경 적용 전* 거부 — 워크스페이스는 invalid 상태에 절대 진입하지 않는다.

---

**Invariant 1 — Parent-child symmetry**

`∀ n ∈ nodes : n.parent_id == "" ∨ (∃ p ∈ nodes : n.node_id ∈ p.children)`

비루트 노드는 모두 자신의 `node_id`가 부모의 `children` 배열에 포함되는 부모 노드를 가져야 한다. 이 양방향 정합성은 모든 add/move/delete 작업에서 유지된다.

*위반 동작:* dangling parent_id 참조를 만들 add·move 시도는 silent 거부 + `push_error("HypothesisNode parent_id references non-existent node: %s")` 로깅. 워크스페이스 상태 불변.

---

**Invariant 2 — Depth bound**

`∀ n ∈ nodes : depth(n) ≤ MAX_DEPTH (= 3, MVP)`

깊이 4+ 노드는 존재 불가. 모든 add·move 작업에서 mutation 적용 *전* 검사.

*위반 동작:* add·move 거부 + "이 가지는 더 깊이 나눌 수 없습니다" hint (Rule 2 지정 문구). 상태 불변.

---

**Invariant 3 — Acyclicity**

`∀ n ∈ nodes : n에서 시작한 parent-walk는 ≤ MAX_DEPTH 단계 내 루트(parent_id == "")에 도달`

MAX_DEPTH = 3이므로 최대 3 단계 parent-walk가 `parent_id == ""` 노드에 도달해야 한다. 도달하지 못하면 사이클 존재.

*위반 동작:* 사이클 유발 move 시도(조상을 자기 후손의 자식으로 이동)는 mutation 전 거부. move-validation 단계에서 제안된 새 부모로부터 위로 walk하면서 대상 노드의 `node_id`가 walk에 출현하면 거부 + `push_error("Cycle detected: cannot reparent node %s under its own descendant")`.

---

**Invariant 4 — Evidence count bound**

`∀ n ∈ nodes : len(n.evidence) ≤ EVIDENCE_PER_NODE_CAP (= 5, MVP)`

노드당 evidence는 최대 5개. 모든 CitationDrop에서 검사.

*위반 동작:* 6번째 드롭 거부 + "이 노드에는 인용을 5개까지만 첨부할 수 있습니다" hint (Rule 4 지정 문구). evidence 배열 불변.

---

**Invariant 5 — Evidence move atomicity (systems-designer F8 IMPORTANT closure)**

evidence 노드 간 *이동* (decisions-2026-05-07 Gate ① 재해석 — "옮겨붙이면": source 노드 evidence 배열에서 제거 + target 노드 배열에 추가)은 `WorkspaceData` 레이어에서 *원자적*으로 실행. `WorkspaceData.move_evidence(library_id, source_node_id, target_node_id) -> bool`은 두 step 모두 success 시에만 commit, 어느 한 step 실패 시 source 배열 rollback. 두 step 사이에 외부 코드(시그널 핸들러·crash·integrity sweep)가 진입해도 evidence는 source 또는 target 중 한 곳에 *반드시* 존재 — 양쪽 부재 상태 도달 불가. 위반 시 `push_error("Evidence move atomicity violated: evidence %s lost in transit between %s and %s")` + WorkspaceData rollback. EC §5.3 evidence drop 정책 정합 (CitationDrop은 add only — move는 별도 API).

---

**Invariant 6 — Tuning resource validation (systems-designer F7 IMPORTANT closure)**

`assets/data/workspace/tuning.tres` 로드 시점에 다음 invariant 검증 — 위반 시 default value 대체 + `push_error`:

`evidence_hit_test_tolerance_px ≥ node_drag_threshold_px` (§7.6 부등식)

이 부등식이 무너지면 드롭 히트 테스트가 등록되기 전에 드래그가 시작되어 evidence 첨부가 항상 차단된다. `WorkspaceData._validate_tuning(tuning: WorkspaceTuning) -> WorkspaceTuning` 메소드가 로드 시점 검증 + 위반 knob을 default value로 silent 보정.

---

### 4.3 v1+ chain_coherence Subscore — Forward Declaration

ADR-0007 §1 + submission-evaluation GDD §4.4는 chain_data로부터 `nodes[].evidence`, `depth`, `edge_count`를 소비할 미래 `chain_coherence` subscore를 예약한다. 이 subscore는 모든 MVP 케이스에서 weight 0.0 잠금 (`scoring_weights.chain_coherence = 0`) — MVP 평가에서 제외된다. 아래 수식은 **v1+ 잠정 초안일 뿐 — MVP 명세 아님**.

```
chain_coherence(submission) = α · normalized_depth
                            + β · normalized_breadth
                            + γ · evidence_distribution_entropy
```

후보 항 (v1+ 잠정 — boundary case 명시 필수):

| Term | Candidate formula | Notes |
|------|------------------|-------|
| `normalized_depth` | `max_depth_reached / MAX_DEPTH` | [0, 1]; 추론 체인 깊이. node_count==0 시 0 (빈 워크스페이스 EC §5.1) |
| `normalized_breadth_v2` | `1 − (leaf_count / node_count)` (leaf_count = `\|{n : n.children == []}\|`) — **단 `node_count == 0` 시 div-zero 보호: §4.3 Boundary policy 강제 short-circuit (chain_coherence = 0 즉시 반환, 본 항 미실행)** | [0, 1]; 단일 노드(node_count=1, leaf=1) → 0; 선형 체인 4-node(leaf=1) → 0.75; star tree 4-node(leaf=3) → 0.25; balanced binary 7-node(leaf=4) → ≈0.43. *"비-리프 비율"이 분기성의 proxy* — 선형/star/balanced를 구분 (기존 `edge_count/(node_count−1)` 폐기 — 모든 forest에서 1 고정 → discrimination 0). **Forest semantic 한계 (systems-designer F4 IMPORTANT)**: 2-root forest (leaf=2, node=2) → 0 — 단일 노드와 동일 score. v1+ formula round에서 forest-aware 변형 검토 필요 |
| `evidence_distribution_entropy` | 노드별 evidence 분포의 normalized Shannon entropy. `p_i = len(n_i.evidence) / total_evidence_count`. `H = −Σ p_i · log2(p_i)`. `H_max = log2(node_count)`. 정규화: `H / H_max` (단 boundary 적용). **Convention `0 · log2(0) := 0`** (systems-designer F2 BLOCKING closure — Shannon entropy 표준 limit p→0+. GDScript 구현은 zero-evidence 노드의 항을 0으로 명시 단축, `log(0) → -inf` 후 multiplication NaN 전파 방지) | [0, 1]; **Boundary cases**: node_count == 1 → 0 (단일 노드는 entropy 의미 없음); total_evidence_count == 0 → 0 (evidence 없음 — entropy 미정, lowest score 처리); H_max == 0 (node_count == 1) → 0 (분모 보호); 개별 노드의 `len(n.evidence) == 0` 시 해당 항만 0 단축 (전체 entropy 계속 계산) |

**Boundary policy (v1+ 알고리즘 구현 의무, systems-designer F1 BLOCKING closure)**: 모든 chain_coherence 항은 `node_count == 0 ∨ chain_data == {}` 시 항 전체를 0으로 단축평가 — 본 short-circuit은 *각 항 formula row 인라인에 명시* (위 표 참조), Implementor가 표를 코드로 추출 시 보호 누락 방지. 단일 노드(node_count == 1)는 chain_coherence = 0 (linear chain 하한 + breadth/entropy 미정). Submission-evaluation §4 산출 시 이 short-circuit이 div-by-zero · NaN 전파를 방지한다. 또한 `0·log2(0) := 0` convention은 entropy 계산 시점에 *코드 레벨 guard*로 진입 (GDScript: `if p_i == 0.0: continue` 또는 `term = 0.0 if p_i == 0.0 else -p_i * log(p_i) / log(2.0)`).

가중치 α, β, γ는 **TBD — v1+ formula round로 위임** (자문가 검수 + playtest data 대기). Output range [0, 1].

**Note:** MVP submission-evaluation §4는 chain_data를 소비하지 않음. 이 수식은 v1+ ship 시 #6 GDD amendment를 피하기 위한 forward declaration. schema_version=1 export 계약(§3.1 Rule 6)은 이 수식이 요구하는 모든 필드를 이미 포함. v1+ 진입 시 자문가/playtest 결과로 가중치 튜닝 + 이 boundary policy 재검토 의무 (특히 `normalized_breadth_v2`의 한국 상고심 추론 패턴 적합성).

---

### 4.4 evidence_density (per-node informational metric — NOT exported)

The `evidence_density` formula is defined as:

`evidence_density(n) = len(n.evidence) / EVIDENCE_PER_NODE_CAP`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `len(n.evidence)` | e | int | 0–5 | 노드 n의 현재 evidence 수 |
| `EVIDENCE_PER_NODE_CAP` | CAP | int | 5 (MVP) | Rule 4 tuning knob; denominator |
| `evidence_density(n)` | ρ_n | float | 0.0–1.0 | 채워진 evidence 슬롯 비율 |

**Output Range:** [0.0, 1.0]. 0.0 = evidence 없음; 1.0 = 5개 슬롯 모두 채움.

**chain_data에 포함 X.** DeskPane이 render 시 계산하는 local UI hint. **bottom evidence rule** 시각 채널의 길이 결정에 사용 (§8.1.1) — 노드 카드 하단의 가로 잉크블랙 룰(underline mark)이 `ρ × node_width` 길이로 표시. 한국 법조 문서의 *밑줄 강조* 관례를 차용한 Pillar 1 가시화 채널이며, **selection state (border 두께)와 visual channel 분리** — 두 신호가 동시 발화해도 충돌 없음 (decisions-2026-05-07 Gate ② 참조). 원시 카운트를 노출하지 않고 즉각적인 밀도 피드백 제공.

**Discretization:** MVP cap=5에서 ρ는 6개 이산 값 — `{0.0, 0.2, 0.4, 0.6, 0.8, 1.0}`. 이는 node_width 200px 기준 0/40/80/120/160/200px 길이의 룰 — 1080p 1:1 매핑에서 모든 단계가 인지 가능 (40px ≫ subpixel 임계). **Discretization step count는 `evidence_per_node_cap` knob 종속** (systems-designer F5 IMPORTANT closure — knob 변경 시 step 수 재산출: cap=3 → 4 step, cap=8 → 9 step). 본 6단계 시각 spec(§8.1.1.b) + AC-37 픽셀 수치(40/120/200px ±2px)는 `evidence_per_node_cap = 5` MVP 기본값 종속. cap 변경 시 §8.1.1.b 픽셀 표 + AC-37 수치 동시 갱신 의무.

**Pillar 2 도메인 한계 명시 (game-designer Pillar 2 IMPORTANT — MVP 수용 결정 2026-05-07 cycle 2)**: `evidence_density`는 *count-based* proxy — 한국 상고심에서 인용 weight는 *court grade* (전합 > 부 > 하급심) + *판례 recency* + *doctrinal alignment*에 의해 결정되는 다차원 신호. MVP는 count proxy를 *수용된 단순화*로 채택 (Bottom Evidence Rule 시각 채널 인지 가능성 우선). v1+ ADR-0007 amendment를 통해 `precedent_seniority_bonus` subscore (현재 weight 0.0 잠금) 활성 + `evidence_density` weighted 변형(`weighted_density(n) = Σ_i court_grade_weight(evidence_i) / EVIDENCE_PER_NODE_CAP_WEIGHTED`) 도입을 v1+ formula round에 위임. *MVP는 count-based 시각 신호로 ship — 본 한계는 design/gdd/reviews/reasoning-workspace-decisions-2026-05-07-cycle2.md Decision 1에 명시.*

**Example:** evidence 3개 노드: ρ = 3/5 = **0.6**; bottom rule 길이 = 0.6 × 200px = **120px**.

## 5. Edge Cases

### 5.1 Empty / minimum tree

- **If 플레이어가 노드 0개로 Submit 클릭**: `submit()` 호출이 `FROZEN` 전이 *전* 차단 — Workspace가 즉시 `submission_rejected("empty_tree")` emit (`EvaluationService` 도달 X); 워크스페이스 `ACTIVE` 유지; DeskPane 인라인 hint "가설 트리에 노드가 없습니다. 하나 이상의 가설을 추가해주세요." 1차 방어선은 Submit 버튼이 node count == 0 동안 비활성 — 클릭 자체 차단. ADR-0007 §1은 `chain_data == {}`를 허용하나 본 UI 레이어 사전 차단으로 빈 submission이 EvaluationService에 전달되지 않음.

- **If 플레이어가 단일 루트 노드(evidence 0)로 Submit**: Submit 허용 (Rule 4는 최솟값 0 미금지). `chain_data.nodes`에 `evidence: [], memo_length: 0, child_count: 0` 단일 노드 포함된 채 전달. 결과 subscore의 `chain_coherence`·`citation_score`가 낮게 산출되는 것은 *평가 시스템의 의도된 동작* — 에디터 레이어 추가 차단 없음. *v1+ chain_coherence boundary policy* (§4.3): `node_count == 1` 또는 `total_evidence_count == 0` 시 chain_coherence = 0 short-circuit — div-zero · NaN 전파 방지.

- **If 노드가 레이블만 있음 (memo·evidence·children 모두 없음)**: 차단 없음 (Rule 4·5 위반 아님). `memo_length: 0, evidence: [], child_count: 0`으로 직렬화되어 `chain_data` 포함. 평가 가중치 산출 시 낮은 contribution 반영은 설계 의도.

### 5.2 Tree-structural violations

- **If plain drag으로 깊이 4 위치에 노드 배치 시도** (Rule 2 cap 위반): 드롭 직전 깊이 검증 실패 → 드롭 거부, 노드 원위치 애니메이션 복귀, DeskPane 하단 "이 가지는 더 깊이 나눌 수 없습니다" hint (Rule 2 지정). 부모 노드 visual drop zone 하이라이트는 드래그 중 실시간 비활성 — depth-3 노드의 drop target 자격 없음을 즉시 시각화 (커서 변경).

- **If plain drag으로 사이클 생성 시도** (조상을 후손 위 드롭): `parent_id` 체인 재귀 검사 → 사이클 감지 시 드롭 거부 + 원위치 복귀 + "노드를 자신의 하위 노드로 이동할 수 없습니다" hint. `chain_data` forest 계약 보유 — 사이클 허용 시 직렬화 루프. 검증은 드롭 완료 *전* 동기 실행 의무.

- **If 동시 drag 두 건 발화** (multi-select 제스처 또는 rapid input): Workspace는 동시 drag context 1건만 보유 (first-drag-wins). 두 번째 드래그 시작 신호 무시. 첫 드래그 완료(드롭 또는 취소) 후 두 번째 드래그를 새로 시작해야 한다. 추가 에러 표시 없이 silent — 복잡한 multi-drag UX는 MVP scope 외.

- **If `parent_id`가 존재하지 않는 `node_id` 참조** (Save/Load 역직렬화 시 손상된 데이터): `WorkspaceData` 로드 시점에 integrity sweep 실행 — 미존재 `parent_id` 노드는 `parent_id = ""`로 보정(루트 승격) + 부모 노드의 `children`에서 해당 node_id 제거. 플레이어에게 silent repair. `workspace_state_changed` emit 후 `#3 Save/Load`가 정합 상태 재저장. 손상 발생 시 에디터 콘솔 `push_warning("WorkspaceData integrity: orphan node [id] promoted to root")` 기록.

### 5.3 Evidence drop edge cases

- **If 플레이어가 Library precedent 루트(`case:2019do1234` — `/holding-N` 미포함) 드롭**: Rule 4 타입 검증 실패 → 드롭 거부 + 카드 원위치 튕김 애니메이션 + "판시 단락(holding) 단위로 인용해주세요" hint (Rule 4 지정). 시각: 대상 노드 drop zone brief red flash (150ms) 후 원래 색 복귀 — 허용 불가 명시.

- **If 드롭한 Library entry의 `library_id`가 LibraryService에 미존재** (드래그 시점·평가 시점 사이 캐시 불일치): (a) 드래그 중 `citation_drag_started(library_id)` 수신 시 Workspace는 ID 유효성 검사를 하지 않음 — 검사 책임은 LibraryService. (b) `EvaluationService.submit()` Validating 단계에서 `LibraryService.validate_citations(player_citations)` 호출 시 미존재 ID 감지 → `submission_rejected("invalid_citation:[library_id]")` emit → Workspace `FROZEN` → `ACTIVE` 복귀. DeskPane "존재하지 않는 인용 항목이 포함되어 있습니다. 인용을 확인해주세요." 메시지. 해당 evidence는 노드에서 *수동 제거* 의무 (자동 제거 X — 플레이어 의도적 확인 필요).

- **If 동일 `library_id`를 같은 노드에 재드롭** (Rule 4 중복 차단): 두 번째 드롭 거부 + 카드 원위치 즉시 복귀(애니메이션 없음 — silent drop cancel) + 대상 노드의 이미 첨부된 동일 evidence 항목이 250ms yellow flash (중복 항목을 시각적으로 지시). hint 텍스트 없음 — flash가 충분한 피드백.

- **If 노드 evidence count가 정확히 5이고 6번째 드래그**: 드래그 중 노드 위 커서 진입 시 drop zone 하이라이트 비활성 + 커서 "금지" 심볼 변경 (드롭 불가 선행 피드백). 드롭 발생 시 카드 원위치 복귀 + "이 노드에는 인용을 5개까지만 첨부할 수 있습니다" hint (Rule 4 지정). 실시간 커서 피드백이 hint보다 우선.

- **If 드롭한 Library 카드가 노드 사이에 떨어짐** (no hit-test target — Rule 4 §3.3): hit-test 결과 유효 노드 없음 → 카드가 드롭 위치에서 원본 LibraryPane 위치로 ease-back 애니메이션 복귀 (0.25s ease-out) + "노드 위에 드롭해주세요" hint. 카드는 LibraryPane `ItemView`에서 사라지지 않음 — 동일 카드 재드래그 가능.

### 5.4 Lifecycle / state transitions

- **If `submission_rejected`가 Workspace `INACTIVE` 중 도착** (평가 중 플레이어 이탈 — 경쟁 조건): `INACTIVE` 상태 수신은 무시. Workspace `INACTIVE` 유지. 플레이어가 해당 케이스로 재진입(`workspace_handoff_started`) 시 `ACTIVE` 전환되며 거부 사유는 `WorkspaceData`에 임시 보관 → DeskPane 상단 배너 "이전 제출이 거부되었습니다: [reason]".

- **If `evaluation_completed` 도착했으나 `case_id` 불일치** (케이스 전환 중 평가 완료): Workspace는 수신된 `result.case_id`가 현재 `active_case_id`와 다르면 시그널 무시. `EvaluationResult`는 #11 Career Progression이 독립 수신·영속화 — 데이터 손실 없음. Browser Catalog의 해당 케이스 봉투는 `Resolved`로 갱신 (Browser가 `evaluation_completed` 직접 수신). Workspace는 현재 케이스 상태 유지.

- **If 플레이어가 FROZEN 중 ANY 입력 시도**: 트리 편집(추가/이동/삭제/레이블), evidence 드롭, 메모 편집, Submit 재클릭 모두 무시. 입력 이벤트 consumed 처리 — UI 위젯 자체 disable. "제출이 처리 중입니다" 오버레이 배너 계속 표시. **예외**: `Escape` 키 + 메인 메뉴 접근은 무시 대상에서 제외 — FROZEN 중에도 메뉴 탐색 허용 (Pillar 3 — 어떤 UX 압박도 플레이어 이탈 자유 침해 X). 메뉴 이탈은 5.4 첫 항목의 INACTIVE 경쟁 조건으로 처리.

- **If 게임이 FROZEN 중 크래시·종료** (chain_data export 후 평가 미반환): 재시작 시 `WorkspaceData`는 `FROZEN` 상태로 직렬화됐으나 `EvaluationService`는 `IDLE` 초기화. Workspace는 기동 시 저장 상태가 `FROZEN`임을 감지 → 자동으로 `ACTIVE` 복구 + "이전 세션에서 제출이 완료되지 않았습니다. 다시 제출해주세요." 배너. `chain_data` 스냅샷은 `WorkspaceData`에 보존 → 재제출 시 *동일 스냅샷 재사용* (사후 편집 없이 동일 내용 재전달 — Pillar 1 가드 유지).

- **If `workspace_handoff_started`가 이전 케이스 Workspace `ACTIVE` 중 도착** (Browser §3 코너): `workspace_handoff_started(case_id_B)` 수신 시 현재 ACTIVE case_A에 대해 `workspace_handoff_ended(case_id_A, "paused")` 자동 emit 후 case_B 전환. case_A `WorkspaceData`는 #3 Save/Load가 직렬화 (`workspace_state_changed` emit 포함). case_B Workspace `INACTIVE` → `ACTIVE`. 플레이어 경고 없음 — "paused" 이탈은 정상 흐름.

### 5.5 Memo edge cases

- **If memo가 정확히 500자에서 추가 입력 시도** (Rule 5 cap): `TextEdit.max_length=500` 하드 캡 → 501번째 키 입력 자체 차단 (입력 무시). 별도 에러 메시지 없음 — 글자 수 카운터 "500/500" 실시간 표시가 cap 도달 인지 제공. 붙여넣기 시 500자 초과분 잘림 (truncate-on-paste).

- **If memo가 공백·이모지 only**: 허용. Rule 5 내용 형식 제약 없음 (plain text MVP). 저장·직렬화·`memo_length` 계산은 실제 character count 그대로. `chain_data`에는 `memo_length`(공백·이모지 포함 character count)만 포함, 본문 미포함 (Pillar 1 가드 — 공백 메모도 평가 미반영).

- **If 5000자 클립보드를 메모에 붙여넣기** (MVP plain text): `TextEdit.max_length=500` 적용 → 첫 500자만 삽입, 이후 잘림. 잘림 발생 시 카운터 "500/500"으로 즉시 갱신 — 시각 피드백. 경고 다이얼로그 없음.

### 5.6 Pillar 1 guard violations (silent regressions)

- **If 미래 코드 변경이 `chain_data`에 `memo_text`를 포함시키려 시도**: `chain_data` Dictionary는 `schema_version: 1` 하에서 허용 필드 집합을 `schema_version`, `nodes`, `edge_count`, `max_depth_reached`, `total_evidence_count`로 잠금. `submit()` 호출 직전 chain_data 빌더는 allow-list 검증 — `memo_text` 또는 비허용 필드 포함 시 `push_error("chain_data schema_version=1 violation: forbidden field [field_name]")` + `submission_rejected("schema_violation")` emit. 빌더가 자기 생성 dict를 자기 검증 — unit test AC 항목 커버 의무.

- **If Library entry의 `hanja_terms`(또는 미래 확장 필드)가 `library_id` 형식 변경 시도**: `library_id` 계약은 `LibraryEntry.id` 단일 소스이며 런타임 합성 ID(`case:.../holding-N`)는 `<file.id> + "/holding-" + N` 고정 패턴 외 변형 불허. `hanja_terms` 등 확장 필드는 검색·표시 전용 — evidence 배열 저장 또는 citation 검증 경로에 투영 X. LibraryService `get_entry(id)` 인터페이스는 합성 완료 ID만 입력으로 받도록 타입 계약 유지. 향후 ID 형식 변경 시 별도 migration + `schema_version` bump 의무 (Library ADR-0001 amendment 절차 mirror).

### 5.7 Workspace-Browser boundary

- **If 플레이어가 case A WorkspaceHandoff 후 mid-edit으로 case B WorkspaceHandoff 발화** (case A 미제출): 5.4 마지막 항목 처리 경로 적용. case A는 `workspace_handoff_ended(case_id_A, "paused")` auto-emit → `INACTIVE`. 삭제 확인 다이얼로그 없음 — case A 트리·메모·evidence는 `WorkspaceData`에 보존되며 재진입 시 복원 (Rule 8 §3.3 persistence 정합, Browser §AC-20 post-WorkspaceHandoff tree+memo PERSISTENT 보장). case B Workspace `ACTIVE` 진입.

- **If `workspace_handoff_ended(reason: "paused")`가 Workspace `FROZEN` 중 emit 시도**: 상태 머신상 불가능 — `FROZEN` 진입 조건은 Submit 클릭이고 `workspace_handoff_ended` emit 조건은 ACTIVE 이탈 또는 READ_ONLY 후 Browser VerdictArrived 완료. 그러나 방어적 guard로: `workspace_handoff_ended` 수신 시 Workspace가 `FROZEN`이면 시그널 무시 + `push_warning("workspace_handoff_ended received during FROZEN — ignored; evaluation in progress")`. Browser는 이 거부를 관찰 불가하므로 Browser `WorkspaceHandoff` 상태가 교착 가능 — 이 경우 Browser측 타임아웃 가드 필요 (**OQ-W8** Browser 위임).

## 6. Dependencies

본 GDD가 의존하는 시스템·ADR 인터페이스를 양방향(상류·하류·아키텍처) 명시. 각 행은 §3.3에서 잠근 시그널/API 계약을 응축하고, 후속 ADR 또는 GDD가 변경 시 본 GDD 갱신 트리거를 발동시키는 traceability hook 역할.

### 6.1 시스템 의존성 (양방향)

| # | 시스템 | 방향 | 강도 | 인터페이스 | 본 GDD 측 책임 | 상대 측 책임 |
|---|---|---|---|---|---|---|
| **#1** | Case Data Schema | 상류 (Read-only) | Hard | `CaseService.get_case(case_id) -> CaseFile` | `case_id`로 케이스 메타 조회. **`correct_disposition` / `correct_citations` / `scoring_weights` 접근 금지** (정보 격리 — 사후 정당화 방지 Pillar 1 가드) | Case Resource를 Library 참조 ID로 직렬화 (#1 GDD §3 정합) |
| **#20** | Legal Reference Library | 상류 (Read-only) | Hard | `LibraryService.get_entry(id)`, `LibraryService.get_holding(synthesized_id)`, `LibraryService.validate_citations(ids)`; CitationDrop 시그널 2종 (`citation_drag_started`, `citation_dropped`) | Evidence 카드 표시·드롭 처리·invalid_citation EC §5.3 처리 | Holding 합성 ID 일관성 (Library §3.1.2), 드래그 시그널 emit (Library §3.2 CitationDrop state) |
| **#3** | Save/Load | 하류 (Read+Write 위임) | Hard | Workspace `workspace_state_changed` emit; #3가 직렬화 시점 결정 | 상태 변경 시 시그널 emit; 직접 파일 I/O 금지 | `WorkspaceData` Resource를 케이스 lifecycle 동안 직렬화/역직렬화. **저장 빈도 정책 #3 GDD 위임 (OQ-W4)**; integrity sweep 대상 (orphan node EC §5.2 처리) |
| **#7** | Brief Editor | 하류 (chain_data 입력 계약 제공) | Soft | `node.evidence` 배열에서 `{{cite:<library_id>}}` 토큰 자동 생성 (Library `library_brief_cite_token` constant 정합) | Evidence ID array를 Brief Editor에 노출 | Brief Editor가 워크스페이스 evidence를 인용 토큰으로 변환 |
| **#9** | Submission & Evaluation | 하류 (chain_data export) | Hard | `EvaluationService.submit(PlayerSubmission)`; `chain_data` Dictionary export (ADR-0007 §1); `submission_rejected` / `evaluation_completed` 시그널 수신 | Freeze 행동 계약 (ADR-0007 §3.2 forward-constraint) 이행; chain_data schema_version=1 빌드·검증; FROZEN/READ_ONLY 상태 머신 | EvaluationService autoload (ADR-0007 §2); 평가 결과 evaluation_completed emit |
| **#14** | Retrospective Replay (Alpha) | 하류 (READ_ONLY 데이터 소스) | Soft | READ_ONLY 상태의 `WorkspaceData` 인스턴스 | 결정문 도착 후 워크스페이스 아카이브 보존 (불가변) | 아카이브 열람 인터페이스 — *본 GDD scope 외* (#14 위임) |

**의존성 그래프 (compact)**:

```
#1 Case Data Schema  ──read──┐
#20 Legal Library    ──read──┤── #6 Reasoning Workspace ──emit──> #3 Save/Load
                              │                          ──read──> #7 Brief Editor
                              └────chain_data export────> #9 Submission & Evaluation
                                                          │
                                                          └──submission_rejected/
                                                             evaluation_completed
                                                             └────> #6 (back to ACTIVE/READ_ONLY)
                                                                    └──READ_ONLY──> #14 Retrospective Replay
```

### 6.2 아키텍처 의존성 (ADR)

| ADR | Status | 본 GDD 의존 사항 | 변경 트리거 |
|---|---|---|---|
| **ADR-0001** (Library Storage Format) + Amendment 1 + 1.1 | Accepted | `LibraryEntry` / `LibraryLawEntry` / `LibraryPrecedentEntry` / `LibraryHolding` 클래스 트리. Evidence ID 형식 (`law:...`, `case:.../holding-N`) 계약. | Library ID 형식 변경 시 Rule 4 evidence 타입 검증·EC §5.6 forward-defense 갱신 의무 |
| **ADR-0004** (Korean Text Rendering MSDF Font) | Proposed (verification 대기) | Theme type variations (`&"BodyLabel"`, `&"CommentLabel"`, `&"MemoLabel"`, `&"MemoEdit"`, `&"CourtHeadline"`, `&"CaptionLabel"`); `RichTextLabel + scroll_active=true` 가상화 (메모 본문); `inline_theme_override_without_type_variation` forbidden_pattern; `text_server/backend = "TextServerAdvanced"` 의존 | Theme key 추가/변경 시 §3.1 Rule 5 + §8.1.6 + §9.4 갱신 |
| **ADR-0007** (Submission Evaluation Algorithm) | Proposed (verification 대기) | §1 chain_data Dictionary 입력 계약 (schema_version=1); §3.2 freeze 스냅샷 forward-constraint (submit() 시점 workspace 메모 불가변); EvaluationService autoload + `submission_rejected` / `evaluation_completed` 시그널 | chain_data 스키마 변경 시 ADR amendment + GDD §3.1 Rule 6 + §4 Formulas + §7 schema_version knob 동시 갱신 |
| **Workspace Layout ADR** (provisional — 미작성) | Pending | 3-Pane 레이아웃 내 DeskPane 위치/크기, 메모 패널 OQ-W5 ratify, 트리 캔버스 panning OQ-W10, gamepad CitationDrop OQ-W9, **CitationDrop signal topology** (`citation_drag_started`/`citation_dropped` 발신자 + Godot 4.6 native drag-drop API 채택 vs autoload signal 선택 — OQ-W13), 노드 카드 inner padding (effective text box 200×46px — bottom evidence rule 영역 예약) | 본 GDD §9 PROVISIONAL → LOCKED 전환의 prerequisite. §3.3 시그널 contract만 본 GDD에서 잠금; emitter 구체는 본 ADR 책임 (decisions-2026-05-07 Gate ③ 위임 검증 invariant 4건 준수). UI Foundation epic 진입 시 작성 의무 |

### 6.3 GDD 횡단 의존성 (정합 요건)

| 상대 GDD | 잠금 사항 | 본 GDD 측 이행 |
|---|---|---|
| **#5 Case File Browser §3.6 WorkspaceHandoff** | Browser가 FactsOpen → WorkspaceHandoff 전이 시 통제권 위임. `workspace_handoff_started(case_id)` emit | §3.3 시그널 명세 closure (Browser §6 OQ-5 해소) |
| **#5 Case File Browser §AC-20** | Pre-WorkspaceHandoff 메모 *VOLATILE* / Post-WorkspaceHandoff 워크스페이스 트리 + 메모 *PERSISTENT* | §3.3 Persistence 정책 (Rule 8) — `WorkspaceData`는 케이스 InProgress 동안 #3가 직렬화. 본 GDD가 *영속 메모* 정책 책임 |
| **#20 Library §3.1.2** | Holding ID 합성 규칙 `<file.id> + "/holding-" + N` 단일 source | §3.1 Rule 4 evidence 타입 검증 (precedent root 거부 — holding 단위만) |
| **#20 Library §3.2 CitationDrop state** | Library가 드래그 시작 시 `citation_drag_started(library_id)` emit; Workspace가 drop target 정책 책임 | §3.3 CitationDrop 시그널 명세 + Rule 4 정책 (cap·중복·타입) |
| **#9 Submission & Evaluation §3.1.1** | PlayerSubmission Resource의 `chain_data: Dictionary` 필드 | §3.1 Rule 6 + §4.1 chain_data 빌드 책임 본 GDD |
| **#2 UI Foundation** (미설계) | Workspace UI Control 노드 구체 | §9 PROVISIONAL — Control class 선택 위임. UI Foundation 작성 후 본 §9 LOCKED 전환 |

### 6.4 의존성 강도 분류

- **Hard (시스템 미존재 시 본 GDD 기능 중단)**: #1, #20, #3, #9, ADR-0001/0004/0007
- **Soft (선택적 enhancement)**: #7 (Brief Editor 없어도 Workspace 작동), #14 (Alpha 시스템 — MVP 외)
- **Pending hard-gate (미설계 의존, MVP QA 진입 차단 의무 — 2026-05-07 cycle 2 강화)**:
  - **#4 Settings & Accessibility GDD** — accessibility I-9 IMPORTANT closure: Workspace MVP는 #4가 최소 3 API (`reduced_motion: bool`, `text_scale: float [1.0, 2.0]`, `keyboard_shortcut_remap: Dict[String, String]`) 제공 시점까지 QA 진입 차단. AC-40·AC-41·§9.6 keyboard configurable 모두 #4 의존.
  - **#2 UI Foundation** — §9 PROVISIONAL 잠금만; Control class 구체는 Workspace Layout ADR 위임 (UI Foundation epic 시작 전제).
  - **Workspace Layout ADR** — 메모 패널 OQ-W5 fallback ratify + gamepad OQ-W9 + panning OQ-W10 + signal topology OQ-W13. **§8.1.1.b inner padding spec은 본 GDD 2026-05-07 cycle 2에서 잠금 (위임 폐기)** — Workspace Layout ADR scope 축소.

## 7. Tuning Knobs

### 7.1 Structural Caps

| Knob | Type | Default (MVP) | Safe Range | Affects | Extreme Behavior |
|---|---|---|---|---|---|
| `max_tree_depth` | int | 3 | 2 – 5 | §3.1 Rule 2 트리 깊이 제한; chain_data `max_depth_reached` 상한 | <2: 루트+자식 2계층만 — "상고이유 → 쟁점" 표현만 허용, 판례 근거 계층 소실, Pillar 1 가중치 신호 빈약; >5: 트리가 다단계 프레임으로 분기 — `total_evidence_count` 상한이 depth × evidence_per_node_cap으로 선형 확대, 인지 과부하 |
| `evidence_per_node_cap` | int | 5 | 3 – 8 | §3.1 Rule 4 노드당 첨부 evidence 최대 수; chain_data `total_evidence_count` 공동 상한 | <3: 노드 하나가 판례 2건 이하 — 인용 전략 폭 협소, 중요 판결 선택 압박 과다; >8: 인용 희석 — 핵심 판시 단락이 잡음에 묻혀 Pillar 1 가중치 신호 저하 |
| `node_label_char_limit` | int | 60 | 30 – 120 | §3.1 Rule 3 레이블 *입력·저장* cap (display는 ellipsis truncation 정책 — Rule 1 참조; 200×48px 카드 inner box 단일 행 표시 ~13–15자, 그 이상은 hover tooltip + 편집 진입 + F2 list view에서 노출) | <30: 가설 문장 절단 불가피 (저장 자체 cap), 플레이어 좌절; >120: 입력 길이 부담 + ellipsis 빈도 증가로 시각 노이즈; 카드 자체 높이는 영향 없음 (truncation으로 안전) |
| `node_memo_char_limit` | int | 500 | 200 – 2000 | §3.1 Rule 5 메모 TextEdit 입력 cap; `RichTextLabel scroll_active` 활성화 시점 압박 | <200: 메모 공간이 너무 협소 — 사고 보조 기능 무력화; >2000: 단일 노드 메모가 단문 준비서면 수준이 되어 §7 Brief Editor 역할 침범, chain_data `memo_length` 집계 불균형 |
| `max_root_count` | int | unlimited | 1 – 20 | 병렬 가설(다중 루트) 최대 수 — v1+ 플래그 | <1: 병렬 가설 불가 — 게임 플레이 근본 제약; =1: 단일 루트 강제, 다양한 상고이유 탐색 불가; >20: DeskPane 수평 오버플로 — 레이아웃 UX 파탄, §9 요건 범위 초과 |

### 7.2 Interaction Tuning

| Knob | Type | Default (MVP) | Safe Range | Affects | Extreme Behavior |
|---|---|---|---|---|---|
| `node_drag_threshold_px` | float | 8.0 | 4 – 16 | §3.1 Rule 3 이동 의도 인식 — plain drag 시작 감지 픽셀 (click vs drag 구별 임계) | <4: 미세 움직임에도 드래그 시작 → 클릭 중 의도치 않은 노드 이동 다수; >16: 드래그 시작이 느껴질 만큼 지연 — 이동 의도 인식 불량, `evidence_hit_test_tolerance` 부등식 위반 리스크 |
| `evidence_hit_test_tolerance_px` | float | 16.0 | 8 – 32 | §3.1 Rule 4 CitationDrop — 드롭 타겟 노드 히트박스 확장 | <8: 소형 노드 위 드롭 정확도 요구 과다 — 정밀 조작 스트레스; >32: 인접 노드 히트박스 중첩 → 잘못된 노드에 evidence 첨부 빈발 |
| `node_double_click_window_ms` | int | 350 | 200 – 500 | §3.1 Rule 3 레이블 인라인 편집 진입 / Rule 3 루트 노드 추가 더블클릭 인식 | <200: 빠른 단순 클릭이 편집 진입 오발동; >500: 더블클릭 의도가 두 번의 단일 클릭으로 오판 → 편집 진입 불가, 선택 중복 토글 |

### 7.3 Visual Feedback Intensity (§9 Prep)

| Knob | Type | Default (MVP) | Safe Range | Affects | Extreme Behavior |
|---|---|---|---|---|---|
| `selected_border_thickness_px` | float | 2.0 | 1.0 – 3.0 | §3.1 Rule 1 선택 노드 보더 — Art Bible §3.1 정합 | <1.0: 선택 상태 인식 불량 — 어떤 노드에 메모 패널이 연결됐는지 불명확; >3.0: 보더가 카드 내 텍스트 영역 침범, 200×48px 레이아웃 압박 |
| `unselected_border_thickness_px` | float | 0.5 | 0.25 – 1.0 | §3.1 Rule 1 미선택 노드 보더 — Art Bible §3.1 정합 | <0.25: 노드 경계 소실 — 카드 식별 불가; ≥ `selected_border_thickness_px`: 선택/미선택 구분 신호 소실 (항상 unselected < selected 유지 필요) |
| `evidence_rule_visible` | bool | true | true \| false | §8.1.1.b bottom evidence rule (Channel B) 표시 여부 — Pillar 1 가시화 메인 채널 | =false: bottom rule 미표시 — Pillar 1 "무게가 보인다" 판타지 소실. *Selection signal(Channel A)만으로는 evidence weight 미가시 — 디버그 외 사용 금지* |
| `evidence_rule_thickness_px` | float | 2.0 | 1.5 – 3.0 | §8.1.1.b bottom evidence rule 두께 — 길이는 ρ에 종속 (튜닝 X), 두께만 조정 | <1.5: 인지 임계 근접; >3.0: 카드 inner box (effective 200×46px) text vertical center 압박 — Layout 의존 |
| `freeze_overlay_fade_ms` | int | 250 | 150 – 500 | §3.1 Rule 7 FROZEN 상태 진입 시 오버레이 배너 페이드인 속도 | <150: 배너가 즉각 등장 — 플레이어 깜짝 놀람, 전환 폭력적; >500: 오버레이가 느리게 떠서 플레이어가 FROZEN 상태임을 인지하기 전에 입력 시도 → UX 혼란 |

### 7.4 Confirmation Thresholds (Pillar 3 — *cut* anchor)

| Knob | Type | Default (MVP) | Safe Range | Affects | Extreme Behavior |
|---|---|---|---|---|---|
| `delete_confirmation_subtree_threshold` | int | 0 | 0 – 5 | §3.1 Rule 3 삭제 확인 다이얼로그 발동 조건 — 서브트리 총 노드 수 N 이상일 때 확인. Default 0 = 항상 확인 | =0: 항상 확인 — Pillar 3 "삭제 무게" 판타지 완전 보존; =1: 단일 리프 삭제는 확인 없이 진행 — 경량화 UX이나 Pillar 3 약화; >5: 깊은 서브트리 삭제도 즉시 실행 — 판타지 침해, §2 Player Fantasy "아깝다는 감각" 소실 |

### 7.5 chain_data Export

| Knob | Type | Default (MVP) | Safe Range | Affects | Extreme Behavior |
|---|---|---|---|---|---|
| `chain_data_schema_version` | int | 1 | locked | §3.1 Rule 6 chain_data Dictionary 구조 식별자 — ADR-0007 §3.2 마이그레이션 계약 | 임의 변경 금지. 스키마 변경은 ADR-0007 Amendment로만 처리. 변경 없이 버전 번호만 올리면 `EvaluationService` 파싱 오류 |

### 7.6 Tuning Interaction Warnings

세 가지 위험한 조합을 주의해야 한다.

**구조 상한 공동 효과.** `max_tree_depth`와 `evidence_per_node_cap`은 chain_data `total_evidence_count` 상한을 공동으로 결정한다. MVP 기본값 기준 이론적 최대는 `(4^0 + 4^1 + 4^2 + 4^3) × 5 = 425`이나 실제 `max_root_count`와 분기 패턴에 따라 달라진다. 두 값을 동시에 올릴 경우 chain_data 직렬화 크기와 v1+ `EvaluationService` chain_coherence 연산 비용이 배수로 증가한다.

**드래그 vs 히트 테스트 부등식.** `node_drag_threshold_px`와 `evidence_hit_test_tolerance_px`는 반드시 `evidence_hit_test_tolerance_px ≥ node_drag_threshold_px` 관계를 유지해야 한다. 이 부등식이 무너지면 드롭 히트 테스트가 등록되기 전에 드래그가 시작되어 evidence 첨부가 항상 차단된다.

**Pillar 3 약화 플래그.** `delete_confirmation_subtree_threshold > 0` 으로 높이면 Pillar 3 "삭제 무게" 앵커가 약화된다. 이 값을 변경하기 전에 game-designer 검토를 받아야 한다 — §2 Player Fantasy의 "누구도 재촉하지 않는다" 경험은 시간 압박이 없는 환경에서 확인 다이얼로그가 유일한 마찰 포인트이기 때문이다.

### 7.7 Knob 저장 위치

| 범주 | 값 | 저장 위치 |
|---|---|---|
| 구조 상한 (§7.1) | `max_tree_depth`, `evidence_per_node_cap`, `node_label_char_limit`, `node_memo_char_limit`, `max_root_count` | `design/registry/entities.yaml` constants 섹션 (cross-system 등록 대상) |
| Pillar 3 임계값 (§7.4) | `delete_confirmation_subtree_threshold` | `design/registry/entities.yaml` constants 섹션 |
| 인터랙션·시각 피드백 (§7.2, §7.3) | drag threshold, hit-test tolerance, double-click window, border thickness, modulation strength, fade duration | `assets/data/workspace/tuning.tres` (Workspace 전용 튜닝 Resource) |
| chain_data 스키마 버전 (§7.5) | `chain_data_schema_version` | ADR-0007에 잠금 — 별도 파일 저장 불필요 |

구조 상한은 EvaluationService(ADR-0007), §7 Brief Editor, §10 Verdict Reveal이 동일 값을 참조하므로 레지스트리 등록 필수. 인터랙션·시각 튜닝은 Workspace 내부 전용이므로 ADR-0001/0004 관례를 따라 theme resource 또는 전용 tuning resource로 격리.

## 8. Visual/Audio Requirements

본 섹션은 Reasoning Workspace의 시각·오디오 요건을 정의한다. 모든 시각 결정은 Art Bible의 인쇄 미학을 따르며 — *법정 기록* 톤의 잉크블랙·판결지·인장빨강 팔레트, 0.5px·2px 두 단계 보더, 외부 그림자 없음 — Pillar 1(가중치 시각화)와 Pillar 3(시간 압박 0의 침묵)을 직접 구현한다. 모든 오디오 결정은 *물리적 책상의 종이·펜·법정 atmosphere*를 차용하며 게임 컨벤션의 긴장 자극·시간 압박 큐를 명시 금지한다. 시각·오디오는 1:1 중복(audio 단독 정보 전달 금지) 의무 — 접근성 요건(§9.6) 정합.

### 8.1 Visual Requirements

**8.1.1 Node visual states**

모든 spec은 Art Bible §3 (Shape Language), §4 (Color System), §7 (Motion Style) 정합. Visual signal은 **두 직교 채널**로 분리 (Gate ② decisions-2026-05-07 참조):
- **Channel A (Selection)**: 외곽 보더 두께 — binary (0.5px 미선택 / 2px 선택).
- **Channel B (Evidence weight)**: 노드 하단 *bottom evidence rule* 길이 — continuous 6단계 ρ ∈ {0.0, 0.2, 0.4, 0.6, 0.8, 1.0} (§4.4 evidence_density · §8.1.1.b 명세).

두 채널은 동시 발화해도 충돌 없음 — 본 결정은 0.125px subpixel 인지 임계 미달 + selection signal과의 신호 압도 문제(2026-05-07 review BLOCKING #6/#7) 해소.

| State | Border (Channel A) | Background | Text color | Shadow | Notes |
|---|---|---|---|---|---|
| `default unselected` | 0.5px **미드그레이 `#8C8C8C`** (Art Bible §3 라인 무게 표 + WCAG 1.4.11 non-text contrast 3.0:1 충족 — accessibility BLOCKING #3 closure; 기존 `#D9D6CF` 1.3:1 ratio 폐기) | 판결지 `#F5F2EC` | 잉크블랙 `#1A1A1A` | 없음 (Art Bible §3 "외부 그림자 없음") | 기준선 — bottom rule(Channel B)이 별개로 발화 |
| `selected` | 2px 잉크블랙 `#1A1A1A` (Art Bible §3 "활성·선택 강조 2px") | 판결지 `#F5F2EC` — 배경색 변화 없음 (Art Bible §3 "배경색 변화 없음") | 잉크블랙 `#1A1A1A` | 없음 | 테두리 두께 전환만 — 0.05초 (Art Bible §7 클릭 피드백). bottom rule(Channel B) 길이 영향 없음 |
| `drop target hover (CitationDrop 중)` | 1px 잉크블랙 `#1A1A1A` — 미선택에서 0.5px→1px 상승. 선택은 2px 유지 | 판결지 `#F5F2EC` — 배경 변화 없음 (Art Bible §3 원칙) | 잉크블랙 `#1A1A1A` | 없음 | 드래그 진입 즉시 전환. 이탈 즉시 복원. 0.08초 (Art Bible §7 호버 속도) |
| `drop target REJECTED flash (shape-only, 인장빨강 폐기)` | 1.5px **미드그레이 `#8C8C8C` 점선** (`StyleBoxFlat` border_dash 또는 등가) | 판결지 `#F5F2EC` — 배경 변화 없음 (인장빨강 5% 투명 폐기 — art-director B-NEW-1 BLOCKING closure: 인장빨강 단독 시맨틱 결정문 전용 lockdown 정합) | 잉크블랙 `#1A1A1A` | 없음 | 150ms 후 원래 상태로 선형 페이드. 거부 신호는 *shape cue (점선)* + 카드 원위치 ease-back으로 전달 — 색 채널 사용 X. 색맹 가드: spatial+motion 채널 다중 |
| `evidence duplicate flash (subtle grey tint)` | 기존 보더 유지 | 미드그레이 10% 투명도 `#8C8C8C1A` (Art Bible §4 팔레트 준수 — 색맹 가드: 색 단독 의존 금지; flash는 spatial 위치 cue 보완) | 잉크블랙 `#1A1A1A` | 없음 | 250ms 후 페이드. 경고가 아닌 *지시* — 이미 있는 항목을 조용히 가리킨다. bottom rule 영향 없음. *(art-director I-1 IMPORTANT closure: state name "yellow" → "subtle grey tint" — 실제 색과 일치)* |

**Pillar 3 (시간 압박 0)**: 플래시 두 종 모두 단기 시각 후 즉시 소멸 — 상태가 남지 않고 화면이 정적으로 복귀.

**8.1.1.b Bottom evidence rule (Channel B — Pillar 1 가시화 채널)**

각 노드 카드 하단에 가로 *evidence rule* (밑줄 강조 mark)이 evidence 수에 비례한 길이로 표시 — 한국 법조 문서의 *중요 부분 밑줄* 관례 직접 차용.

| 변수 | 값 |
|---|---|
| 위치 | 노드 카드 하단 edge — 카드 외곽 보더의 *내측* (보더가 룰을 시각적으로 감싸지 않음). 좌측 정렬 |
| 두께 | 2.0px (고정 — `evidence_rule_thickness_px` knob §7.3) |
| 색상 | 잉크블랙 `#1A1A1A` (Art Bible §3 line weight 표 — 활성 line) |
| 길이 | `ρ × node_inner_width` — `ρ = len(n.evidence) / EVIDENCE_PER_NODE_CAP` (§4.4). MVP cap=5 기준 6단계 0%·20%·40%·60%·80%·100% |
| 가시 조건 | `ρ > 0` 시 표시; `ρ == 0` 시 미표시 (룰 자체 없음 — 카드 하단 빈 공간) |
| 추가 (evidence add) | 0.15초 linear width tween 좌→우 grow (Art Bible §7 "문서 간 전환 0.15초 페이드" 정합) |
| 제거 (evidence remove) | 0.15초 linear width tween 우→좌 shrink |
| Reduced-motion 모드 | tween 비활성, snap to final width (AC-40 정합) |

**Layout — inner padding spec (art-director B-NEW-5 BLOCKING closure 2026-05-07 cycle 2)**: 200×48px 카드 기준 inner padding 명세를 본 GDD에서 잠금 (Workspace Layout ADR 위임 폐기 — Gate ② tradeoff (a) 직접 이행):

| 영역 | 값 |
|---|---|
| Top padding | 6px |
| Left padding | 8px |
| Right padding | 8px |
| Bottom padding | 4px (`evidence_rule_visible == false` 시) / 2px text + 2px rule 영역 (`evidence_rule_visible == true` 시) |
| Effective text box (rule 부재) | 184×38px |
| Effective text box (rule 활성) | 184×40px (수직 정렬은 위쪽 6px + 아래 2px text padding + 2px rule 영역 = 본문 높이 40px) |
| Label 폰트 | Pretendard Regular 14pt (line-height 18px — 단일 행 수용) |

이 padding은 Art Bible §3.1 200×48px hero shape 명세 *확장* (Art Bible amendment 트리거 — art-director가 Art Bible §3.1에 본 padding spec 등재 의무). Bottom rule은 inner padding 영역 내부 좌측 정렬, 좌측 padding 8px 시작점에서 grow → 200px node 좌측 edge에서 inset 되어 표시되지 않는다 (rule은 효과 영역 좌측 8px 시작 → ρ × 184px 길이 → 카드 내측 우측 padding까지). 즉 ρ=1.0 시 룰은 184px (200px 카드 inner 가로) 가득 차고, 카드 외곽 padding 영역은 룰이 침범 X. AC-37 픽셀 수치 정합 갱신 의무 (40/120/200px → 36.8/110.4/184px ±2px).

**Pillar 1 (가중치 시각화) 직접 구현**: bottom evidence rule 길이가 인용 수에 비례 — 인용이 쌓일수록 *밑줄이 길어진다*. 6 단계 이산 길이 (40px 단위)는 1080p에서 모두 명확히 구분 (subpixel 임계 ≫). `evidence_rule_visible == false` 또는 cap=0인 극단 케이스에서도 selection signal(Channel A)과 독립 — Pillar 1 메인 신호 채널 유지.

**색맹 가드**: 길이는 spatial cue 단독 — 색 단독 신호 의존 없음 (Art Bible §4 정합).

**8.1.2 Tree edges**

- **스타일**: 직선 (Art Bible §3 "선은 항상 직선이다"). 실선. 굵기 0.5px (Art Bible §3 "보조 정보 구분"). *art-director I-4 IMPORTANT 지적: parent-child 관계는 "단락 구분"보다 강한 의미이므로 1px 후보도 검토 가능. 본 cycle은 0.5px 유지 + Art Bible §3 amendment 시 재검토.*
- **색상**: **미드그레이 `#8C8C8C`** (기존 라이트그레이 `#D9D6CF` 폐기 — WCAG 1.4.11 non-text contrast 3:1 충족, accessibility BLOCKING #3 closure). 엣지는 구조의 보조 기록 — 결정 아님.
- **라우팅**: 직각 절곡 오서거널 (L-라우트). 트리 레이아웃이 판결문 번호 위계(I. 1. 가. ①.)와 시각적 일치.
- **추가**: 새 자식 노드 연결 시 0.2초 리니어 드로 — 라인이 부모→자식 방향 진행 (Art Bible §7 "노드 연결 생성 0.2초 리니어 드로. 잉크가 선 위를 천천히 지나가는 느낌"). Pillar 3 — 연결이 가볍지 않음을 모션으로 전달.
- **삭제**: 엣지 0.15초 페이드 아웃 (Art Bible §7 "문서 간 전환 0.15초 페이드").
- **이동**: 원위치 엣지 0.15초 페이드 → 새 위치 0.2초 드로. 순차.

**8.1.3 DeskPane background**

- **배경**: 판결지 `#F5F2EC` 단색 + 종이 텍스처 오버레이 (Art Bible §3 "봉투 질감 오프화이트 종이 텍스처"; 에셋 `tex_paper_aged_01.png` 1024×1024px BC7, Art Bible §8). 텍스처 채도 5% 이하 — 패턴 인지 안 되는 grain. 격자·선분 패턴 금지. Art Bible §1 "꾸밈 없고 구조만 있다".
- **여백**: 콘텐츠 영역 기준 Art Bible §3 페이지 그리드. DeskPane 내부 패딩 ≥24px — 트리 노드가 패널 경계에 붙지 않아 판결문 여백감 유지.
- **드롭존 힌트 (`citation_drag_started` 수신 시)**: DeskPane 전체에 **미드그레이 `#8C8C8C`** 1px 점선 border (border-radius 2px) — 기존 라이트그레이 폐기 (WCAG 1.4.11 정합). 내부 배경 변화 없음. "끌어오세요" 텍스트 금지 — Pillar 3 침묵. 드래그 종료 즉시 소멸. *(art-director I-6 IMPORTANT: Art Bible §3 "플레이어 인터랙션 힌트용 점선: 허용" 1줄 amendment 의무.)*

**8.1.4 Freeze overlay banner (§3.1 Rule 7) — "조용히 정지한다" 연출 (art-director B-NEW-2/B-NEW-3 BLOCKING closure 2026-05-07 cycle 2)**

- **오버레이**: DeskPane 전체 덮는 판결지 `#F5F2EC` **80% 불투명** (기존 60% → 80% 상향. art-director B-NEW-2 closure: 60%는 "흐릿"이 아닌 "뚜렷"; 80%에서 트리가 20% visibility — "아직 거기 있음" 암시 + 입력 차단 명확). 배경 트리가 흐릿하게 비치며 "아직 거기 있음" 암시 — 완전 차단 아님.
- **배너**: 수평 잉크블랙 `#1A1A1A` 바 (높이 64px), 오버레이 수직 중앙. 내부 텍스트 `&"CourtHeadline"` type variation (본명조 SemiBold 16pt — ADR-0004 §4. 인라인 theme override 금지). 문구: **"제출이 처리 중입니다"**. 텍스트 색: 판결지 `#F5F2EC` (반전 — 이 순간만 배경·전경이 뒤집힘 — Art Bible §2 상태 5 결정문 시퀀스 반전 패턴 *준비*; 결정적 반전은 #10 Verdict Reveal 전용으로 보존).
- **~~인장 모티프~~** **폐기 (art-director B-NEW-3 BLOCKING closure)**: 32px 인장은 Art Bible §3 히어로 셰이프 minimum (120px 캔본 + 내부 大法院 14pt) 위반 + Art Bible §1 원칙 4 ("결정문 도착 시퀀스 이외에 나타나지 않는다") 직접 충돌. **인장 모티프 제거** — 배너 텍스트 단독 처리. 결정성 신호는 배너 64px 두께 + 색 반전 + `weight-stamp-deep` 오디오로 전달 (인장빨강 lockdown — 인장은 #10 Verdict Reveal 전용).
- **연출 두 단계**: (1) 0–250ms 오버레이 페이드인 (`freeze_overlay_fade_ms` knob §7.3) — 배경 트리가 서서히 흐려진다. (2) 250ms 시점 배너 단독이 scale(1.0 유지) + opacity(0→1) 0.15초 페이드인 (Art Bible §7 "문서 간 전환 0.15초 페이드" 정합). 스케일 변화 폐기 — 인장 부재 시 *부드러운 등장*이 더 정합. ~~Art Bible §7 인장 도장 찍힘 1:1 정합~~ 폐기 (인장 자체가 부재).
- **해제**: 오버레이 + 배너 0.15초 페이드 아웃 후 트리 인터랙션 재활성.

**8.1.5 READ_ONLY post-evaluation visual**

- **표시**: DeskPane 전체에 `CanvasItem.modulate` 채도 감쇠 — **15% 감쇠 (기존 5% → 15% 상향. art-director I-3 IMPORTANT closure: 5%는 1080p 육안 인지 임계 ~10-15% 미달; 15%는 임계 통과 + 30% 워터마크와 보완 신호로 작동)**. 완전 그레이스케일 금지 — 트리 구조가 판독 가능해야 한다 (#14 Retrospective Replay 데이터 소스).
- **워터마크**: DeskPane 전체에 판결지 배경색 30% 불투명 오버레이 (FROZEN 60%보다 옅게 — 아카이브 상태 조용히 알림). 배너 없음 — READ_ONLY는 조용한 종결이지 FROZEN의 적극적 차단 아님. Art Bible §2 상태 6(회고) "낮은 에너지. 마무리의 고요."
- **노드 테두리**: 전체 노드 border를 **미드그레이 `#8C8C8C`** 0.5px 고정 (라이트그레이 `#D9D6CF` 폐기 — WCAG 1.4.11 정합; 선택/비선택 구분 소실 — 더 이상 편집 가능한 작업 공간 아님).
- FROZEN(배너 + 60% 오버레이)과 READ_ONLY(워터마크 30% + 채도 감쇠)는 오버레이 강도와 배너 유무로 명확히 구분.

**8.1.6 Memo panel (provisional — §9 의존)**

- **접힌 상태**: 패널 숨김. 노드 선택 해제 시 패널 사라짐. 패널 존재 암시 아이콘 불필요 — Pillar 3 침묵.
- **펼친 상태**:
  - 표시 위젯: `RichTextLabel`, `theme_type_variation = &"MemoLabel"` (ADR-0004 §4 type variation 의무; `inline_theme_override_without_type_variation` forbidden_pattern 위반 금지). 폰트 Pretendard Regular 14pt `&"BodyLabel"` 계열.
  - 편집 위젯: `TextEdit`, `theme_type_variation = &"MemoEdit"`. 동일 폰트 계열.
  - 배경: 판결지 `#F5F2EC`. 경계: 0.5px **미드그레이 `#8C8C8C`** (라이트그레이 `#D9D6CF` 폐기 — WCAG 1.4.11 정합; Art Bible §3 0.5px 보조 구분선).
- **글자 수 카운터 ("500/500") (art-director B-NEW-4 BLOCKING closure 2026-05-07 cycle 2 — 인장빨강 lockdown)**: `&"CaptionLabel"` type variation (Pretendard Regular 11pt 미드그레이 `#8C8C8C`). cap 도달 시 **글꼴 무게 Medium 상승 단독 처리** (기존 인장빨강 `#C8102E` 전환 폐기 — Art Bible §4 인장빨강은 *결정적·돌이킬 수 없다·대법원 공식 행위* lockdown — 메모 cap은 *편집 중 경계 알림*으로 결정성 부재; 인장빨강 사용은 #10 Verdict Reveal 단독). 신호 채널: 위치(우측 정렬 고정) + 수치(500/500) + 글꼴 무게 (Regular → Medium). 색 단독 의존 없음 (Art Bible §4 색맹 가드 정합).

**8.1.7 Asset Spec 트리거**

후속 `/asset-spec system:reasoning-workspace` 실행 시 생성 대상:

- ~~`vfx_freeze_banner_stamp_01.png`~~ **폐기** (art-director B-NEW-3 BLOCKING closure — 인장 모티프 §8.1.4에서 제거).
- `tex_paper_aged_01.png` — DeskPane 배경 종이 텍스처 (1024×1024px BC7, 채도 5% 이하). **art-director I-2 IMPORTANT closure: Art Bible §8 do 예시의 canonical 명 사용. 기존 `tex_desk_paper_base_01.png` 명명 폐기 — 단일 명명 통일.**
- **Reject flash 색 토큰 폐기 + 점선 토큰 추가**: ~~인장빨강 5% 투명 `#C8102E0D`~~ 폐기 (인장빨강 lockdown). `evidence_duplicate_subtle_grey_tint = #8C8C8C1A` (10% 투명 미드그레이) 토큰 + `dropzone_hint_dashed_grey = #8C8C8C` (점선 1px) 토큰을 `assets/data/themes/default.tres` 등록.
- `ui_dropzone_hint_dashed.svg` — DeskPane 드롭존 1px 점선 보더 (32×32px 타일 가능 SVG 또는 StyleBox).
- Tree edge 라인 스타일 스펙시먼 — 0.5px **미드그레이 `#8C8C8C` (WCAG 1.4.11 정합 — 라이트그레이 `#D9D6CF` 폐기)** 오서거널 L-라우트 + 0.2초 드로 (수직 segment 0–0.1초 → 수평 segment 0.1–0.2초 *순차*; art-director N-2 NICE-TO-HAVE closure: Art Bible §7 "잉크가 선 위를 천천히 지나가는 느낌" 정합). godot-shader-specialist와 구현 가능성 (Line2D vs shader) 확인.

> **📌 Asset Spec** — Visual/Audio 요건이 정의됨. Art Bible 승인 후 `/asset-spec system:reasoning-workspace` 실행하여 per-asset visual descriptions·dimensions·generation prompts 생성 권장.

### 8.2 Audio Requirements

**8.2.1 Audio philosophy / tone**

Workspace는 변호사가 사고하는 *조용한 방*이다. 모든 사운드는 종이·잉크·나무라는 물리 세계에서 차용 — 게임 컨벤션의 긴장 큐 차용 금지. 오디오는 *정보전달*이지 *판단평가* 아님 — 행동이 등록됐음을 확인할 뿐, 행동의 좋고 나쁨을 평가하지 않는다. 긴장 sting·카운트다운 톤·"오답" 부저·서두름 시사 큐는 절대 도입 금지. 감정적 무게는 두 순간에만 허용 — evidence가 노드에 부착될 때 (Pillar 1 — 인용이 안착하는 무게감) + Submit 누를 때 (Pillar 3 — 결정 전 숨을 들이마시는 sonic 등가물). 그 외 모든 인터랙션은 책장을 넘기는 정도의 정적이다.

**weight-stamp / weight-stamp-deep 제작 측 measurable 제약 (audio-director #1 IMPORTANT closure)** — 위 "tension 금지" 원칙을 sound-designer 위임 시 모호함 없이 전달하기 위한 객관 spec:
- **No pitch rise**: 음높이 상승 (rising pitch contour) 금지 — *압력*은 정적 sonic 사건이지 *증가하는 긴박*이 아님.
- **No BPM-suggestive rhythm**: 리듬 패턴 또는 반복 attack 금지 — 단발 hit only.
- **Attack transient ≤ 30ms**: 빠른 attack — 긴 buildup 금지.
- **Reverb tail ≤ 200ms** (`weight-stamp`) / **≤ 600ms** (`weight-stamp-deep`): tail은 결정성 인지에 충분, urgency 부여 길이 X.
- **No harmonic content above 4kHz**: 고주파 발사음(=긴장 trigger 컨벤션) 금지. 본 spec 위반 시 sound-designer 측 deliverable 거부.

**8.2.2 Sound event catalog**

| Event | §3 Ref | Cue family | Duration | Volume layer | Tone description |
|---|---|---|---|---|---|
| Node added (root) | Rule 3 | `paper-place` | ~150 ms | UI-low | 빈 책상 위에 종이 한 장을 내려놓는 소리 — 무게감 있고 조용 |
| Node added (child) | Rule 3 | `paper-place-soft` | ~100 ms | UI-low | 루트보다 가볍게, 같은 결이되 안쪽 거리감 |
| Node selected | Rule 1 | `paper-settle` | ~80 ms | UI-low | 종이가 살짝 당겨지는 느낌 — 클릭이 아니라 집어올리는 결 |
| Node deselected | Rule 1 | *(silence)* | — | — | 다음 선택의 소리가 맡는다 |
| Label edit start (double-click) | Rule 3 | `pen-arrive` | ~60 ms | UI-low | 펜촉이 종이 위에 닿는 순간 — 짧고 건조 |
| Label edit confirm (Enter) | Rule 3 | `pen-lift` | ~80 ms | UI-low | 펜이 종이에서 떨어지는 결 — 작은 종결감 |
| Node move start (plain drag) | Rule 3 | `paper-drag` | ~120 ms | UI-low | 종이 표면을 끌어당기는 결 — 마찰감, 천천히 |
| Node move drop (success) | Rule 3 | `paper-place` | ~130 ms | UI-low | 추가와 동일 패밀리지만 약간 묵직 — 배치 결정감 |
| Node move drop (rejected — depth/cycle) | EC §5.2 | `paper-return` | ~100 ms | UI-low | 종이가 원위치로 미끄러짐 — 조용히 돌아온다 |
| Node delete confirm | Rule 3 | `paper-set-aside` | ~200 ms | UI-mid | 종이 묶음을 책상 귀퉁이로 — **Pillar 3 *cut* 앵커**: 삭제의 무게를 폭력 없이 |
| Node delete cancel | Rule 3 | *(silence)* | — | — | 다이얼로그 닫힘은 시각이 충분 |
| Memo focus | Rule 5 | `pen-arrive-soft` | ~50 ms | UI-low | 더 조용한 변형 — 필기 준비 진입 |
| Memo char-cap reached (500/500) | EC §5.5 | *(silence)* | — | — | 시각 카운터가 충분 |
| CitationDrop hover (drag over valid target) | Rule 4 | `paper-hover` | ~60 ms | UI-low | 종이가 목적지 위 정지한 느낌 — 단발성 진입 톤, barely there |
| CitationDrop accept (evidence attached) | Rule 4 | `weight-stamp` | ~180 ms | UI-mid | **Pillar 1 weight cue** — 인장 도장 직전 압력감: 짧고, 둔하고, 분명. 의사결정의 무게를 sonic으로 표현하는 유일한 큐 |
| CitationDrop reject (root / cap / duplicate) | Rule 4 | `paper-return` | ~100 ms | UI-low | depth 거부와 동일 패밀리, 약간 더 건조 — quiet, 책망 X |
| CitationDrop miss (no hit-test) | EC §5.3 | *(silence)* | — | — | 시각 ease-back 충분 |
| Submit click | Rule 7 | `weight-breath` | ~400 ms | UI-mid | 숨을 한 번 들이마시는 짧고 낮은 톤 — Pillar 3 망설임의 sonic 등가 |
| FROZEN overlay appears | Rule 7 | `hush-down` (atmosphere bus) + `weight-stamp-deep` (**UI-mid bus**) | ~250 ms | mixed | 방의 소리가 한 겹 물러나고 (`hush-down`은 atmosphere -18 dB), 인장이 찍히는 묵직한 임팩트 1회 (`weight-stamp-deep`은 UI bus 0 dB — audio-director #4 BLOCKING closure: 기존 atmosphere 분류는 "게임 전체에서 이 소리만이 분명" 의도와 모순; UI bus 배정으로 명료성 확보) — 게임 전체에서 이 소리만이 분명 |
| evaluation_completed received | Rule 7 / §3.2 | `paper-release` | ~200 ms | atmosphere | 오버레이가 걷히는 소리 — 앰비언트가 다시 살아남, 축하 X |
| submission_rejected (validation error) | EC §5.3, §5.4 | `paper-return-soft` | ~150 ms | UI-low | 조용한 정지 — 오버레이 걷힘, 꾸중·안도 모두 X |

**8.2.3 Atmosphere / ambience**

**권장: 앰비언트 베드 있음.** Pillar 3(시간 압박 0)는 무음을 요구하지 않는다 — 완전 무음은 플레이어를 경계 상태로 두어 사운드 이벤트 하나하나를 과도하게 인지하게 만든다. 앰비언트 베드는 UI 이벤트 사이의 침묵을 자연스럽게 채우고, 한국 대법원 인근 사무실의 물리적 존재감을 부여한다.

- **구성 요소**: 로우-레벨 룸 톤(공기 느낌), 먼 곳 종이 넘기는 소리 (15-30초마다 무작위), 건물 하층의 희미한 나무 바닥 발소리·엘리베이터 소리(불규칙·드물게), 창밖 먼 도심 저음(선택 — 너무 주의 끌면 제거).
- **루프 전략**: 메인 룸 톤 90-120초 루프 + 랜덤 단발 레이어(Godot `AudioStreamRandomizer`). 단일 루프 반복 피로 방지. 루프 경계 크로스페이드 2초.
- **볼륨**: UI 이벤트 대비 **-18 dB 이하, -24 dB 이상** (audio-director #3 IMPORTANT closure — floor 명시; "들릴 때가 아니라 *없어졌을 때* 느껴지는 수준"의 의도는 보존하되 `hush-down` anchor가 무의미해질 정도의 불가청 mix 차단; sound-designer는 본 범위 내 player listening level 70 dB SPL 기준 perceptible at ~46-52 dB SPL 보장).

**8.2.4 Music**

**MVP: 음악 없음.** Workspace에서 음악은 감정을 유도한다 — 이 게임은 플레이어 자신의 추론이 감정의 원천. BGM이 그 자리를 선점해서는 안 된다. 앰비언트 베드(§8.2.3)가 충분한 질감을 제공.

**단일 예외 — FROZEN**: **앰비언트 조작만 허용 — 음악 트랙 도입 절대 금지** (audio-director #5 IMPORTANT closure). FROZEN 진입 시 (a) 룸 톤 amplitude fade-out (`hush-down` envelope), (b) `weight-stamp-deep` 단발 hit 1회. 신규 tonal content (피치 element, 멜로디, 화성 패드) 도입 X — 기존 ambient 룸 톤의 *amplitude·spectral filter manipulation*으로 한정. 본 제약은 기존 "음악적 처리" 모호 표현 폐기 — sound-designer 위임 spec.

장시간 세션 BGM 도입 검토 트리거 (**OQ-W11**, audio-director #6 IMPORTANT closure — trigger criterion 명시): "v1+ playtest data에서 *median active-workspace session time ≥ 10분* AND *팀 외 playtest 응답자의 30% 이상이 voluntarily report audio fatigue* 시 audio-director가 BGM prototype 시작". 두 조건 모두 충족 전까지 OQ-W11 deferred 유지. 도입 시 무드 드리프트 없는 단선율 드론 또는 피아노 한 음만 허용.

**MVP 정의: 앰비언트 베드만, 음악 트랙 없음.**

**8.2.5 Mix / accessibility**

| 버스 | 용도 | 기본 레벨 |
|---|---|---|
| `UI` | 모든 `sfx_*` 이벤트 | 0 dB (기준) |
| `Atmosphere` | 앰비언트 베드, `hush-down`, `paper-release` | -18 dB (UI 기준) |
| `Music` | 예약 — MVP 미사용 | muted |
| `Master` | 마스터 믹스 | LUFS -14 통합 타깃 |

**플레이어 슬라이더**: `UI Sound`, `Atmosphere`, `Master Volume` 세 개. Music 슬라이더는 v1+ 도입 전까지 숨김. **Dialogue 슬라이더는 본 화면 미사용** — 향후 voice content 도입 화면이 추가되면 그 시점에 Dialogue bus 도입 (accessibility N-1 NICE-TO-HAVE closure: 본 GDD는 Workspace 화면 한정 audio architecture, *전체 게임 audio 글로벌 spec 아님*).

**접근성 (audio-director #7 IMPORTANT closure — OQ-W12 ↔ §8.2.5 모순 해소)**: 음성 대화 없음. 모든 *information-bearing* 오디오 이벤트는 시각 피드백과 1:1 중복 — 어떤 정보-전달 이벤트도 소리만으로 정보 전달 X. §8.2.2 `*(silence)*` row (Node deselected, Memo char-cap, Node delete cancel, CitationDrop miss)는 *information-bearing 분류 외* — 별도 시각 보완 불요. `weight-stamp`는 시각 보더 강화·evidence 카드 안착 애니메이션과 쌍 + bottom rule 길이 grow tween (§8.1.1.b). FROZEN 오버레이는 시각 배너가 오디오와 동시 진입. **OQ-W12 closed**: §8.2.5 absolute rule "1:1 중복 (information-bearing only)"이 정책. 추후 playtest accessibility round는 *implementation 검증* (정책 결정 X — 정책은 본 lock으로 종결).

**8.2.6 Asset Spec 트리거**

GDD 승인 후 sound-designer 위임. 각 패밀리는 단일 샘플 반복 피로 방지를 위해 3-5개 변형 요구.

| 큐 패밀리 | 변형 수 | 비고 |
|---|---|---|
| `paper-place` / `paper-place-soft` | 4 each | 핵심 노드 인터랙션 — 최다 노출 |
| `paper-settle` | 3 | 선택 피드백 |
| `pen-arrive` / `pen-arrive-soft` | 3 each | 편집 진입 |
| `pen-lift` | 3 | 편집 확정 |
| `paper-drag` | 3 | 이동 시작 |
| `paper-return` / `paper-return-soft` | 3 each | 거부/취소 |
| `paper-set-aside` | 3 | 삭제 확정 — Pillar 3 앵커, 가장 신중한 디자인 |
| `paper-hover` | 2 | CitationDrop 진입 |
| `weight-stamp` | **5** | **최우선** — Pillar 1 핵심 큐. **fire rate 65 fires/session 가능 (5 evidence × 30 nodes 상한) → 3 변형은 identifiability fatigue 확정** (audio-director #2 BLOCKING closure). 5 변형 + 즉시 반복 회피 randomizer 정책 (last-played variant 다음 fire에서 가중치 0). |
| `weight-stamp-deep` | 2 | FROZEN 임팩트 — `weight-stamp` 확장 (UI bus 0 dB — §8.2.2 mix 정합) |
| `weight-breath` | 2 | Submit 망설임 |
| `hush-down` | 1 | FROZEN 앰비언트 페이드 — 처리 기반, 변형 불요 |
| `paper-release` | 2 | evaluation_completed / 오버레이 해제 |
| 앰비언트 룸 톤 루프 | 1 (90-120s) | 크로스페이드 지점 마킹 필수 |
| 앰비언트 랜덤 단발 레이어 | 6-8개 종류 | 종이 넘김·발소리·건물 소리 풀 |

## 9. UI Requirements

> **Status**: PROVISIONAL contract — Control 노드 구체는 후속 *Workspace Layout ADR* + #2 UI Foundation epic 위임. 본 섹션은 정보 아키텍처·인터랙션 패턴·접근성 요건·screen state·핵심 인터랙션을 잠그지만 Godot Control class 선택은 잠그지 않는다.

### 9.1 Information Architecture

**DeskPane ownership.** DeskPane은 Workspace의 유일한 렌더링 surface — Browser §3.6 `WorkspaceHandoff`로부터 위임받음. DeskPane 내부에서 Workspace가 소유:

- **Tree canvas** — 가설 노드 그래프 (add / move / delete / label-edit)
- **Memo panel** — per-node 자유 메모; 위치는 **PROPOSED** (§9.3)
- **Submit affordance** — full-width submit button + character cap counter
- **Freeze overlay** — "제출이 처리 중입니다" 배너, FROZEN state 한정
- **READ_ONLY indicator** — 영구 배너, READ_ONLY state 한정

DeskPane이 **소유하지 않는 것**: LibraryPane 콘텐츠/검색, CatalogPane 상태, verdict display (Browser 통해 #10에 위임).

**Sub-zone priority (z-order, front to back):**

1. Freeze overlay / READ_ONLY indicator (최상단 — FROZEN 중 모든 인터랙션 차단)
2. Confirmation dialogs (delete, submit)
3. Memo panel (트리 캔버스 위 — 펼친 상태 오버랩 허용)
4. Tree canvas + Submit affordance (base layer)

**인접 pane과의 책임 분담:**

| 책임 | 소유자 |
|---|---|
| Citation drag source | LibraryPane / LibraryService |
| Drop target hit-test | DeskPane (Workspace) |
| Node visual + label | DeskPane |
| Memo content | DeskPane |
| Pane width / resizing | 후속 Workspace Layout ADR + Browser §6 OQ-8 |

### 9.2 Screen States

| State | Rendered | Hidden / Disabled | Modified |
|---|---|---|---|
| `INACTIVE` | 없음 — DeskPane 미마운트 | 모든 Workspace sub-zone | — |
| `ACTIVE` | Tree canvas, memo panel, submit button, progress counters | Freeze overlay, READ_ONLY indicator | 모든 편집 가능 (트리·메모·evidence) |
| `FROZEN` | Tree canvas (read-only), freeze overlay banner | Submit button (disabled), memo edit input | Evidence drop zone 비활성; 모든 인터랙티브 위젯 disable |
| `READ_ONLY` | Tree canvas (read-only), 모든 노드 메모 (display only), READ_ONLY indicator | Submit button (hidden), memo edit input, add/delete 컨트롤 | Write 경로 없음 — 아카이브 뷰 |

**Prose snapshots:**

- **INACTIVE**: DeskPane은 Browser-owned 콘텐츠(placeholder 또는 case brief) 표시. Workspace 미렌더링.
- **ACTIVE**: 트리 캔버스가 DeskPane 상단을 채우고 가설 노드 200×48px. 선택 노드는 메모 패널 표시 (위치는 §9.3). full-width submit button이 하단 anchor. Evidence count 배지가 각 노드에 visible.
- **FROZEN**: 모든 노드가 시각적으로 존재하나 non-interactive. 배너 오버레이가 트리 캔버스 위 페이드인 ("제출이 처리 중입니다") at `freeze_overlay_fade_ms` = 250ms. submit button visible but grayed. 호버 응답 없음.
- **READ_ONLY**: 트리 전체 visible, 모든 evidence·메모 콘텐츠 읽기 접근. DeskPane 상단 sticky 배너 ("제출 완료 — 열람 전용") — ACTIVE와 구별. 메모 패널 display-only (`RichTextLabel`, `TextEdit` 없음). #14 Retrospective Replay 데이터 소스.

### 9.3 Memo Panel Position — OQ-W5 Resolution Proposal

**Status: PROPOSED — UI Foundation epic에서 ratify**

세 후보:

**(A) Inline next to selected node (recommended)**
선택 노드의 우측 가장자리 또는 하단에 side-car로 펼침.
- Pros: 노드와 메모의 공간 결합이 "메모는 노드에 *속한다*"는 mental model 강화 (Gibson affordance — co-location signals ownership). Pillar 3 contemplative 톤 지원 — 트리에서 시야를 잃지 않고 읽고 편집.
- Cons: 메모 길이 시 레이아웃 압박 (500자, ~8 lines at 13pt `CommentLabel`); DeskPane 우측 가장자리 근처 노드는 truncation 또는 패널 오버플로우 필요. 동적 재배치 로직 필요.

**(B) Fixed bottom-right of DeskPane**
메모 패널이 우하단 고정 사각형 차지, 어떤 노드를 선택해도 동일 좌표.
- Pros: 예측 가능한 영역 — 레이아웃 reflow 없음; 구현 단순; 명확한 시각 위계 (트리 위, 메모 아래).
- Cons: 선택 노드와 공간 단절. 4-deep 트리 + 다중 루트 시 선택 노드가 메모 패널과 멀어 mental model 끊김. 마우스 사용자가 DeskPane 양분된 주의 필요.

**(C) Modal on demand**
메모 패널이 modal 오버레이로 열림 (DeskPane 전체 dim) — 명시 호출 (전용 키 또는 버튼) 시.
- Pros: 메모 편집 풀 포커스; 레이아웃 압박 없음.
- Cons: 메모 편집 중 트리 가시성 상실 — 형제 노드·evidence count 교차 참조 불가. Pillar 3 contemplative flow 침해 — 단일 가지 의심 시 전체 논리 동시 인식이 필요한 경험.

**Recommendation: (A), (B)는 UI Foundation 스프린트 레이아웃 복잡도가 차단할 경우 fallback.**
근거: Pillar 1 ("진실은 가중치다")는 메모 작성 중에도 evidence 밀도와 트리 구조가 보여야 한다. Pillar 3의 *판단 무게*는 단일 가지를 의심하는 동안 전체 주장을 볼 수 있을 때만 효과적. (C)는 그 동시 인식을 완전히 제거. (B)는 공간 거리로 약화. (A)는 동적 위치 계산 비용으로 보존.

**OQ-W5 open 유지.** UI Foundation epic이 4-deep tree + `max_root_count` ≥ 3에서 prototype 측정 후 (A) 또는 (B) 확정.

### 9.4 Interaction Patterns

#### 9.4.1 Pointer (KB+M primary)

| Gesture | Effect | Feedback |
|---|---|---|
| Click node | 노드 선택; 메모 패널이 해당 노드로 포커스 이동 | Selected border → 2px 잉크블랙; 메모 패널 콘텐츠 갱신 |
| Double-click empty canvas | cursor 위치에 새 루트 노드 생성 | 새 노드 cursor 위치 등장, 레이블 필드 활성 |
| Double-click node | 인라인 레이블 편집 진입 (60자 cap) | 레이블 필드 열림; cursor 텍스트 표시; 글자수 카운터 visible |
| Hover node body | Cursor `grab`(잡기) 변환 — 이동 가능성 명시 | `Control.MOUSE_CURSOR_DRAG` 적용 (Godot 4.6). **drop-shadow 도입 X** — Art Bible §3 "외부 그림자 없음" + §8.1.1 Shadow=없음 정합 (ux-designer + game-designer + art-director 2nd cycle BLOCKING closure: 기존 §9.5 "미세 drop-shadow 증가" 폐기) |
| Drag node (plain, no modifier) | 노드 이동 (재부모화 또는 루트 승격) — Rule 3 | Cursor `grabbing`, **노드 ghost 70% opacity + 좌측 상단 6×6px 잉크블랙 grip dot indicator** (ux-designer ghost discrimination IMPORTANT closure: library-source ghost는 좌측 상단 indicator 부재 — 두 drag mode를 visual differentiation); 유효 drop target 하이라이트; 무효 dim. drop discrimination by source (node-source = 이동 / library-source = evidence) |
| Drop on node (node-source) | 드래그 노드를 target의 자식으로 reparent | Ghost snap, 트리 reflow |
| Drop on empty canvas (node-source) | 루트 승격 (`parent_id = ""`) | 부모로부터 detach, 트리 reflow |
| Right-click node | Context menu: 자식 추가 / 레이블 편집 / **이동** / 삭제 | Cursor 위치 menu — 이동은 다음 클릭으로 target 지정 (KB+M discoverable + KB fallback). **이동 modal 동작 (ux-designer IMPORTANT closure)**: (a) 이동 모드 진입 시 cursor crosshair + 화면 하단 status bar "이동 위치를 클릭하세요. (Esc: 취소)" 표시; (b) 무효 target 클릭(자기 후손, depth 4 위반) 시 brief 점선 red flash + status bar "이동 불가: [reason]" + modal *유지* (재선택 허용); (c) Esc 또는 우클릭 dismiss → modal 종료 + cursor 복원 |
| Drag from LibraryPane to node | Evidence citation 첨부 (CitationDrop) | 노드 drop zone 하이라이트; 카드 ghost 70% opacity |
| Delete key (node selected) | 노드 + 서브트리 삭제 (확인 다이얼로그) | "이 가지와 하위 [N]개 노드가 함께 삭제됩니다" |
| Enter (label edit active) | 레이블 확정 | 레이블 필드 닫힘 |
| Escape (label edit active) | 레이블 편집 취소 | 이전 값으로 복귀 |

#### 9.4.2 Keyboard Alternatives (accessibility floor)

| Key | Action | Notes |
|---|---|---|
| Tab | 노드 간 포커스 traversal (breadth-first) | Focus ring은 selected와 구별 (§9.6) |
| Shift+Tab | 역방향 traversal | — |
| Arrow Up/Down | 부모 / 첫 자식으로 포커스 이동 | 트리 탐색 |
| Arrow Left/Right | 이전 / 다음 형제로 포커스 이동 | 트리 탐색 |
| Enter | 선택 노드 펼침 (자식 표시) 또는 이미 펼쳐진 경우 레이블 편집 진입 | — |
| Delete | 선택 노드 + 서브트리 삭제; 확인 다이얼로그 의무 | Pointer 경로와 동일 |
| Ctrl+Arrow Up/Down | 선택 노드 reparent (KB-only drag 등가): Ctrl+Up = 루트 승격; Ctrl+Down = 이전 형제의 자식으로 | Depth + cycle invariant 검사. KB modifier는 KB-only 경로 한정 — pointer drag와 무관 (pointer는 plain drag, §3.1 Rule 3) |
| **Ctrl+Arrow Left/Right** | **선택 노드 형제 reorder (좌 = 앞으로 / 우 = 뒤로) — ux-designer IMPORTANT closure 2026-05-07 cycle 2** | 한국 상고심에서 *상고이유 순서* (가장 강한 이유 first) 표현. 형제가 없으면 no-op + status bar "형제 노드가 없어 순서를 바꿀 수 없습니다" |
| **Space (LibraryPane card focused)** | **KB CitationDrop 시작 — 카드를 "pending citation" 상태로 마크. status bar "[library_id] 인용 대기 중. 노드 포커스 후 Space로 첨부" + 좌상단 floating 배지 표시** | **ux-designer + accessibility BLOCKING closure 2026-05-07 cycle 2 — AC-45 KB-only workflow 가능. OQ-W9 gamepad 두 단계 패턴과 mirror.** Pending 상태는 application-level — Tab으로 DeskPane 진입 가능 |
| **Space (DeskPane node focused, pending citation 활성)** | **pending library_id를 포커스 노드에 첨부 (Rule 4 정책 적용 — cap·중복·타입 검증)** | 성공 시 `weight-stamp` audio + bottom rule 길이 갱신 + pending 상태 해제. 거부 시 §5.3 정책 mirror (depth/cap hint) + pending 상태 *유지* (다른 노드 재선택 허용) |
| **Esc (pending citation 활성)** | **pending citation 취소** | 좌상단 배지 사라짐 + status bar "인용 대기 취소" |
| Ctrl+Enter | Submit (트리가 비어있으면 §5.1 mirror — 버튼 비활성과 동일 silent no-op + status bar "노드를 추가해주세요"; 비어있지 않으면 확인 다이얼로그 진입) | ux-designer NICE-TO-HAVE closure: 빈 트리 동작 명시 |
| Ctrl+S | **No-op** — 자동 저장 (§3.3 Rule 8). Ctrl+S는 효과 없음, false "saved" toast 금지 | 수동 저장 잘못 광고 X |
| F2 | 접근성 list view 토글 (flat indented text tree) | §9.6. **F2 discoverability 의무 (accessibility BLOCKING #2 closure)**: DeskPane 진입 시 status bar 일회성 toast "F2: 텍스트 목록 보기" 3초 표시 (세션 첫 진입 시만; `WorkspaceData.f2_hint_seen: bool` 영속). AccessKit 측면은 §9.6 참조 |
| Escape | 진행 중인 작업 취소 (label edit / drag / dialog / pending citation) | FROZEN 중 메인 메뉴 이탈 포함 항상 사용 가능 |

#### 9.4.3 Gamepad (critical paths required)

| Input | Action | Notes |
|---|---|---|
| D-pad / Left stick | 노드 간 포커스 traversal | Tab과 동일 breadth-first |
| A button | Confirm / 포커스 노드 선택; context에서 레이블 편집 진입 | — |
| B button | Back / cancel; context menu 닫기; 레이블 편집 취소 | — |
| X button | 포커스 노드의 context menu 열기 | add-child, delete 발견 경로 |
| Y button | 포커스 노드 레이블 편집 시작 | Context menu 우회 단축 |
| Right stick | 트리 캔버스 panning (가시 영역 초과 시) | Provisional — UI Foundation에서 ratify; §9.8 OQ-W10 |
| Left trigger + D-pad Up | 포커스 노드 루트 승격 (Ctrl+Up 등가) | Trigger combo for reparent |
| Left trigger + D-pad Down | 포커스 노드를 이전 형제의 자식으로 (Ctrl+Down 등가) | — |
| Right bumper | 다음 노드 (fast traversal) | — |
| Left bumper | 이전 노드 | — |
| Start / Menu | pause / settings | FROZEN 포함 항상 사용 가능 |

**Gamepad CitationDrop — provisional discrete 대안 (OQ-W9):**
드래그-from-Library는 가장 어려운 gamepad 인터랙션. 두 단계 대안 제안: (1) LibraryPane에서 카드 포커스 후 A 누르면 "인용 대기 중" 상태; (2) DeskPane 가설 노드 포커스 후 A 누르면 부착. 아날로그 드래그 없이 cross-pane citation workflow 보존. 정확한 버튼 할당 + 시각 핸드셰이크 (예: floating "인용 대기 중" 배지) + 취소 경로는 **provisional — UI Foundation epic ratify.**

### 9.5 Feedback Patterns

| Interaction | Visual | Audio | Reference |
|---|---|---|---|
| Node hover | 커서 → grab(잡기) 변환 (drop-shadow 도입 X — Art Bible §3 정합); 노드 visual 변화 없음 | — | §8.1.1 + §3.1 Rule 3 |
| Node selected | Border → 2px 잉크블랙; 메모 패널 갱신 | `paper-settle` (§8.2.2) | — |
| Valid drop target (CitationDrop) | Drop zone 하이라이트 active | `paper-hover` | §8.1.1 |
| Invalid drop (cap reached) | Drop zone 하이라이트 부재; "금지" 커서; post-drop hint | `paper-return` | §3.1 Rule 4 |
| Duplicate evidence drop | 250ms yellow flash on existing badge | (silent) | §5.3 |
| Invalid type drop (precedent root) | 150ms red flash; 카드 origin 복귀 | `paper-return` | §5.3 |
| Label char counter | 레이블 필드 *편집 모드* 한정 (인라인 편집 진입 시에만 표시); cap 도달 시 글꼴 무게 Medium 전환 (game-designer I-8 IMPORTANT closure: 60/60 도달이 *유일한 신호* — 표시 시점은 ellipsis truncation으로 이미 달라진 화면이므로 mid-threshold 신호 무의미) | — | §3.1 Rule 3 |
| Memo char counter | 메모 필드 아래 인라인; cap 도달 시 글꼴 무게 Medium 전환 (인장빨강 폐기 — art-director B-NEW-4 BLOCKING 정합 §8.1.6) | — | §5.5 |
| Freeze overlay | `freeze_overlay_fade_ms` 250ms 페이드인; 모든 위젯 dim | `hush-down` + `weight-stamp-deep` | §3.1 Rule 7; §7.3 |
| Error tooltip | 영향 노드 아래 인라인 hint; ~3s 자동 dismiss | — | §3.1 Rules 2–4 |
| Subtree delete | 노드 수 표시 확인 다이얼로그; 파괴적 액션 | `paper-set-aside` | §3.1 Rule 3 |

모든 오디오 큐는 §9.6 접근성 요건에 따라 visual redundancy 의무. 오디오 에셋 할당은 §8.2 위임.

### 9.6 Accessibility Requirements

Floor 요건 — 풀 audit은 OQ-W7 + accessibility-specialist 위임. **본 cycle (2026-05-07 cycle 2)에서 AccessKit role floor + KB CitationDrop + WCAG 1.4.11 contrast + F2 discoverability 잠금 (4 BLOCKING closure).**

- **색 대비 — WCAG AA + 1.4.11 non-text contrast**: 본문 텍스트 잉크블랙 `#1A1A1A` on 판결지 `#F5F2EC` ≈ 14:1 (AAA pass). **Non-text UI components (border·tree edge·icon)는 SC 1.4.11 3:1 minimum 의무** — 미드그레이 `#8C8C8C` on `#F5F2EC` ≈ 3.0:1 충족 (accessibility BLOCKING #3 closure: 기존 `#D9D6CF` 1.3:1 폐기, §8.1.1·§8.1.2·§8.1.3 모두 미드그레이로 통일). 피드백 상태(selected, error, frozen)는 색 단독 의존 X — border 두께·텍스트 레이블·spatial cue가 non-color 채널.
- **AccessKit role floor (accessibility BLOCKING #1 closure 2026-05-07 cycle 2 — OQ-W7 부분 종결)**: Tree canvas의 root Control은 `accessibility_role = AccessibilityRole.ROLE_TREE`, 각 HypothesisNode Control은 `ROLE_TREE_ITEM`. 각 노드의 `accessibility_name = node.label` (full 60자, ellipsis 미적용 — 스크린 리더는 시각적 truncation 무관), `accessibility_description = "depth %d, evidence %d개 첨부됨, 자식 %d개" % [depth, len(evidence), child_count]`. Canvas root의 `accessibility_description = "가설 트리 캔버스. F2를 눌러 텍스트 목록 보기로 전환. Space로 인용 첨부 (LibraryPane → DeskPane 두 단계)."` *— 본 floor는 정상 path (full audit 종결 X) — OQ-W7 잔여 audit은 verification 작업으로 reframe.*
- **오디오 redundancy**: §8.2.5 정합 — *information-bearing* 오디오 큐는 동시 시각 카운터파트 의무 (§8.2.2 silence row 제외).
- **키보드 단축키**: §9.4.2 모든 단축키는 Settings 통해 configurable (#4 Settings & Accessibility GDD 위임). **#4 GDD blocking gate (accessibility I-9 IMPORTANT closure)**: Workspace MVP는 #4 Settings GDD가 최소 3 API (`reduced_motion: bool`, `text_scale: float [1.0, 2.0]`, `keyboard_shortcut_remap: Dict[String, String]`) 제공 시점까지 *QA 진입 차단*. §6.4 Pending dependency에 #4 hard-gate 명시 갱신.
- **KB CitationDrop (accessibility BLOCKING #8 closure 2026-05-07 cycle 2)**: §9.4.2 Space-on-LibraryPane → Space-on-Node 두 단계 패턴 + Esc 취소 + 좌상단 floating 배지 + status bar 안내. AC-45 KB-only workflow 통과 가능.
- **스크린 리더**: AccessKit는 Godot 4.6 default. Tree canvas traversal AccessKit 검증은 위 role floor에 *기반*하여 verification — non-standard widget이지만 explicit role assignment로 표준 widget 등가 traversal 가능. RichTextLabel 메모 본문은 AccessKit 자동 노출 미보장 (Godot 4.6 알려진 한계) — `accessibility_name`을 underlying memo 문자열로 programmatically 설정 의무 (godot-specialist Item 9 IMPORTANT — ADR-0004 amendment 검토 항목).
- **Focus indicator (AC-47 lockdown)**: visible focus ring이 "selected" 상태와 구별 의무. **Spec lock**: 1px 잉크블랙 `#1A1A1A` 점선 + 외부 inset 2px (카드 외곽 border 바깥쪽 2px offset, *내부 inset 폐기* — accessibility I-5 IMPORTANT closure: selected 2px 보더 occlusion 방지). Selected = 카드 외곽 2px solid; Focused = 카드 외곽 +2px offset의 점선 ring; 두 상태 동시 공존 시 outer 점선 ring + inner solid 모두 visible.
- **Reduced motion**: 모든 drag/drop 애니메이션 + freeze overlay fade + **bottom evidence rule grow/shrink tween (§8.1.1.b — accessibility I-4 IMPORTANT closure)**은 "Reduced Motion" 설정 존중 (easing 비활성, 즉시 final 상태 snap). #4 Settings configurable.
- **텍스트 스케일링**: `&"BodyLabel"` (Pretendard 14pt) + `&"CommentLabel"` (본명조 13pt) + `&"MemoLabel"` (Pretendard 14pt) + `&"MemoEdit"` (Pretendard 14pt TextEdit variation)은 Settings text-scale 슬라이더 100%–200%로 스케일 (ADR-0004 Theme type variations). 200% scale에서 horizontal overflow 또는 text truncation 없이 레이아웃 수용.
- **F2 list view (accessibility BLOCKING #2 closure 2026-05-07 cycle 2)**: 가설 트리의 flat indented text 표현이 F2로 접근 가능. **Discoverability 의무**: (a) DeskPane 진입 시 일회성 status bar toast (§9.4.2 mirror), (b) Canvas root AccessKit `accessibility_description`에 F2 단축키 안내 포함 (위 role floor 참조), (c) `#4 Settings & Accessibility GDD` 첫 진입 가이드에서 F2 발견 경로 등재 (#4 위임 항목).
- **No flashing content**: 3–50 Hz 플래시 금지. 150ms red flash (§5.3) → ~~150ms 인장빨강 flash~~ 폐기 (인장빨강 lockdown — §8.1.1 REJECTED flash가 미드그레이 점선으로 대체); rapid-rejection 시나리오에서 반복되지 않도록 검증.

### 9.7 Layout Constraints (provisional)

- **Baseline 해상도**: 1920×1080. Baseline DeskPane width ≈ 870px (Browser §3.1: 1920 − 480 CatalogPane − 470 LibraryPane − 8 margin).
- **Floor 해상도**: 1366×768 최소 지원 윈도우 사이즈 (제안). 1366px에서 DeskPane ≈ 566px (1366 − 480 − 320 LibraryPane clamp − 0 margin). 4-deep tree + 3+ root at 566px DeskPane width는 horizontal scroll 필요 가능 — Workspace Layout ADR ratify 의무.
- **DeskPane minimum width for tree rendering**: 4-deep linear chain (4 노드 × 200px wide + spacing) horizontal 렌더링 시 ~900px 요구. Vertical 레이아웃은 ~48px × 4 + spacing ≈ 230px 高. 트리 캔버스 default는 **top-down vertical** — multi-root horizontal capacity 최대화. Horizontal extent는 root count로 결정, depth로 결정 X. Layout direction provisional — Workspace Layout ADR가 최종 결정.
- **Ultrawide (21:9)**: DeskPane 확장; 트리 캔버스 노드 사이즈 stretch X — 캔버스가 whitespace + scroll range 획득. Layout 목적 maximum DeskPane width는 Workspace Layout ADR TBD.
- **4:3 aspect ratio**: 미지원 타깃. 레거시 4:3는 <1280px viewport과 동급 — EC-8 / #2 UI Foundation v1+.
- **3-pane resizing**: 본 GDD scope X. Browser Layout ADR (Browser §6 OQ-8) 위임.

### 9.8 Open UX Questions Surfaced

| ID | Question | Status |
|---|---|---|
| OQ-W5 | Memo panel position — (A) inline vs. (B) fixed bottom-right vs. (C) modal. **Fallback (A) → (B) trigger threshold**: ux-designer IMPORTANT closure 2026-05-07 cycle 2 — DeskPane width < 720px 또는 선택 노드 우측 inline panel 영역(330px = 메모 패널 + 16px gap)이 DeskPane 우측 edge를 초과하면 (B) 자동 fallback. 본 threshold는 prototype 측정 후 ratify (UI Foundation epic). | Proposed (A) + threshold spec, ratify at UI Foundation epic |
| OQ-W7 | AccessKit verification for non-standard tree canvas widget — *role floor § 9.6에서 잠금 (2026-05-07 cycle 2)*; OQ-W7 잔여는 verification 작업 (RichTextLabel 메모 본문 AccessKit 노출 검증 + UI Foundation prototype에서 actual screen reader 출력 측정) | Floor locked, verification deferred — accessibility-specialist 위임 |
| OQ-W9 (new) | Gamepad CitationDrop 두 단계 discrete 대안 — 버튼 할당, 시각 핸드셰이크 ("인용 대기 중" 배지), 취소 경로. **KB pattern은 §9.4.2에서 잠금** — gamepad가 동일 패턴(A=mark, A=attach, B=cancel) mirror | UI Foundation epic 프로토타입 의무. **2026-05-07 cycle 2 escalation trigger (qa-lead AC-46 IMPORTANT closure)**: UI Foundation epic sign-off 시점에 OQ-W9 ratify 의무 — 미해결 시 AC-46 ADVISORY → BLOCKING 전환 |
| OQ-W10 (new) | Tree canvas panning behavior: right-stick analog pan vs. D-pad scroll vs. auto-center on focused node; 4-deep + 3+ roots at 566px DeskPane floor 시 동작 | UX validation — floor 해상도 ratify에 종속 |

## 10. Acceptance Criteria

각 기준은 Given-When-Then 형식으로 표기되며 GDD를 읽지 않은 QA tester가 독립 검증 가능해야 한다. 끝부분 태그 **(Logic / Integration / Visual / UI / Manual)**가 테스트 분류를 명시. 총 56 ACs + 2 untestable OQs.

### 10.1 chain_data Export

**AC-1 — depth root node**: GIVEN a HypothesisNode with `parent_id == ""`, WHEN `chain_data` is built at freeze time, THEN that node's exported `depth` field == 0. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_depth_root_is_zero`

**AC-2 — depth recursive computation**: GIVEN a 4-node linear chain (A root → B → C → D), WHEN chain_data is built, THEN exported `depth` values are A=0, B=1, C=2, D=3. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_depth_recursive_four_node_chain`

**AC-3 — max_depth_reached single root only**: GIVEN a workspace with one root node and no children, WHEN chain_data is built, THEN `max_depth_reached == 0`. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_max_depth_reached_root_only`

**AC-4 — max_depth_reached full tree**: GIVEN a tree reaching depth 3 (A→B→C→D), WHEN chain_data is built, THEN `max_depth_reached == 3`. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_max_depth_reached_four_level_tree`

**AC-5 — edge_count non-root nodes**: GIVEN the 4-node chain (A root, B/C/D non-root), WHEN chain_data is built, THEN `edge_count == 3`. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_edge_count_equals_non_root_count`

**AC-6 — total_evidence_count summed across nodes**: GIVEN nodes A(2 evidence), B(0), C(3), D(1), WHEN chain_data is built, THEN `total_evidence_count == 6`. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_total_evidence_count_sum`

**AC-7 — child_count immediate children only**: GIVEN node A with children [B, C] and B with children [D], WHEN chain_data is built, THEN A's `child_count == 2`, B's `child_count == 1`, D's `child_count == 0`. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_child_count_immediate_only`

**AC-8 — schema_version locked to 1**: GIVEN any non-empty workspace, WHEN chain_data is built, THEN `chain_data["schema_version"] == 1`. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_schema_version_locked_one`

**AC-9 — memo_length is UTF-8 codepoint count not byte count**: GIVEN a node memo containing 4 Korean codepoints "법리오해", WHEN chain_data is built, THEN `memo_length == 4` (codepoint count, NOT byte length). 구현은 `String.length()` 사용 의무. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_memo_length_codepoint_not_byte`

**AC-10 — memo body excluded from chain_data (Pillar 1 guard)**: GIVEN a node with memo text "test content", WHEN chain_data is built and the allow-list validator runs, THEN no `memo_text` 또는 비허용 필드가 노드 dict에 출현하지 않으며; `memo_text` 인젝션 시도는 `push_error("chain_data schema_version=1 violation: forbidden field memo_text")` + `submission_rejected("schema_violation")` 트리거. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_memo_body_absent_fuzz_schema_validator`

**AC-11 — empty workspace exports empty dict**: GIVEN a workspace with zero nodes, WHEN chain_data is requested, THEN the returned Dictionary is `{}` (ADR-0007 §1). **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_empty_workspace_exports_empty_dict`

### 10.2 Tree Structural Invariants

**AC-12 — depth bound rejection**: GIVEN a node at depth 3, WHEN player attempts to add a child (would be depth 4), THEN the add is rejected, workspace state unchanged, and "이 가지는 더 깊이 나눌 수 없습니다" hint displayed. **(Logic)** `tests/unit/workspace/tree_invariants_test.gd::test_depth_bound_add_rejected_at_four`

**AC-13 — cycle detection rejection (qa-lead IMPORTANT closure 2026-05-07 cycle 2 — Logic vs Integration 분리)**: GIVEN node A is parent of node B, WHEN `WorkspaceData.reparent(node_a_id, under=node_b_id)` is called directly on the data model, THEN the move is rejected pre-mutation, state unchanged, `push_error("Cycle detected: cannot reparent node %s under its own descendant")` logged, return value indicates rejection. UI gesture path (drag from A body → drop on B) covered by separate Integration AC `AC-13b`. **(Logic)** `tests/unit/workspace/tree_invariants_test.gd::test_cycle_detection_ancestor_under_descendant`

**AC-13b — cycle detection UI integration**: GIVEN node A is parent of node B in DeskPane, WHEN player plain drags A's body and drops on B, THEN drag controller calls `reparent()` (which rejects per AC-13), workspace UI shows ease-back animation + "노드를 자신의 하위 노드로 이동할 수 없습니다" hint. **(Integration)** `tests/integration/workspace/tree_invariants_test.gd::test_cycle_detection_ui_path`

**AC-14 — evidence cap rejection**: GIVEN a node holding 5 evidence items, WHEN a 6th CitationDrop is received, THEN the drop is rejected, evidence array unchanged (still 5), and "이 노드에는 인용을 5개까지만 첨부할 수 있습니다" hint displayed. **(Logic)** `tests/unit/workspace/tree_invariants_test.gd::test_evidence_cap_sixth_drop_rejected`

**AC-15 — parent-child symmetry on add**: GIVEN node A exists, WHEN child node B is added under A, THEN `B.parent_id == A.node_id` AND `A.children` contains B's node_id (bidirectional symmetry). **(Logic)** `tests/unit/workspace/tree_invariants_test.gd::test_parent_child_symmetry_on_add`

**AC-16 — parent-child symmetry preserved on delete**: GIVEN nodes A→B→C, WHEN B is deleted (with subtree confirmation), THEN A.children no longer contains B's node_id, and C is also removed (full subtree deletion). **(Logic)** `tests/unit/workspace/tree_invariants_test.gd::test_parent_child_symmetry_on_subtree_delete`

### 10.3 State Machine

**AC-17 — INACTIVE to ACTIVE on handoff**: GIVEN Workspace is INACTIVE, WHEN `workspace_handoff_started(case_id)` is received, THEN Workspace transitions to ACTIVE and DeskPane tree canvas becomes interactive. **(Integration)** `tests/integration/workspace/state_machine_test.gd`

**AC-18 — ACTIVE to FROZEN on Submit**: GIVEN Workspace is ACTIVE with at least one node, WHEN Submit is triggered, THEN Workspace transitions to FROZEN, chain_data is built and assigned to PlayerSubmission, and `EvaluationService.submit()` is called. **(Integration)** `tests/integration/workspace/state_machine_test.gd`

**AC-19 — FROZEN to ACTIVE on submission_rejected**: GIVEN Workspace is FROZEN, WHEN `submission_rejected(reason)` is received, THEN Workspace transitions back to ACTIVE, freeze overlay removed, tree editing re-enabled. **(Integration)** `tests/integration/workspace/state_machine_test.gd`

**AC-20 — FROZEN to READ_ONLY on evaluation_completed**: GIVEN Workspace is FROZEN, WHEN `evaluation_completed(result)` is received, THEN Workspace transitions to READ_ONLY, all write paths closed, READ_ONLY indicator visible. **(Integration)** `tests/integration/workspace/state_machine_test.gd`

**AC-21 — READ_ONLY to INACTIVE on handoff_ended submitted**: GIVEN Workspace is READ_ONLY, WHEN `workspace_handoff_ended(case_id, "submitted")` is emitted, THEN Workspace transitions to INACTIVE. **(Integration)** `tests/integration/workspace/state_machine_test.gd`

**AC-22 — ACTIVE to INACTIVE on handoff_ended paused**: GIVEN Workspace is ACTIVE, WHEN `workspace_handoff_ended(case_id, "paused")` is emitted, THEN Workspace transitions to INACTIVE while WorkspaceData is preserved. **(Integration)** `tests/integration/workspace/state_machine_test.gd`

**AC-22b — submission_rejected received during INACTIVE (qa-lead §5.4 IMPORTANT closure 2026-05-07 cycle 2)**: GIVEN Workspace is INACTIVE (player navigated away after submit), WHEN `submission_rejected(reason)` arrives, THEN signal is consumed, `WorkspaceData.last_rejection_reason = reason` 임시 보관 + `WorkspaceData.last_rejection_case_id` 기록. WHEN player re-enters that case via `workspace_handoff_started(case_id)`, THEN Workspace transitions ACTIVE + DeskPane top sticky banner "이전 제출이 거부되었습니다: [reason]" shown + reason cleared after dismissal. **(Integration)** `tests/integration/workspace/state_machine_test.gd::test_inactive_rejection_temp_storage`

**AC-23 — forbidden transition blocked with push_warning**: GIVEN Workspace is in READ_ONLY state, WHEN any direct-edit input event is processed, THEN the event is consumed (silently blocked); submit() from READ_ONLY logs `push_warning` and is rejected. **(Logic)** `tests/unit/workspace/state_machine_test.gd::test_forbidden_transition_read_only_no_edit`

### 10.4 Freeze Forward-Constraint

**AC-24 — chain_data immutable post-freeze (deep-equality verification + 신규 instance distinctness step — qa-lead IMPORTANT closure 2026-05-07 cycle 2)**: GIVEN chain_data was built and assigned at freeze, WHEN any post-freeze tree mutation is attempted, THEN mutation blocked, and `PlayerSubmission.chain_data` 내용이 freeze 스냅샷과 동일. **검증 방법 (Godot Dictionary reference type 고려)**: byte-identical 비교는 Godot Dictionary가 reference type이므로 직접 적용 불가. 대신 다음 4-step verification: (1) **Deep-equality**: `JSON.stringify(snapshot, "  ", true)` 와 `JSON.stringify(PlayerSubmission.chain_data, "  ", true)` 문자열 동등 비교 (Godot 4.6 signature: `JSON.stringify(data, indent, sort_keys, full_precision)` — 3rd arg=sort_keys=true, key 정렬 포함; nodes[] 배열 순서는 §3.1 Rule 6 canonical ordering이 보장); (2) **Reference identity option**: `snapshot == PlayerSubmission.chain_data` (Godot Dictionary `==` 연산자 — value 비교; 같은 reference면 자명 true, 별도 reference면 deep value 비교); (3) **Mutation attempt blocking**: freeze 후 `workspace_data.add_node(...)` / `node.evidence.append(...)` 호출 시 push_error + 상태 변경 없음 검증; (4) **Instance distinctness**: `PlayerSubmission.chain_data` 와 `WorkspaceData` 내부 노드 reference가 *별도 instance* 임을 검증 — 라이브 노드 mutation을 시도하고(예: `workspace_data._test_force_mutate_node(node_id)` 헬퍼) `PlayerSubmission.chain_data["nodes"][i]` 가 변경되지 않음 확인. (4)는 §3.1 Rule 6 "fully constructed new Dict" normative 위반을 catch. 4 step 모두 PASS 시 AC-24 충족. **(Logic)** `tests/unit/workspace/freeze_contract_test.gd::test_chain_data_immutable_post_freeze`

**AC-25 — memo edits during FROZEN ignored**: GIVEN Workspace is FROZEN, WHEN a TextEdit input event fires on a memo field, THEN memo content unchanged; `memo_length` in frozen snapshot unchanged. **(Logic)** `tests/unit/workspace/freeze_contract_test.gd::test_memo_edit_during_frozen_ignored`

**AC-26 — evidence drop during FROZEN ignored**: GIVEN Workspace is FROZEN, WHEN `citation_dropped(library_id, position)` is received, THEN no node's evidence array modified; drop zone highlight inactive. **(Logic)** `tests/unit/workspace/freeze_contract_test.gd::test_evidence_drop_during_frozen_ignored`

**AC-27 — crash recovery during FROZEN restores ACTIVE with banner**: GIVEN WorkspaceData was serialized FROZEN (game crash mid-evaluation), WHEN game restarts and loads, THEN Workspace auto-recovers to ACTIVE (NOT FROZEN), banner "이전 세션에서 제출이 완료되지 않았습니다. 다시 제출해주세요." shown, preserved chain_data snapshot reused on re-submit. **(Integration)** `tests/integration/workspace/freeze_recovery_test.gd`

### 10.5 CitationDrop

**AC-28 — precedent root drop rejected with hint**: GIVEN a `LibraryPrecedentEntry` (root, no `/holding-N` suffix), WHEN dropped on a hypothesis node, THEN the drop is rejected, card returns to LibraryPane, and "판시 단락(holding) 단위로 인용해주세요" hint displayed. **(Integration)** `tests/integration/workspace/citation_drop_test.gd`

**AC-29 — duplicate drop on same node triggers yellow flash**: GIVEN a node already holding `case:2019do1234/holding-1`, WHEN same ID dropped on same node again, THEN drop silently rejected, card returns instantly, existing evidence badge flashes yellow 250ms. **(Integration)** `tests/integration/workspace/citation_drop_test.gd`

**AC-30 — evidence cap reached, 6th drop rejected with hint**: GIVEN a node with exactly 5 evidence items, WHEN a 6th drop attempted, THEN drop rejected and "이 노드에는 인용을 5개까지만 첨부할 수 있습니다" hint shown (UI path mirror of AC-14). **(Integration)** `tests/integration/workspace/citation_drop_test.gd`

**AC-31 — miss drop ease-back, no state change**: GIVEN no hypothesis node under drop position (no hit-test target), WHEN `citation_dropped` fires, THEN no node's evidence array changes, card animates back to LibraryPane over 0.25s ease-out, "노드 위에 드롭해주세요" hint shown. **(Integration)** `tests/integration/workspace/citation_drop_test.gd`

**AC-32 — invalid_citation at submit triggers submission_rejected**: GIVEN a node holds a Library ID that was valid at drop but no longer in LibraryService at submit, WHEN `EvaluationService.submit()` called, THEN `submission_rejected("invalid_citation:[id]")` emitted, Workspace returns to ACTIVE from FROZEN, "존재하지 않는 인용 항목이 포함되어 있습니다" 배너. **(Integration)** `tests/integration/workspace/citation_drop_test.gd`

### 10.6 Persistence

**AC-33 — WorkspaceData survives game restart**: GIVEN a case InProgress with workspace tree (3 nodes, memos, evidence), WHEN game closed and reopened, THEN same tree structure, labels, memos, evidence arrays present in loaded WorkspaceData. **(Integration)** `tests/integration/workspace/persistence_test.gd`

**AC-34 — ACTIVE → INACTIVE → ACTIVE roundtrip preserves full state**: GIVEN Workspace ACTIVE with tree and memos, WHEN paused INACTIVE then resumed ACTIVE, THEN tree structure, memo contents, evidence arrays, labels identical to pre-pause. **(Integration)** `tests/integration/workspace/persistence_test.gd`

**AC-35 — orphan node integrity sweep on load**: GIVEN WorkspaceData contains a node with `parent_id` referencing non-existent node_id (corruption), WHEN workspace loads, THEN orphan's `parent_id` set to `""` (root promotion), missing parent's children list cleaned up, `push_warning("WorkspaceData integrity: orphan node [id] promoted to root")` logged, `workspace_state_changed` emitted. **(Integration)** `tests/integration/workspace/persistence_test.gd`

### 10.7 UI Visual / Interaction

**AC-36 — selected node border 2px ink-black**: GIVEN a node selected, WHEN rendered at 1920×1080, THEN border visually 2px and 잉크블랙 `#1A1A1A` (Art Bible §3.1), distinct from unselected 0.5px. Screenshot evidence. **(Visual)** `production/qa/evidence/workspace-node-selected-border.md`

**AC-37 — bottom evidence rule length matches evidence count**: GIVEN nodes with evidence count = {0, 1, 3, 5} (ρ = {0.0, 0.2, 0.6, 1.0}) at default `evidence_rule_thickness_px = 2.0`, WHEN rendered at 1920×1080 1:1 zoom and **node_inner_width = 184px (= 200px card − 8px×2 padding, §8.1.1.b inner padding spec)**, THEN bottom rule lengths measured at {0px (none), 36.8px ±2px, 110.4px ±2px, 184px ±2px} respectively (qa-lead + systems-designer IMPORTANT closure 2026-05-07 cycle 2: 픽셀 수치는 §8.1.1.b inner padding spec lockdown에 따라 갱신; `evidence_per_node_cap` 변경 시 본 수치 재산출 의무). Measurement protocol: screenshot capture + pixel-ruler overlay (`tools/qa/pixel-ruler.gd` 또는 동등 manual measurement); ρ=0 node 룰 부재 검증 (보더 only); ρ=1.0 룰이 노드 inner padding 좌측 8px 시작 → 우측 8px 끝 가득 채움 검증. Lead sign-off + screenshot evidence. **(Visual)** `production/qa/evidence/workspace-bottom-evidence-rule.md`

**AC-38 — freeze overlay banner 250ms fade-in with banner appear (art-director B-NEW-3 BLOCKING closure 2026-05-07 cycle 2 — 인장 모티프 폐기)**: GIVEN Workspace transitions to FROZEN, WHEN 250ms elapses, THEN **80% opacity 판결지 오버레이** fades in over 250ms; THEN ink-black banner alone (인장 stamp 부재 — Art Bible §1 원칙 4 "결정문 도착 시퀀스 이외에 나타나지 않는다" 정합) opacity(0→1) **0.15s linear fade-in** (Art Bible §7 "문서 간 전환 0.15초 페이드" 정합). 스케일 변화 X. **(Visual)** `production/qa/evidence/workspace-freeze-overlay-banner.md`

**AC-39 — READ_ONLY indicator distinct from FROZEN**: GIVEN Workspace READ_ONLY, WHEN rendered, THEN 30% 워터마크 + 15% modulate 채도 감쇠 (NOT 80% FROZEN 오버레이; 5% → 15% 갱신 — art-director I-3 IMPORTANT closure), 잉크블랙 배너 부재, "제출 완료 — 열람 전용" sticky indicator at DeskPane top. **(Visual)** `production/qa/evidence/workspace-readonly-vs-frozen.md`

**AC-40 — reduced-motion disables all easing/tween animations (accessibility I-4 IMPORTANT closure 2026-05-07 cycle 2)**: GIVEN "Reduced Motion" 설정 enabled, WHEN any of (a) node drag-drop, (b) FROZEN entry overlay fade, (c) **bottom evidence rule grow/shrink (§8.1.1.b)**, (d) tree edge draw on add/move, (e) red flash / grey-tint duplicate flash, THEN 애니메이션 즉시 final 상태 snap (no interpolation), tween 비활성. 모든 5 path 검증. **(UI)** `production/qa/evidence/workspace-reduced-motion.md`

**AC-41 — text scaling 100%–200% without horizontal overflow**: GIVEN text scale 200%, WHEN 4-level tree + memos rendered, THEN no `BodyLabel` or `MemoLabel` text truncated/overflow horizontally. **(UI)** `production/qa/evidence/workspace-text-scale-200.md`

**AC-42 — F2 list view renders all nodes in indented text**: GIVEN workspace with 5 nodes across 2 depth, WHEN F2 pressed, THEN flat indented text representation displayed, child indented relative to parent, all labels readable. **(UI)** `production/qa/evidence/workspace-f2-list-view.md`

### 10.8 Accessibility

**AC-43 — body text color contrast WCAG AA**: GIVEN default theme (잉크블랙 `#1A1A1A` on 판결지 `#F5F2EC`), WHEN automated WCAG check, THEN ratio ≥ 4.5:1 for all `BodyLabel` and `MemoLabel`. **(Logic)** `tests/unit/workspace/accessibility_test.gd::test_body_text_contrast_aa`

**AC-44 — information-bearing audio cues have visual counterpart (qa-lead IMPORTANT closure 2026-05-07 cycle 2 — silence row 명시 제외)**: GIVEN sound event catalog (§8.2.2) **filtered to non-`*(silence)*` rows = 11 information-bearing cues** (Node added × 2 + Node selected + Label edit start/confirm + Node move start/drop success/drop rejected + Node delete confirm + Memo focus + CitationDrop hover/accept/reject + Submit click + FROZEN overlay + evaluation_completed + submission_rejected; 수치 §8.2.2 row 합산 검증 의무), WHEN each event fires during manual walkthrough, THEN every information-bearing cue (weight-stamp, paper-return, FROZEN banner, etc.)는 동시 시각 피드백 (border 변화, card 애니메이션, overlay, status bar) 보유. **AT-mode validation (accessibility I-6 IMPORTANT closure)**: 별도 run with screen reader active + F2 list view enabled — list view text reflects evidence count change on CitationDrop accept (spatial canvas 대체 신호). Checklist enumerable per §8.2.2 (silence row 4건 제외). **(Manual)** `production/qa/evidence/workspace-audio-visual-parity.md`

**AC-45 — keyboard-only full workflow completion (ux-designer + accessibility BLOCKING closure 2026-05-07 cycle 2)**: GIVEN keyboard input only, WHEN player executes the complete sequence: (1) Tab to LibraryPane, focus a holding card; (2) Press Space → "pending citation" 상태 활성화 (좌상단 배지 표시); (3) Tab to DeskPane, navigate to target HypothesisNode via Arrow keys; (4) Press Space → evidence attached (`weight-stamp` 오디오 + bottom rule 길이 갱신); (5) Add new root via Tab to "+" button + Enter; (6) Edit label via F2 + type + Enter; (7) Open memo panel via selecting node (Space on focused node), focus moves to memo TextEdit, type memo; (8) Ctrl+Enter to Submit + confirm dialog. THEN 모든 8 step pointer 없이 완료, focus ring visible throughout, status bar guidance present. **(Manual)** `production/qa/evidence/workspace-keyboard-only-workflow.md`

**AC-46 — gamepad full workflow (escalation trigger 명시 — qa-lead IMPORTANT closure 2026-05-07 cycle 2)**: GIVEN gamepad only + OQ-W9 두 단계 discrete 대안 구현됨, WHEN player completes add tree → drop evidence → submit, THEN critical path 모두 KB/Mouse 없이 완료. **ADVISORY until UI Foundation epic sign-off** — UI Foundation epic sign-off 시점에 OQ-W9 ratify 의무, 미해결 시 본 AC ADVISORY → BLOCKING 자동 전환. **(Manual — Advisory with sunset)** `production/qa/evidence/workspace-gamepad-workflow.md`

**AC-47 — focus ring visually distinct from selected state (qa-lead BLOCKING closure 2026-05-07 cycle 2 — "권장" 언어 폐기, spec lockdown)**: GIVEN node keyboard-focused but not gameplay-selected (Tab 또는 Arrow key 도달 후 click 부재), WHEN rendered at 1920×1080 1:1 zoom, THEN focus ring **렌더링 명세 (LOCKED, not 권장)**: `1px 점선 잉크블랙 #1A1A1A 외부 offset 2px` (선택 2px solid 보더 *바깥쪽* 2px offset에 점선 ring — accessibility I-5 IMPORTANT closure: 기존 inset 2px는 selected solid 보더 occlusion + card text content 영역 침범). 두 상태 동시 발생 (focused + selected) 시 outer 점선 ring + inner solid 모두 visible → 두 신호 readable coexist. **측정 protocol**: focus state + selected state 동시 캡처 + 색맹 시뮬레이터(Stark, Sim Daltonism, 또는 Color Oracle 중 1) 적용 시에도 두 상태 구분 가능 검증. **Floor resolution 검증**: 1366×768에서도 1px 점선이 인지 가능 — 미달 시 thickness 1.5px 폴백 (Workspace Layout ADR amendment 트리거). Lead sign-off + screenshot 3종 (focused only / selected only / both). **(Visual)** `production/qa/evidence/workspace-focus-vs-selected.md`

### 10.9 Performance

**AC-48 — chain_data build time ≤ 16ms at MVP cap (godot-specialist Item 2 BLOCKING closure 2026-05-07 cycle 2 — 50ms → 16ms 정정 + Time API 갱신)**: GIVEN worst-case MVP (~30 nodes: depth=3 fully branched, evidence=5 per node), WHEN chain_data built and measured via gdunit4 timer, THEN elapsed ≤ **16ms** (60fps frame budget — Rule 7 single-frame atomic 정합; 기존 50ms는 ADR-0007 §3.3 full evaluation 예산 — chain_data build alone은 dict assembly로 << 1ms 예상). 측정 프로토콜: seeded fixture + **`Time.get_ticks_msec()`** start/end (godot-specialist Item 4 IMPORTANT closure: `OS.get_ticks_msec()` deprecated since Godot 4.0) + N=100 averaged. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_chain_data_build_time_worst_case`

**AC-49 — tree render with 30 nodes sustains 60fps (qa-lead IMPORTANT closure 2026-05-07 cycle 2 — stub test 의무화)**: GIVEN 30-node workspace rendered in headless gdunit4 scene, WHEN 100 consecutive frames measured, THEN no frame > 16.6ms (60fps budget). **Blocked**: Workspace Layout ADR가 Control class를 ratify하기 전까지 hard gate 불가 (OQ-QA-2 참조). **Stub test 의무**: `tests/unit/workspace/performance_test.gd::test_tree_render_30_nodes_60fps` 는 항상 존재하되 unblock 전까지는 `assert_skip("Blocked on Workspace Layout ADR — Control class TBD")`로 명시 skip — CI 차단 X, 그러나 sprint review에서 "AC-49 done" 주장 차단 (test가 skip으로 자명 표시). Workspace Layout ADR ratify 시 본 stub을 actual test로 교체. **(Logic)** `tests/unit/workspace/performance_test.gd::test_tree_render_30_nodes_60fps`

**AC-50 — memo TextEdit input lag ≤ 100ms perceived (godot-specialist Item 5 BLOCKING closure 2026-05-07 cycle 2 — phantom API 폐기)**: GIVEN node memo TextEdit focused at default `MemoEdit` Theme variation (ADR-0004), WHEN key pressed and character appears on screen, THEN delay between key-down event timestamp and frame containing the new character ≤ 100ms. Measurement protocol (선택지 — 동일 결과 보장 시 어느 쪽이든 허용): (a) **고속 카메라 측정** — 240fps phone camera로 키보드 + 화면 동시 촬영, key-press frame과 character-appears frame 사이 frame 수 × 4.16ms 환산; (b) **인스트루멘트 measurement** — `_unhandled_input(event: InputEvent)` 콜백에서 `event is InputEventKey and event.pressed` 시 `Time.get_ticks_usec()` 캡처를 t0로 기록 + 다음 `RenderingServer.frame_post_draw` 시그널 콜백에서 `Time.get_ticks_usec()` 캡처를 t1로 기록 + frame buffer 내 새 character 존재 시 `delta = (t1 − t0) / 1000.0` ms 산출, N=20 sample 평균. (기존 `Input.get_action_press_timestamp()` API는 Godot 4.6에 미존재 — 폐기). 측정 환경: target hardware (Steam Deck 또는 동등 GTX 1060+ desktop) at 1080p Forward+; vsync on; 30-node tree fully populated (worst case); 5분 워밍업 후 측정. **(Manual)** `production/qa/evidence/workspace-memo-input-lag.md`

### 10.10 Pillar Compliance Verification

**AC-51 — Pillar 1 evidence count visible without raw numbers (game-designer + qa-lead + ux-designer BLOCKING closure 2026-05-07 cycle 2 — Gate ② cascade 누락 정정)**: GIVEN node with ρ=0.6 (3/5), WHEN rendered, THEN **bottom evidence rule visible at correct length** (§4.4 + §8.1.1.b: ρ × 184px = 110.4px ±2px) WITHOUT 노드 face 위 숫자 evidence count 라벨 (density는 *bottom rule length로만* 전달, counter 아님 — Channel B per Gate ②). 기존 "border modulation" 채널은 Gate ② 결정으로 폐기 — 본 AC는 새 채널 검증. Lead sign-off + screenshot at ρ ∈ {0.0, 0.2, 0.4, 0.6, 0.8, 1.0}. **(Visual)** `production/qa/evidence/workspace-pillar1-density-no-raw-count.md`

**AC-52 — Pillar 1 guard: memo text never reaches chain_data (fuzz test)**: GIVEN schema validator on chain_data dict injected with `memo_text` field at node level, WHEN validator runs (regression simulation), THEN dict rejected + `submission_rejected("schema_violation")` emitted, NO EvaluationService call. Fuzz: 5 distinct forbidden field names, all caught. **(Logic)** `tests/unit/workspace/chain_data_test.gd::test_memo_body_absent_fuzz_schema_validator`

**AC-53 — Pillar 3: no time-pressure cues in workspace (manual audit — qa-lead IMPORTANT closure 2026-05-07 cycle 2 — boundary 명시)**: GIVEN full workspace running ACTIVE, WHEN QA tester runs 5분 세션 + 모든 audio events·visual elements 감사, THEN no countdown timer, ticking cue, urgency animation, pace-increasing signal present. **명시 inclusion (urgency cue 정의)**: countdown timer; progress bar with shrinking quantity; clock display; flashing element with persist > 250ms; BPM-escalating audio; rising pitch contour; alert color (인장빨강 단독으로 *결정* context 외 사용). **명시 exclusion (urgency 외)**: `weight-stamp` audio (180ms, no pitch rise, no rhythm — §8.2.1 measurable spec 정합); FROZEN banner fade-in 0.15s (single transition, finality not urgency); evidence rule grow 0.15s (single transition, value increment not pace). Checklist는 inclusion 8항목 모두 absent + exclusion 3항목 explicitly permitted. **(Manual)** `production/qa/evidence/workspace-pillar3-no-time-pressure.md`

**AC-54 — Pillar 3 cut anchor: delete confirmation always shown for non-empty subtree**: GIVEN `delete_confirmation_subtree_threshold == 0` (default), WHEN any node with ≥ 1 child deleted via Delete key or context menu, THEN "이 가지와 하위 [N]개 노드가 함께 삭제됩니다. 계속하시겠습니까?" 다이얼로그가 모든 상태 변경 *전* 출현, cancel 시 트리 변경 없음. **(Logic)** `tests/unit/workspace/tree_invariants_test.gd::test_delete_confirmation_always_shown_nonempty_subtree`

### 10.11 Cross-System Interaction

**AC-55 — Workspace ↔ EvaluationService: chain_data delivered correctly on submit**: GIVEN workspace with 2 노드 (depth 1, one evidence each), WHEN submit triggered, THEN PlayerSubmission received by EvaluationService has `chain_data.nodes.size() == 2`, `chain_data.edge_count == 1`, `chain_data.total_evidence_count == 2`, `chain_data.schema_version == 1`. **(Integration)** `tests/integration/workspace/citation_drop_test.gd` (fixture shared with EvaluationService stub)

**AC-56 — Workspace ↔ Library: drop from Library accepted and evidence list updated**: GIVEN valid holding-level Library ID (`case:2024da12345/holding-1`) dragged from LibraryPane and dropped on hypothesis node with < 5 evidence, WHEN drop completes, THEN `LibraryService.get_holding(id)` resolves without error, node's evidence array contains the ID, `weight-stamp` 오디오 큐 발화. **(Integration)** `tests/integration/workspace/citation_drop_test.gd`

### 10.12 Untestable AC Open Questions

- **OQ-QA-1**: AC-46 (gamepad CitationDrop workflow) is ADVISORY because OQ-W9 (두 단계 gamepad discrete 대안) is unresolved — 버튼 할당, 시각 핸드셰이크, 취소 경로 미명세. **2026-05-07 cycle 2 escalation trigger added**: UI Foundation epic sign-off 시점 OQ-W9 미해결 시 BLOCKING 자동 전환.
- **OQ-QA-2**: AC-49 (60fps with 30 nodes)는 headless Godot 4.6 scene with DeskPane Control tree 인스턴스화 필요. Tree canvas 정확한 Control class는 Workspace Layout ADR 위임 (§9 PROVISIONAL). Control class 결정 + gdunit4 headless 인스턴스화 가능 시까지 hard gate 불가. **2026-05-07 cycle 2: stub test 의무 추가** (assert_skip + 명시 reason — sprint review에서 false-claim 차단).

### 10.13 Smoke-Check Baseline (qa-lead IMPORTANT closure 2026-05-07 cycle 2)

`/smoke-check` 실행 시 다음 ACs를 baseline regression suite로 사용:

**Logic ACs (모두 PASS 의무 — BLOCKING gate)**:
- AC-1 ~ AC-11 (chain_data export 11건)
- AC-12 ~ AC-16 (tree invariants 5건)
- AC-23 (forbidden transition)
- AC-24 (chain_data immutable post-freeze 4-step)
- AC-25, AC-26 (FROZEN input 차단 2건)
- AC-43 (text contrast)
- AC-48 (chain_data build time ≤ 16ms)
- AC-52 (Pillar 1 fuzz schema validator)
- AC-54 (Pillar 3 cut anchor)

**Integration ACs (전체 PASS 의무 — BLOCKING gate)**:
- AC-17 ~ AC-22, AC-22b (state machine 7건)
- AC-27 (crash recovery)
- AC-28 ~ AC-32 (CitationDrop 5건)
- AC-33 ~ AC-35 (persistence 3건)
- AC-55, AC-56 (cross-system 2건)

**Visual / Manual / UI ACs**: 본 baseline에서 제외 (lead sign-off + manual evidence 별도 trigger). Smoke-check는 자동화 가능 ACs로 한정.

## Open Questions

본 GDD 디자인 사이클에서 surface된 미해결 질문 + 위임 항목. 각 항목은 owner와 ratify 시점이 명시된다.

### Resolved (in-session)

- **OQ-W1 ✅ resolved (2026-05-06)**: 트리 깊이 cap. **Decision**: depth = 3 (MVP). §3.1 Rule 2 + §7.1 `max_tree_depth` knob.
- **OQ-W2 ✅ resolved (2026-05-06)**: 노드당 evidence cap. **Decision**: 5 (MVP). §3.1 Rule 4 + §7.1 `evidence_per_node_cap` knob.

### Resolved (2026-05-07 cycle 2 — 22 BLOCKING + 50 IMPORTANT closure)

2nd cycle `/design-review` 결과 (8 specialist + creative-director synthesis): MAJOR REVISION NEEDED, 22 BLOCKING + ~50 IMPORTANT. 결정 근거 + 응답 cascade는 `design/gdd/reviews/reasoning-workspace-decisions-2026-05-07-cycle2.md`. 5 design decisions binding for cascade (Pillar 2 MVP 단순화 수용 / 인장빨강 #10 lockdown / AccessKit role floor lock / KB CitationDrop spec / Inner padding direct lock).

**22 BLOCKING (요약 — 상세는 cycle2 decisions 문서 참조)**:
- (cascade discipline 5건) AC-51 stale, §9.5 hover drop-shadow, REJECTED flash 인장빨강, 메모 카운터 인장빨강, 인장 32px → 모두 mechanical cascade revision 적용 (§8.1.1·§8.1.4·§8.1.6·§9.4.1·§9.5 갱신)
- (Pillar 1 silent regression 2건) submission-evaluation §3.1.2 dual-layer guard 미이행 → submission-evaluation §3.1.2에 5th check 추가 의무 (cascade revision 동시 진행), §3.1 Rule 6 single source of truth `src/data/chain_data_schema.gd` const 명시
- (formula gaps 3건) §4.3 normalized_breadth_v2 div-zero formula row inline guard 추가, 0·log2(0) convention 명시, nodes[] canonical ordering BFS 명시
- (UX/AT 4건) §9.5 hover shadow 폐기, KB CitationDrop §9.4.2 Space-mark/Space-attach 패턴, AccessKit role floor §9.6 lock, F2 discoverability status bar toast + AccessKit description
- (visual/audio 4건) freeze overlay 60→80%, 인장 32px 폐기, weight-stamp 3→5 variants + randomizer, weight-stamp-deep UI bus 0 dB
- (engine API 3건) AC-50 phantom API → InputEvent.time, AC-48 OS.get_ticks_msec → Time.get_ticks_msec, AC-48 50ms → 16ms
- (accessibility/contrast 1건) tree edge·unselected border `#D9D6CF` → `#8C8C8C` (3.0:1 WCAG 1.4.11 충족)

**Recommended escalations (creative-director synthesis 권고)**:
- 3rd review cycle mandatory — 2nd cascade가 cycle1 cascade에서 5 신규 회귀를 introduce했으므로 3rd cycle에서 회귀 부재 + IMPORTANT 잔류 항목 절대 수 감소 검증 의무.

### Resolved (2026-05-07 cycle 1 — 12 BLOCKING closure, 1st cascade)

3 design gate 결정 + cascade/mechanical revision으로 2026-05-07 design-review의 12 BLOCKING 항목 모두 closure. 결정 근거는 `design/gdd/reviews/reasoning-workspace-decisions-2026-05-07.md`.

| BLOCKING # | Source | Closure |
|---|---|---|
| 1 | game-designer + systems-designer §3.1 Rule 1 DAG vs single parent_id | Gate ① — Forest of trees 잠금 (DAG 라벨 폐기) — §3.1 Rule 1·2 + §5.2 |
| 2 | game-designer §3.1 Rule 2 depth ≤ 3 vs 4계층 | §3.1 Rule 2 — 학설/세부논거 계층은 노드 `memo` 본문에 포함 (트리 깊이 인플레이션 없음) |
| 3 | systems-designer §4.3 normalized_breadth div-zero + linear-vs-star 차별화 실패 | §4.3 normalized_breadth_v2 = `1 − leaf_count/node_count` (선형/star/balanced 구별; div-zero boundary policy) |
| 4 | systems-designer §4.3 evidence_distribution_entropy div-zero | §4.3 entropy boundary cases — node_count==1 또는 total_evidence_count==0 시 0 short-circuit |
| 5 | systems-designer + qa-lead §3.1 Rule 6 schema_version 단일 레이어 가드 hole | §3.1 Rule 6 — Builder-side allow-list + EvaluationService Pre-evaluation Gate (ADR-0007 §3.1.2) dual-layer guard |
| 6 | art-director §3.1 Rule 1 + §7.1 200×48px vs 60자 | §3.1 Rule 1 — Label 표시 정책 ellipsis truncation + hover tooltip + 편집 진입 + F2 list view에서 full label 노출 |
| 7 | art-director + systems-designer §8.1.1 evidence_density modulation subpixel + selection 압도 | Gate ② — Bottom Evidence Rule (Channel B 신규 시각 채널) — §8.1.1.b + §4.4 + §7.3 knob 교체 |
| 8 | godot-specialist §3.3 시그널 dual emitter + Browser autoload-or-scene + drag-drop API | Gate ③ B-1 — Signal contract lock + Workspace Layout ADR 위임; OQ-W13 신설; §3.3 표 정정 |
| 9 | godot-specialist §3.1 Rule 7 freeze 동기/비동기 모순 | Gate ③ B-2 — Sync transition single-frame (a→d atomic) + fire-and-forget submit + async signal callback 복귀 |
| 10 | qa-lead AC-37/47/50 측정 protocol | AC-37 (bottom rule pixel-ruler), AC-47 (focus ring 점선 spec + 색맹 시뮬레이터), AC-50 (240fps 카메라 또는 timestamp 인스트루멘트) — 각 측정 protocol 명시 |
| 11 | godot-specialist + qa-lead AC-24 byte-identical (Godot Dictionary reference type) | AC-24 — 3-step deep-equality verification (JSON.stringify sorted + `==` 연산자 + mutation block) |
| 12 | ux-designer §9.4.1 + §3.1 Rule 3 Ctrl+drag 컨벤션 + discoverable surface 0 | §3.1 Rule 3 — Plain drag from node body + cursor grab/grabbing 변환 + 우클릭 메뉴 "이동" 항목 (drop discrimination by source) |

### Deferred to other systems / phases

| OQ | Question | Owner | Target |
|---|---|---|---|
| **OQ-W3** | chain_data `memo_text` 필드 — 메모 텍스트 분석 도입 시 schema_version=2 bump 시점 검토 | systems-designer + #9 Submission & Evaluation | v1+ post-MVP |
| **OQ-W4** | `workspace_state_changed` 시그널 기반 자동저장 빈도 정책 (매 mutation? 5초 throttle? 명시 저장 버튼?) | #3 Save/Load GDD | #3 Save/Load 디자인 시점 |
| **OQ-W5** | 메모 패널 위치 — (A) inline next to selected node / (B) fixed bottom-right / (C) modal. 본 GDD §9.3에서 (A) 권고, (B) fallback. | ux-designer + UI Foundation epic | UI Foundation epic ratify (4-deep tree + 3+ root prototype 측정 후) |
| **OQ-W6** | 메모 마크다운 서식 활성화 (현재 plain text MVP) | game-designer + ux-designer | v1+ post-MVP |
| **OQ-W7** | AccessKit Godot 4.6 검증 — Tree canvas (non-standard widget) traversal. F2 list view fallback 규격 확정 필요 | accessibility-specialist + godot-specialist | UI Foundation epic + accessibility audit |
| **OQ-W8** | Browser §3.6 WorkspaceHandoff 타임아웃 가드 — Workspace `FROZEN` 중 `workspace_handoff_ended` 무시 시 Browser 측 교착 가능 (§5.7 EC) | Browser GDD #5 author | Browser Layout ADR 또는 Browser §AC 보강 |
| **OQ-W9** | Gamepad CitationDrop 두 단계 discrete 대안 — 버튼 할당, 시각 핸드셰이크 ("인용 대기 중" 배지), 취소 경로 (§9.4.3) | ux-designer + UI Foundation epic | UI Foundation epic 프로토타입 |
| **OQ-W10** | Tree canvas panning behavior — right-stick analog pan vs. D-pad scroll vs. auto-center on focused node. 4-deep + 3+ root at 566px DeskPane floor 시 동작 (§9.4.3 + §9.7) | ux-designer + Workspace Layout ADR | Floor 해상도 ratify에 종속 |
| **OQ-W11** | 장시간 세션 (≥10분) BGM 도입 검토 — 단선율 드론 또는 피아노 한 음 (§8.2.4) | audio-director + 플레이테스트 | v1+ 플레이테스트 결과 후 |
| **OQ-W12** | 주요 비음성 사운드의 시각 지시자 필요 여부 (§8.2.5 접근성) | accessibility-specialist + 플레이테스트 접근성 라운드 | 플레이테스트 접근성 라운드 |
| **OQ-W13** | CitationDrop signal topology — autoload `LibraryService` vs scene node `LibraryPane` 발신자 + Godot 4.6 native drag-drop API (`_get_drag_data`/`_can_drop_data`/`_drop_data`) vs autoload signal vs hybrid 채택. Gate ③ 결정에서 contract만 잠금, 구체 위임. | godot-specialist + Workspace Layout ADR | Workspace Layout ADR 작성 시점 (UI Foundation epic prerequisite) |

### AC-level untestable (carry-over from §10)

- **OQ-QA-1**: AC-46 (gamepad CitationDrop workflow) ADVISORY 상태 — OQ-W9 ratify 시 hard gate 전환.
- **OQ-QA-2**: AC-49 (60fps with 30 nodes) blocked — Workspace Layout ADR가 Control class 결정 + headless scene 인스턴스화 가능 시 hard gate 전환.

### Provisional contracts pending future ADRs

- **§9 UI Requirements** — `PROVISIONAL contract`. UI Foundation epic + Workspace Layout ADR 작성 후 LOCKED 전환.
- **§4.3 chain_coherence subscore** — v1+ forward declaration only. ADR-0007 amendment + submission-evaluation §4 갱신 시점에 잠금. 본 GDD는 amendment 불요 (chain_data schema 충분 — Pillar 1 가드 유지).
