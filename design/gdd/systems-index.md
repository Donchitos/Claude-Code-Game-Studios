# Systems Index: 파기 (破棄)

> **Status**: Draft (lean review mode — director gates skipped)
> **Created**: 2026-05-03
> **Last Updated**: 2026-05-07 (cycle 2 cascade — 22 BLOCKING closure + ADR-0008 Proposed)
> **Source Concept**: design/gdd/game-concept.md
> **Art Bible**: design/art/art-bible.md

> **Revision 2026-05-04**: System #20 Legal Reference Library 추가. 케이스마다 법령·판례 텍스트가 중복 저장되는 구조를 막기 위한 전역 데이터베이스. #1 Case Data Schema의 역할이 *케이스별 콘텐츠 + Library 참조 ID*로 축소됨. #5, #6, #7, #15가 Library에 직접 의존성 추가됨. 디자인 순서 1번이 #20으로 변경.

> **Review 2026-05-04 (lean)**: #20 Legal Reference Library `/design-review` 1차 — Verdict NEEDS REVISION (5 블로커 + 12 권장). 동 세션에서 블로커 #3(Holding ID 합성 규칙)·#5(4.1↔7.3 활성 조건) 즉시 해소. **ADR-0001 (Library Storage Format)** Proposed로 작성되어 블로커 #1 해소 → 3/5 in-session resolved.
>
> **자문 전략 재편 2026-05-04**: 잔여 블로커 #2(조의2/호 스키마)는 MCP(`korean-law-mcp`) fetch + `production/research/legal-corpus/` 문서 관리로 자가 검증. 블로커 #4(AC-15 메모리 측정 프로토콜)는 *자문가 대상 아님* → godot-specialist/performance-analyst 라우팅 또는 ADVISORY 격하. 인간 자문가 회의는 VS 진입 직전 1회로 연기 (Persona 진정성 + Q4 학설 + 게임 톤 검수).
>
> **MVP Approved 트리거**: MCP 기반 자료 수집 완료 + 시드 5-10건 검증 + ADR-0001 Accepted.

---

## Overview

*파기 (破棄)* 는 한국 대법원 상고심 변호사를 시뮬레이션하는 텍스트·UI 전용 솔로 도메인 추론 게임이다. 전통적 의미의 캐릭터·환경·전투·경제 시스템은 존재하지 않으며, 게임 전체가 *판결문·법령·판례·상고이유서*라는 6종 문서 위에서 작동한다. 핵심 루프는 "케이스 인입 → 자료 검토 → 가설 구성 → 상고이유서 작성 → 결정문 도착 → 회고"이며, 시스템 분해는 이 루프를 지원하는 시각·데이터·평가·진행·메타 레이어로 구성된다.

5 Pillar 중 *진실은 가중치다* (Pillar 1)와 *사고 만이 압박이다* (Pillar 3)가 코어 시스템 디자인을 가장 강하게 제약하며, *커리어가 곧 보상이다* (Pillar 5)가 Feature 레이어의 진행 시스템들을 통합한다. 총 20개 시스템, 그중 13개가 MVP 범위에 포함되지만 다수는 매우 작은 시스템이고 실제 디자인 무게는 7개 핵심 시스템(#20 Library, #5 Browser, #6 Reasoning Workspace, #7 Brief Editor, #8 Investigation Slots, #9 Submission & Evaluation, #10 Verdict Reveal Sequence)에 집중된다.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 20 | Legal Reference Library | Core | MVP | Reviewed (Provisional — ADR-0001 trilogy + ADR-0002 + **ADR-0006** Accepted 2026-05-05; AC-17 100ms ✅ via lazy full_opinion side-car; gdunit4 193/193 PASS; lawyer consult deferred to VS gate) | design/gdd/legal-reference-library.md | — |
| 1 | Case Data Schema | Foundation | MVP | Designed (ADR-0003 Accepted 2026-05-05; first seed verified — gdunit4 20/20 case + 143/143 total) | design/gdd/case-data-schema.md | Legal Reference Library |
| 2 | UI Foundation (inferred) | Core | MVP | Not Started | — | — |
| 3 | Save/Load (inferred) | Core | MVP | Not Started | — | — |
| 4 | Settings & Accessibility (inferred) | Meta | MVP | Not Started | — | UI Foundation |
| 5 | Case File Browser | Gameplay | MVP | Designed Provisional (2026-05-05; **ADR-0004 Proposed 2026-05-06** — Korean text rendering hybrid by family closes OQ-1; AC-14·15·16 art-director sign-off pending; Browser Layout ADR pending OQ-8) | design/gdd/case-file-browser.md | Case Data Schema, UI Foundation, Legal Reference Library |
| 6 | Reasoning Workspace | Gameplay | MVP | Designed Provisional (2026-05-07 cycle 2 cascade applied — 22 BLOCKING + ~50 IMPORTANT closure via 5 design decisions + mechanical revision; **ADR-0008 Workspace Layout Proposed 2026-05-07** closes Gate ③ 4 invariant + OQ-W5/W9/W10/W13; **3rd /design-review cycle scheduled** to verify cascade discipline + IMPORTANT 잔여 감소) | [reasoning-workspace.md](reasoning-workspace.md) | Case Data Schema, UI Foundation, Case File Browser, Legal Reference Library, ADR-0001/0004/0007/0008 |
| — | Client Voice Track (cross-system) | Cross-system | MVP-gate (locked 2026-05-06 Option D 하이브리드) | OQ logged | case-data-schema OQ-7 + case-file-browser OQ-9 (+ #13 OQ-10 VS) | Case Data Schema, Case File Browser, Art Bible §6, ADR-0004 |
| 7 | Brief Editor | Gameplay | MVP | Not Started | — | Case Data Schema, UI Foundation, Case File Browser, Reasoning Workspace, Legal Reference Library |
| 8 | Investigation Slots | Gameplay | MVP | Not Started | — | Case File Browser, Reasoning Workspace |
| 9 | Submission & Evaluation | Gameplay | MVP | Designed (2026-05-05; lean review revisions applied 2026-05-06; **ADR-0007 Proposed 2026-05-06** — Submission Evaluation Algorithm closes OQ-2 4건; chain_coherence v1+ deferred) | design/gdd/submission-evaluation.md | Case Data Schema, Brief Editor, Legal Reference Library |
| 10 | Verdict Reveal Sequence | Gameplay | MVP | Not Started | — | UI Foundation, Submission & Evaluation |
| 11 | Career Progression | Progression | Alpha | Not Started | — | Case Data Schema, Save/Load, Submission & Evaluation, Reputation System |
| 12 | Reputation System | Progression | Vertical Slice | Not Started | — | Submission & Evaluation |
| 13 | Persona System | Narrative | Vertical Slice → Full Vision | Not Started | — | Case File Browser, Reasoning Workspace, Brief Editor |
| 14 | Retrospective Replay | Meta | Alpha | Not Started | — | Reasoning Workspace, Brief Editor, Submission & Evaluation |
| 15 | Source Citation | Meta | Vertical Slice | Not Started | — | Case File Browser, Reasoning Workspace, Brief Editor, Legal Reference Library |
| 16 | Tutorial & Onboarding (inferred) | Meta | MVP | Not Started | — | Case File Browser, Reasoning Workspace, Brief Editor, Investigation Slots |
| 17 | Meta-Frame (inferred) | Meta | MVP | Not Started | — | UI Foundation, Save/Load |
| 18 | Sharing System (inferred) | Meta | Alpha | Not Started | — | Career Progression, Retrospective Replay |
| 19 | Telemetry (inferred) | Meta | Full Vision | Not Started | — | (cross-cutting) |

---

## Categories

이 게임에 적용되는 카테고리만 사용 (전통적 게임의 Combat/Economy/Audio 등은 미적용 또는 매우 축소).

| Category | Description | Systems in This Game |
|----------|-------------|----------------------|
| **Core** | 모든 시스템이 의존하는 기반 — 이 게임에서는 데이터 스키마/Library와 시각 시스템 | #20, #1, #2, #3 |
| **Gameplay** | 30초·5분·세션 루프를 만드는 시스템 | #5, #6, #7, #8, #9, #10 |
| **Progression** | 시간이 흐르며 변호사가 자라는 시스템 | #11, #12 |
| **Narrative** | 인격(멘토·라이벌·대법관)의 절제된 결을 전달하는 시스템 | #13 |
| **Meta** | 코어 외부의 메타 시스템 (설정·튜토리얼·메뉴·공유·분석 등) | #4, #14, #15, #16, #17, #18, #19 |

> **N/A 카테고리** (이 게임에 없음): Combat, Economy (in-game currency), Loot, Multiplayer, AI Behavior, Procedural Generation, Voice Acting, Cutscenes (결정문 시퀀스 외).

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | 코어 루프가 작동하기 위한 필수 시스템. "차분한 정밀 추론이 재미있는가?" 가설 검증용 | 첫 플레이테스트 (2-4주) | 가장 먼저 디자인 |
| **Vertical Slice** | 1 케이스의 풀 폴리시 + Pillar 4·5의 작동 검증 | VS 데모 (6-8주) | MVP 후 즉시 |
| **Alpha** | 커리어 모드 가동, 3-5 케이스, 모든 시스템 rough | Alpha (3-4개월) | VS 후 |
| **Full Vision** | 풀 콘텐츠, 모든 시스템 polished, 출시 준비 | Beta/Release (12-24개월) | 필요 시 |

---

## Dependency Map

### Foundation Layer (의존성 0)
1. **Legal Reference Library** (#20) — 모든 케이스가 참조하는 전역 법령·판례·학설 데이터베이스. Pillar 4·5의 작동 기반.
2. **Case Data Schema** (#1) — 케이스별 콘텐츠 (사실관계·1·2심 판결문·인용 ID·정답·평가 가중치). Library 참조 ID로 법령·판례를 가리킴.
3. **UI Foundation** (#2) — Art Bible의 시각 정체성('법정 기록')을 코드로 정식화. 6개 시스템이 직접 의존하는 최대 보틀넥.
4. **Save/Load** (#3) — 60-120분 세션의 중간 저장 + 케이스북·커리어 영속화.

> 엄밀히 말하면 #1 Case Data Schema는 #20 Library에 의존하므로 Foundation 정의("의존성 0")를 깨지만, 실용적으로 두 시스템은 *함께 Foundation 역할*을 한다 — 다른 모든 시스템이 둘 다 필요로 함.

### Core Layer (Foundation에만 의존)
1. **Settings & Accessibility** (#4) — depends on: UI Foundation
2. **Case File Browser** (#5) — depends on: Case Data Schema, UI Foundation, Legal Reference Library

### Feature Layer (Core에 의존)
1. **Reasoning Workspace** (#6) — depends on: Case Data Schema, UI Foundation, Case File Browser, Legal Reference Library
2. **Brief Editor** (#7) — depends on: Case Data Schema, UI Foundation, Case File Browser, Reasoning Workspace, Legal Reference Library
3. **Investigation Slots** (#8) — depends on: Case File Browser, Reasoning Workspace
4. **Submission & Evaluation** (#9) — depends on: Case Data Schema, Brief Editor
5. **Verdict Reveal Sequence** (#10) — depends on: UI Foundation, Submission & Evaluation
6. **Reputation System** (#12) — depends on: Submission & Evaluation
7. **Career Progression** (#11) — depends on: Case Data Schema, Save/Load, Submission & Evaluation, Reputation System
8. **Persona System** (#13) — depends on: Case File Browser, Reasoning Workspace, Brief Editor
9. **Retrospective Replay** (#14) — depends on: Reasoning Workspace, Brief Editor, Submission & Evaluation

### Presentation Layer (Feature 위에 얹는 표시)
1. **Source Citation** (#15) — depends on: Case File Browser, Reasoning Workspace, Brief Editor, Legal Reference Library

### Polish Layer (메타·전체 의존)
1. **Tutorial & Onboarding** (#16) — depends on: Case File Browser, Reasoning Workspace, Brief Editor, Investigation Slots
2. **Meta-Frame** (#17) — depends on: UI Foundation, Save/Load
3. **Sharing System** (#18) — depends on: Career Progression, Retrospective Replay
4. **Telemetry** (#19) — cross-cutting (모든 시스템에 attach, 별도 의존성 없음)

---

## Recommended Design Order

| Order | # | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|---|--------|----------|-------|----------|-------------|
| 1 | 20 | **Legal Reference Library** | MVP | Foundation | game-designer + technical-director + narrative-director | M |
| 2 | 1 | Case Data Schema | MVP | Foundation | game-designer + technical-director | S |
| 3 | 2 | UI Foundation | MVP | Foundation | game-designer + ux-designer + art-director | L |
| 4 | 3 | Save/Load | MVP | Foundation | game-designer + lead-programmer | S |
| 5 | 4 | Settings & Accessibility | MVP | Core | ux-designer + accessibility-specialist | S |
| 6 | 5 | Case File Browser | MVP | Core | game-designer + ux-designer | M |
| 7 | 6 | Reasoning Workspace | MVP | Feature | game-designer + ux-designer | L |
| 8 | 7 | Brief Editor | MVP | Feature | game-designer + ux-designer | L |
| 9 | 8 | Investigation Slots | MVP | Feature | systems-designer | S |
| 10 | 9 | Submission & Evaluation | MVP | Feature | systems-designer + game-designer | L |
| 11 | 10 | Verdict Reveal Sequence | MVP | Feature | game-designer + sound-designer + technical-artist | M |
| 12 | 17 | Meta-Frame | MVP | Polish | ux-designer | S |
| 13 | 16 | Tutorial & Onboarding | MVP | Polish | game-designer + ux-designer | M |
| 14 | 12 | Reputation System | VS | Feature | systems-designer | M |
| 15 | 13 | Persona System (Mentor) | VS | Feature | narrative-director + writer | M |
| 16 | 15 | Source Citation | VS | Presentation | narrative-director + ux-designer | S |
| 17 | 11 | Career Progression | Alpha | Feature | systems-designer + game-designer | L |
| 18 | 14 | Retrospective Replay | Alpha | Feature | game-designer + ux-designer | M |
| 19 | 18 | Sharing System | Alpha | Polish | ux-designer + community-manager | S |
| 20 | 19 | Telemetry | Full Vision | Polish | analytics-engineer | M |

> **Effort 정의**: S = 1 세션 (집중 디자인 대화 1회로 GDD 완성). M = 2-3 세션. L = 4+ 세션.
> **총 예상**: ~47 세션 (S 7개 + M 8개 + L 5개). 단 MVP 범위는 ~27 세션으로 압축 가능.

### 병렬 가능 시점
- **#20 Library와 #1 Case Schema는 함께 디자인하는 게 자연스러움** — 스키마 결정이 서로 영향. 단 Library의 *데이터 모델*을 먼저 잡고, Case Schema는 그 위에서 *참조 형식* 결정.
- **Foundation 잔여 (#2 UI Foundation, #3 Save/Load)**는 Library/Case Schema와 병렬 가능.
- **MVP 폴리시 (#17 Meta-Frame, #16 Tutorial)**는 코어 디자인 후반에 병렬로 작성 가능.

---

## Circular Dependencies

**없음** ✓ — Phase 3 분석 시 그래프 사이클 검출되지 않음.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| **#20 Legal Reference Library** | Design + Content | Library 스키마는 *모든 케이스 콘텐츠*의 데이터 구조를 정함. 잘못 디자인되면 모든 케이스를 다시 작성해야 함. 또한 실제 한국 법령·판례를 어떤 단위로 저장하느냐는 자문가 협의 필요 | 변호사·법학자 자문 1회 후 데이터 모델 확정. 첫 케이스 작성과 동시에 Library 시드 데이터 5-10건으로 검증. |
| **#9 Submission & Evaluation** | Design | "추론 체인의 질" 가중 평가 알고리즘이 비자명. 단순 정답 비교는 쉽지만 *왜 그 결론에 도달했는가*를 평가하는 것은 어려움 | MVP는 단순 정답 비교만, v1+에서 추론 체인 평가 본격. 자문가 1-2인 검수 필수. 5인 플레이테스트로 균형 조정. |
| **#2 UI Foundation** | Design + Technical | 6개 시스템이 의존하는 최대 보틀넥. 표준 게임 UI 패턴이 아닌 *문서 IDE* 형 UI라 시행착오 많음 | Art Bible 강력한 anchor 제공. 첫 1주차에 페이퍼 → Godot 위젯 프로토타입으로 빠르게 검증. |
| **#6 Reasoning Workspace** | Design + UX | 가설 트리 + Library 검색 + 메모 통합 UI. 표준 게임 UI 아닌 *Disco Elysium의 Thought Cabinet* 풍 | 가설 트리 단독 프로토타입 우선 (`/prototype reasoning-tree`). MVP는 트리 깊이 2-3단계로 제한. |
| **#7 Brief Editor** | Design + UX | 텍스트 작성 IDE의 게임화. 자유 입력 vs. 구조화 선택의 균형 | MVP는 *구조화된 선택형* (상고이유 후보 + Library 카드 드래그앤드롭). 자유 텍스트는 v1+ 선택사항. |
| **#10 Verdict Reveal Sequence** | Design | MVP의 카타르시스 모먼트. 작동하지 않으면 MVP 가설 NO. 너무 화려하면 게임 톤 무너짐 | Art Bible Section 7 그대로. 첫 케이스에서만 검증, 폴리시는 VS 단계. |
| **#16 Tutorial & Onboarding** | Design | 한국 법학 모르는 플레이어가 첫 30분 포기 시 컨셉 검증 불가. 단 안티필러("드라마 없음")가 가벼운 톤 막음 | 첫 케이스 자체를 *튜토리얼-케이스 하이브리드*. 멘토 NPC의 절제된 코멘트가 가이드. 5인 테스트로 첫 30분 이탈률 측정. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 20 |
| Design docs started | 5 (#20 Library — Reviewed Provisional / #1 Case Data Schema — Designed / #5 Case File Browser — Designed Provisional / #9 Submission & Evaluation — Designed + lean review revisions 2026-05-06 / **#6 Reasoning Workspace — Designed Provisional + cycle 2 cascade applied + ADR-0008 Proposed 2026-05-07**) |
| Design docs reviewed | 2 (#20 — Reviewed Provisional, 3/5 blockers resolved + ADR-0001 Accepted; 2 deferred to lawyer review / **#6 — /design-review 2026-05-07 verdict MAJOR REVISION NEEDED**) |
| Design docs approved | 0 |
| MVP systems designed | 5 / 13 (#20 Provisional · #1 Designed · #5 Provisional · #9 Designed · **#6 NEEDS REVISION**) |
| Vertical Slice systems designed | 0 / 3 |
| Alpha systems designed | 0 / 3 |
| Full Vision systems designed | 0 / 1 |

---

## Next Steps

- [x] ✅ #20 Library — Reviewed Provisional + ADR-0001 Accepted
- [x] ✅ #1 Case Data Schema — Designed + ADR-0003 Accepted
- [x] ✅ #5 Case File Browser — Designed Provisional + ADR-0004 Proposed
- [x] ✅ #9 Submission & Evaluation — Designed + lean review revisions 2026-05-06 + ADR-0007 Proposed
- [x] ✅ #6 Reasoning Workspace — Designed 2026-05-06 (lean; pending /design-review; §9 PROVISIONAL pending Workspace Layout ADR)
- [x] ✅ /design-review #6 — 2026-05-07 — Verdict **MAJOR REVISION NEEDED** (11 BLOCKING + 23 IMPORTANT; 6 specialist + creative-director synthesis; review log: design/gdd/reviews/reasoning-workspace-review-log.md)
- [ ] **다음 권장**: 새 세션에서 #6 revision — 3 design gate 결정 우선 (① DAG vs Tree 스키마 · ② evidence_density 메커니즘 · ③ §3.3 시그널 토폴로지) 후 cascade 재작성 (§2/§3.1/§4.3/§5.1/§8.1.1)
- [ ] Foundation 잔여 (#2 UI Foundation, #3 Save/Load)는 병렬 작성 가능
- [ ] #7 Brief Editor — Reasoning Workspace chain_data 입력 계약 잠긴 후 unblocked
- [ ] ADR Verification → Acceptance: ADR-0004 (5건 verification) + ADR-0007 (3건 verification + EvaluationService 구현)
- [ ] 후속 ADR — ADR-0005 (External Research Tool Stack 30분 retrofit), Workspace Layout ADR (OQ-W5/W9/W10 ratify), Browser Layout ADR (Browser §6 OQ-8)
- [ ] MVP 시스템 GDD 완료 시마다 `/design-review design/gdd/[system].md`
- [ ] MVP 13개 GDD 완료 후 `/review-all-gdds`로 일관성 검증
- [ ] 그 후 `/create-architecture`로 마스터 아키텍처 문서 작성
- [ ] `/gate-check pre-production`으로 프로덕션 진입 게이트 통과

### Cross-system MVP-gate Tracks (NEW 2026-05-06)

- **Client Voice 트랙 (Option D 하이브리드 — locked 2026-05-06)**: 의뢰인 *목소리*를 Brief 봉투 안에 *글로만* 통합 (대화 X, 신규 시스템 X — paper-based authenticity 유지하면서 Pillar 4·5 충돌 해소). 액션:
  - case-data-schema **OQ-7** — `client_letter` / `family_statement` / `lower_court_lawyer_memo` optional 필드 (≤2000/2000/1000 char) 정식 §3.1 Core Rules 진입
  - case-file-browser **OQ-9** — BriefOpen 단계 *Voice 패널* 또는 *서신 첨부* 영역 신설; Theme type variation `&"LetterLabel"` / `&"StatementLabel"` / `&"MemoLabel"` 변형 (Art Bible §6 + ADR-0004 갱신 필요)
  - **Target**: 첫 시드 케이스 fixture 작성 직전 (MVP 진입 게이트 통과 전)
  - **VS 확장 트래커**: #13 Persona System에 *반복 의뢰인* 카테고리 추가 (case-file-browser **OQ-10**) — Pillar 4 *끝나도 따라온다* 핵심 구현. #13 GDD 작성 시 정의.
