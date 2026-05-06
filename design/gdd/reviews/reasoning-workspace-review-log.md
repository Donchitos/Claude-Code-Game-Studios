# Reasoning Workspace — Review Log

> Tracks all `/design-review` cycles for `design/gdd/reasoning-workspace.md`. Append new entries at the top (most recent first).

---

## Resolution — 2026-05-07 cycle 2 — 22 BLOCKING + ~50 IMPORTANT closure (autonomous mode 응답 사이클)

2026-05-07 2nd `/design-review` cycle (8 specialist + creative-director synthesis: MAJOR REVISION NEEDED, 22 BLOCKING + ~50 IMPORTANT) 응답. 사용자 자율 모드 ("허락맡지말고 쭉 해줘") 하에 best-judgment defaults 적용. 다음 cycle은 *3rd `/design-review` mandatory* (creative-director Decision 2 — cycle 1 cascade가 5 신규 회귀 introduce했으므로 cycle 2의 회귀 부재 검증 의무).

### 결정 산출물

- `design/gdd/reviews/reasoning-workspace-decisions-2026-05-07-cycle2.md` — 5 design decisions (Pillar 2 MVP count-based + v1+ court-grade track / 인장빨강 #10 lockdown / AccessKit role floor lock / KB CitationDrop Space-mark·Space-attach·Esc-cancel / §8.1.1.b inner padding direct lock)

### Cascade revisions 적용 (GDD 직접 수정)

**§3.1 Rule 6 (chain_data export)**:
- Single source of truth: `src/data/chain_data_schema.gd`의 `SCHEMA_V1_ALLOWED_FIELDS` + `SCHEMA_V1_NODE_FIELDS` const + import 의무 + `chain_data_schema_allow_list_duplication` forbidden_pattern 명시 (godot-specialist Item 7)
- chain_data 빌드 normative: "fully constructed new Dict, no live references" 명시 (godot-specialist Item 8)
- nodes[] canonical ordering: BFS from sorted root id (systems-designer F3)

**§4.2 Invariants**:
- Invariant 5 신규: Evidence move atomicity (systems-designer F8)
- Invariant 6 신규: Tuning resource validation (systems-designer F7 — `evidence_hit_test_tolerance_px ≥ node_drag_threshold_px` runtime assertion)

**§4.3 chain_coherence**:
- normalized_breadth_v2 div-zero guard formula row inline 명시 (systems-designer F1)
- 0·log2(0) convention 명시 (systems-designer F2)
- 2-root forest semantic 한계 IMPORTANT 명시 (systems-designer F4 carry-over to v1+)

**§4.4 evidence_density**:
- Discretization step count = `evidence_per_node_cap` 종속 명시 (systems-designer F5)
- Pillar 2 도메인 한계 명시 — count-based MVP 수용 + v1+ ADR-0007 amendment 트랙 (game-designer Pillar 2 / Decision 1)

**§8.1.1 Node visual states 표**:
- unselected border `#D9D6CF` → `#8C8C8C` (accessibility #3 — WCAG 1.4.11 1.3:1 → 3.0:1)
- REJECTED flash 인장빨강 폐기 → 미드그레이 점선 1.5px (art-director B-NEW-1 / Decision 2)
- "yellow" → "subtle grey tint" 명명 통일 (art-director I-1)

**§8.1.1.b Bottom rule + inner padding**:
- Inner padding spec direct lock — top 6 / left·right 8 / bottom 4 또는 2 text + 2 rule (art-director B-NEW-5 / Decision 5)
- AC-37 픽셀 수치 갱신 (40/120/200px → 36.8/110.4/184px ±2px)

**§8.1.2 Tree edges**:
- 색상 라이트그레이 → 미드그레이 (accessibility #3 정합)
- L-라우트 0.2초 드로 순차 명시 (art-director N-2)

**§8.1.3 DeskPane**:
- 드롭존 힌트 점선 색 미드그레이로 통일

**§8.1.4 Freeze overlay**:
- 60% → 80% opacity (art-director B-NEW-2)
- 인장 32px 모티프 폐기 — 배너 단독 + `weight-stamp-deep` 오디오 (art-director B-NEW-3 / Decision 2)
- AC-38 갱신 — 스케일 변화 X, 단순 페이드인

**§8.1.5 READ_ONLY**:
- modulate 5% → 15% (art-director I-3)

**§8.1.6 Memo panel**:
- 글자 수 카운터 cap 도달 인장빨강 폐기 → 글꼴 무게 Medium 단독 (art-director B-NEW-4 / Decision 2)

**§8.1.7 Asset Spec triggers**:
- `vfx_freeze_banner_stamp_01.png` 폐기 (인장 모티프 부재)
- `tex_paper_aged_01.png` canonical 명 통일 (art-director I-2)
- 인장빨강 5% 투명 토큰 폐기

**§8.2 Audio**:
- `weight-stamp` 3 → 5 variants + immediate-repeat avoidance randomizer (audio-director #2)
- `weight-stamp-deep` Atmosphere bus → UI bus 0 dB (audio-director #4)
- §8.2.1 weight-stamp/weight-stamp-deep measurable 제약 5건 명시 (audio-director #1)
- §8.2.3 ambient bed -18 dB 이하·-24 dB 이상 floor 명시 (audio-director #3)
- §8.2.4 "음악적 처리" → "앰비언트 조작만 허용" 명확화 (audio-director #5)
- §8.2.4 OQ-W11 trigger criterion 명시 (audio-director #6)
- §8.2.5 OQ-W12 closed (정책 lock — playtest는 implementation 검증) (audio-director #7)
- §8.2.5 Dialogue 슬라이더 부재 rationale 명시 (accessibility N-1)

**§9.4.1 Pointer interactions**:
- Hover drop-shadow 도입 X 명시 — Art Bible §3 + §8.1.1 정합 (game-designer/ux-designer/art-director cross-concurrence BLOCKING)
- Drag ghost grip dot indicator (좌상단 6×6px 잉크블랙) — node-source vs library-source visual differentiation (ux-designer ghost discrimination)
- 우클릭 "이동" modal 동작 명시 — crosshair + status bar + Esc dismiss + 무효 target 점선 flash + modal 유지 (ux-designer)

**§9.4.2 Keyboard alternatives**:
- Ctrl+Arrow Left/Right 형제 reorder 신규 (ux-designer 한국 상고이유 순서)
- Space-on-LibraryPane / Space-on-Node KB CitationDrop 패턴 lock — AC-45 unblock (ux-designer + accessibility #8 / Decision 4)
- Esc on pending citation 취소
- Ctrl+Enter 빈 트리 동작 명시 (ux-designer NICE-TO-HAVE)
- F2 discoverability — 일회성 status bar toast 명시 (accessibility #2)

**§9.5 Feedback patterns**:
- "Node hover → 미세 drop-shadow 증가" 행 폐기 → "커서 → grab 변환, 노드 visual 변화 없음" (cross-concurrence BLOCKING)
- Label / Memo char counter 글꼴 무게 Medium 단독 처리 (art-director B-NEW-4 / Decision 2)

**§9.6 Accessibility floor**:
- AccessKit role floor 명세 lock — ROLE_TREE / ROLE_TREE_ITEM + accessibility_name + accessibility_description (accessibility #1 / Decision 3)
- WCAG 1.4.11 non-text contrast 3:1 의무 + 미드그레이 색 통일
- KB CitationDrop §9.4.2 mirror
- Focus indicator AC-47 spec lockdown — outer offset 2px 점선 (accessibility I-5)
- Reduced motion 5 path 모두 적용 (accessibility I-4)
- F2 discoverability — status bar + AccessKit description + #4 Settings GDD 위임 (accessibility #2)
- #4 Settings GDD blocking gate 명시 (accessibility I-9)
- 인장빨강 점선 red flash 행 갱신 (Decision 2 정합)

**§9.8 Open UX Questions**:
- OQ-W5 fallback trigger threshold 명시 (DeskPane width < 720px 또는 inline panel overlap)
- OQ-W7 floor locked, verification deferred (Decision 3)
- OQ-W9 escalation trigger — UI Foundation epic sign-off 시 BLOCKING 자동 전환

**§10 Acceptance Criteria**:
- AC-13 분리 — Logic AC + AC-13b Integration (qa-lead UI gesture 분리)
- AC-22b 신규 — INACTIVE submission_rejected temp-storage (qa-lead §5.4)
- AC-24 4-step verification (Instance distinctness step 추가 — qa-lead)
- AC-37 픽셀 수치 184 inner width 정정
- AC-38 인장 모티프 부재 — 단순 페이드인 (Decision 2)
- AC-39 modulate 5% → 15%
- AC-40 5 path 명시 (drag-drop / freeze fade / bottom rule tween / tree edge / red flash)
- AC-44 11 information-bearing cue + AT-mode validation (qa-lead silence row + accessibility I-6)
- AC-45 KB-only 8-step workflow 명시 (Decision 4)
- AC-46 escalation trigger 명시 (qa-lead)
- AC-47 spec lockdown — 권장 → unconditional, outer offset 2px 점선 (qa-lead + accessibility I-5)
- AC-48 50ms → 16ms + Time.get_ticks_msec (godot-specialist Item 2 + Item 4)
- AC-49 stub test 의무화
- AC-50 phantom API 폐기 + InputEvent.time / Time.get_ticks_usec (godot-specialist Item 5)
- AC-51 stale "border modulation" → "bottom evidence rule" (cross-concurrence BLOCKING)
- AC-53 urgency cue boundary 명시 (qa-lead)
- §10.13 신규 — Smoke-Check Baseline (qa-lead)

**§6.4 Dependencies**:
- #4 Settings & Accessibility GDD hard-gate 명시 (accessibility I-9)
- Workspace Layout ADR scope 축소 — §8.1.1.b inner padding 위임 폐기 (Decision 5)

**Open Questions**:
- 12 BLOCKING (cycle 1) Resolved 표 위에 22 BLOCKING (cycle 2) Resolved 표 prepend
- OQ-W11 audio trigger criterion (audio-director #6)
- OQ-W12 closed → §8.2.5 absolute rule lock (audio-director #7)

### Cross-document cascades

- `design/gdd/submission-evaluation.md` §3.1.2 — 5번째 검증 step 추가 (chain_data schema validation, single source of truth from `src/data/chain_data_schema.gd`) — Pillar 1 dual-layer guard 실제 instantiation (game-designer B-NEW-2)

### Headers / Status

- 본 GDD 헤더: "Designed — 2nd Cascade Revision Applied (2026-05-07; 22 BLOCKING + 50 IMPORTANT resolved; 3rd review cycle scheduled)"
- Decision Log cross-ref 추가 — cycle 1 + cycle 2 두 decisions 문서

### 다음 세션 권장

1. **3rd `/design-review` 사이클 mandatory** — cycle 2 cascade 회귀 부재 검증 + 잔여 IMPORTANT 절대 수 감소 측정 (creative-director Decision 2 권고)
2. **Workspace Layout ADR 작성** — Gate ③ 4 invariant + OQ-W5 fallback ratify + OQ-W9 + OQ-W10 + OQ-W13 + (§8.1.1.b inner padding은 본 GDD에서 closure)
3. **`/consistency-check`** — bottom evidence rule + 미드그레이 색 통일 + KB CitationDrop pattern + AccessKit floor 다른 GDD 정합
4. **Pillar 2 v1+ track 사용자 검토** — Decision 1 known limitation 수용 여부 final ratification (현재 best-judgment default 적용 — 사용자 reverse 시 Gate ② revisit + ADR-0007 amendment scope 진입)
5. **Art Bible amendment 2건** — §3.1 hero shape inner padding 등재 + §3 점선 dropzone 허용 1줄 등재 + §4 인장빨강 #10 lockdown 1줄 등재
6. **chain_data_schema.gd 신규 파일** — `src/data/chain_data_schema.gd`에 `SCHEMA_V1_ALLOWED_FIELDS` + `SCHEMA_V1_NODE_FIELDS` const 정의 (구현 시점에)

---

## Resolution — 2026-05-07 — 12 BLOCKING closure (응답 사이클)

2026-05-07 review (MAJOR REVISION NEEDED, 11 BLOCKING + 12번째 ux-designer Ctrl+drag = 12 BLOCKING)에 대한 응답 사이클. 다음 세션 `/design-review` 재실행 시 *prior verdict resolved*로 인식 가능.

### 결정 산출물
- `design/gdd/reviews/reasoning-workspace-decisions-2026-05-07.md` — 3 design gate 결정 (Gate ① Forest 잠금 / Gate ② Bottom Evidence Rule / Gate ③ Signal contract lock + Workspace Layout ADR 위임 + freeze 동기 transition)

### Cascade revisions 적용 (GDD 직접 수정)
- §3.1 Rule 1: DAG 라벨 폐기 → Forest of trees + Label 표시 정책 ellipsis truncation (200×48px 물리 제약)
- §3.1 Rule 2: 4계층 추론에서 학설/세부논거는 노드 memo 본문에 포함 (depth ≤ 3 유지)
- §3.1 Rule 3: Plain drag from node body (Ctrl+drag 폐기) + cursor grab 변환 + 우클릭 메뉴 "이동" 항목
- §3.1 Rule 6: chain_data dual-layer guard (Builder allow-list + EvaluationService Pre-evaluation Gate)
- §3.1 Rule 7: Freeze 동기 single-frame transition (a→d atomic) + fire-and-forget submit + async signal callback 복귀
- §3.2: Submit 전이의 sync/async 명시
- §3.3: 시그널 발신자 표 → "Library Subsystem (Workspace Layout ADR)" + 위임 검증 invariant 4건 cross-ref
- §4.3: normalized_breadth_v2 + entropy boundary policy (div-zero short-circuit)
- §4.4: evidence_density semantics → bottom rule 길이 비율 (border 두께 modulation 폐기)
- §5.1: chain_coherence boundary cross-ref
- §5.2: forest 계약 + plain drag 정정
- §6.2: Workspace Layout ADR scope 확장 (signal topology + 노드 inner padding)
- §7.2: knob `ctrl_drag_threshold_px` → `node_drag_threshold_px`
- §7.3: knob `evidence_density_modulation_strength` 폐기 → `evidence_rule_visible` + `evidence_rule_thickness_px`
- §7.6: 부등식 정합 (`evidence_hit_test_tolerance_px ≥ node_drag_threshold_px`)
- §8.1.1: 시각 채널 분리 (Channel A selection / Channel B evidence weight) + `evidence_density modulated` row 폐기
- §8.1.1.b: Bottom evidence rule 신규 subsection (Pillar 1 메인 가시화 채널)
- §8.2.2: Audio table "Ctrl+drag" → "plain drag"
- §9.4.1: Pointer interaction table 정정 (cursor grab + drop discrimination by source + 우클릭 "이동")
- §9.4.2: KB Ctrl+Arrow 명세 정합 (KB-only modifier 한정)
- AC-13: cycle detection 명세에서 plain drag 명시
- AC-24: Godot Dictionary deep-equality 3-step verification protocol (JSON.stringify sorted + `==` + mutation block)
- AC-37: bottom rule pixel-ruler 측정 protocol (40/120/200px ±2px)
- AC-38: stamp scale 1.15→1.0 → 1.2→1.0 (Art Bible §7 정합)
- AC-47: focus ring 점선 spec + 색맹 시뮬레이터 검증 protocol
- AC-50: 240fps 카메라 또는 timestamp 인스트루멘트 측정 protocol + target hardware 명시
- OQ-W13 신규: signal topology + drag-drop API choice (Workspace Layout ADR 위임)
- Resolved subsection: 12 BLOCKING resolution table 추가
- 헤더 Status: "Designed — Revisions Applied (2026-05-07)" + Decision Log cross-ref

### Registry update
- `design/registry/entities.yaml` `workspace_evidence_per_node_cap` notes 갱신 + revised 2026-05-07 (bottom evidence rule 채널 도입)

### 다음 세션 재검토 권장
1. **새 세션 `/design-review design/gdd/reasoning-workspace.md`** — prior verdict 본 entry 참조 (12 BLOCKING resolved 추적). 23 IMPORTANT + 9 Nice-to-Have는 본 사이클 미처리 — 재검토 시점에 surface.
2. **Workspace Layout ADR 작성** — Gate ③ 위임 4 invariant + OQ-W13 (signal topology) + OQ-W5/W9/W10 ratify + 노드 inner padding 명세.
3. **`/consistency-check`** — bottom evidence rule + new knobs 다른 GDD 정합 검증.

---

## Review — 2026-05-07 cycle 2 — Verdict: MAJOR REVISION NEEDED (재발생)

Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, ux-designer, art-director, audio-director, godot-specialist, accessibility-specialist, creative-director (synthesis)
Blocking items: 22 | Recommended: ~50 | Nice-to-Have: ~10
Prior verdict resolved: 12 BLOCKING (cycle 1) — 본 cycle에서 verification: 12 항목 모두 GDD에서 *텍스트 단위* 적용됐으나 cascade 누락 5건이 BLOCKING으로 재surface (AC-51 border modulation stale / §9.5 hover drop-shadow / 인장빨강 4 use case 누락 / freeze 인장 32px / 인장빨강 메모 카운터). 즉 cycle 1 12 BLOCKING은 *직접* 재발 아님이지만, cycle 1 cascade revision의 *불완전성*이 cycle 2에서 5 신규 BLOCKING 회귀로 표출.

### Summary

Cycle 1 closure 12 BLOCKING은 §3 + §4에 적용됐으나 §8 / §9 / AC tables / submission-evaluation §3.1.2 propagate 누락. 8 specialist (cycle 1의 7 + accessibility-specialist 신규 추가)가 독립적으로 도달한 결함 패턴은 *cascade 규율 실패 + 미처리 carry-over surface*. creative-director synthesis: GDD 핵심 아키텍처는 건전 — 재설계 X, cascade 규율 회복이 본 cycle 우선. 3rd review cycle mandatory.

### Top BLOCKING items (22건)

**Cascade discipline 회귀 (cycle 1 cascade 누락)**:
1. [game-designer + qa-lead + ux-designer cross-concurrence] AC-51 stale "border modulation" — Channel B(bottom rule) cascade 누락
2. [game-designer + ux-designer + Art Bible §3 verified] §9.5 hover drop-shadow vs §8.1.1 + Art Bible 모순
3. [art-director] §8.1.1 REJECTED flash 인장빨강 단독 — Art Bible §4 위반
4. [art-director] §8.1.6 메모 카운터 인장빨강 cap 알림 — Art Bible §4 시맨틱 희석
5. [art-director] §8.1.4 인장 32px — Art Bible §3 minimum violation + §1 원칙 4 충돌

**Visual / Audio 신규 모순**:
6. [art-director] §8.1.4 freeze overlay 60% opacity — "흐릿" 미달
7. [art-director] §8.1.1.b padding 미완결 (Gate ② tradeoff (a) 미이행)
8. [audio-director] weight-stamp 3 variants — 65 fires/session에서 fatigue
9. [audio-director] weight-stamp-deep Atmosphere bus(-18 dB) ↔ "게임 전체에서 이 소리만이 분명" 모순

**Formula / Schema gaps (v1+ time-bomb)**:
10. [systems-designer] normalized_breadth_v2 div-zero (node_count=0) 가드 formula row 미명시
11. [systems-designer] 0·log2(0) convention 미명시 (entropy NaN 전파)
12. [systems-designer] nodes[] array order 미정의 — AC-23/AC-24 byte-identical 위협
13. [godot-specialist + game-designer cross-concurrence] §3.1 Rule 6 dual-layer guard 단일 source 미명시 + submission-evaluation §3.1.2 미이행

**AC quality / Engine API**:
14. [godot-specialist] Rule 7 single-frame atomic ↔ AC-48 50ms 모순 (16.6ms vs 50ms)
15. [qa-lead + godot-specialist cross-concurrence] AC-50 `Input.get_action_press_timestamp()` phantom Godot 4.6 API
16. [qa-lead] AC-47 focus ring "권장" 언어 — pass/fail 판정 불가

**Accessibility (WCAG ship-blocking)**:
17. [accessibility] AccessKit role floor 미정의 — 스크린 리더 empty output
18. [accessibility] F2 list view discoverability 0 — AT 사용자 발견 불가
19. [accessibility] unselected border `#D9D6CF` on `#F5F2EC` = 1.3:1 — WCAG 1.4.11 fail
20. [accessibility + ux-designer cross-concurrence] KB CitationDrop 경로 미정의 — AC-45 unpassable

**Performance contract**:
21. [godot-specialist] AC-48 `OS.get_ticks_msec()` deprecated since Godot 4.0
22. [godot-specialist] Dictionary immutability after freeze — 명시적 normative 필요

### Cross-specialist agreements (high-confidence — 5 cross-concurrences)

- **AC-51 stale "border modulation"** (game-designer + qa-lead + ux-designer)
- **§9.5 hover drop-shadow contradiction** (game-designer + ux-designer + Art Bible verified)
- **KB CitationDrop missing → AC-45 unpassable** (ux-designer + accessibility)
- **AC-50 phantom API** (qa-lead + godot-specialist verified)
- **dual-layer guard not implemented downstream** (game-designer + godot-specialist)

### Specialist disagreements

없음. 8 specialist 모두 다른 angle에서 *cascade discipline 실패* + *미처리 carry-over surface*에 수렴.

### Recommended revision order (creative-director Decision priority)

1. **Pillar 2 Bottom Rule 사용자 결정** — count-based MVP vs court-grade upgrade (Decision 1)
2. **인장빨강 #10 lockdown** — 4 use case 폐기 (Decision 2 / cascade discipline)
3. **AccessKit floor lock + F2 discoverability** — accessibility BLOCKING #1·#2 (Decision 3)
4. **AC quality sweep** — godot-specialist 3 BLOCKING (Item 2·5·7) + qa-lead AC-47/51 (Decision 4)
5. **Cascade discipline checklist 강화** — grep token mapping + section coverage matrix (Decision 5 / 회귀 방지)

### Out-of-scope (deferred via §9 PROVISIONAL marker / OQ-W7 verification reframe)

- OQ-W9 (gamepad CitationDrop), OQ-W10 (panning), §9.7 floor-resolution은 Workspace Layout ADR 위임 — 본 verdict의 sub-blocker 카운트 X
- OQ-W7 verification은 floor lock 후 재정의 — UI Foundation epic prototype 측정으로 reframe

### Carry-over for next review (3rd cycle)

다음 /design-review 세션은 *3rd cycle*로서 본 entry를 prior verdict로 인식하고 22 BLOCKING resolved/deferred/explicitly-rejected 상태 + 50 IMPORTANT 잔류 절대 수 감소 측정 의무. 5 cross-concurrence 회귀 부재 우선 검증.

---

## Review — 2026-05-07 cycle 1 — Verdict: MAJOR REVISION NEEDED

Scope signal: L
Specialists: game-designer, systems-designer, qa-lead, ux-designer, art-director, godot-specialist, creative-director (synthesis)
Blocking items: 11 | Recommended: 23 | Nice-to-Have: 9
Prior verdict resolved: First review — no carry-over

### Summary

작성된 GDD가 빌드되면 Pillar 1("진실은 가중치다") + Pillar 4("끝나도 따라온다") 약속을 지킬 수 없다. 6 specialist가 독립적으로 도달한 결함 패턴은 명세-Pillar 정렬 부재 — polish 이슈가 아닌 정체성 이슈. 핵심 불일치 3건이 cascade 재작성을 강제한다: ① §3.1 Rule 1의 "DAG" 라벨 vs `parent_id: String` 단일 부모 스키마(Pillar 4 영속성 약속 침식), ② §4.3 v1+ chain_coherence 수식의 single-root/single-node div-zero + linear-vs-star 구별 실패, ③ §8.1.1 evidence_density 변조의 0.125px subpixel 단계가 1920×1080 인지 임계 미달(Pillar 1 시각 신호가 mid-range에서 작동 안 함). §9 PROVISIONAL marker는 적절(Workspace Layout ADR 위임 정합)하나, §9.4.1 Ctrl+drag 플랫폼 컨벤션 위반은 layout과 무관한 interaction model 결함이므로 revision 범위 포함.

### Top BLOCKING items

1. [game-designer + systems-designer] §3.1 Rule 1 "DAG" vs single `parent_id` schema — 데이터 모델 자체가 Player Fantasy "같은 판시 단락을 다른 가지에 옮겨붙이면" 약속과 불일치
2. [game-designer] §3.1 Rule 2 depth ≤ 3이 한국 상고심 4계층 추론(상고이유→쟁점→판례→학설/세부논거)을 절단 — Pillar 2/4 진정성
3. [systems-designer] §4.3 normalized_breadth div-zero (node_count=1) + linear chain ≡ star tree 차별화 실패
4. [systems-designer] §4.3 evidence_distribution_entropy 두 div-zero 경로 (total_evidence_count=0; log2(node_count=1)=0)
5. [systems-designer + qa-lead] §3.1 Rule 6 schema_version 단일 레이어 가드 hole (submission-evaluation §3.1.2 Pre-evaluation Gate 미커버)
6. [art-director] §3.1 Rule 1 + §7.1: 200×48px 카드 vs 60자 라벨 물리적 불가능
7. [art-director + systems-designer] §8.1.1 evidence_density modulation subpixel 인지 한계 + selection state가 weight signal 압도
8. [godot-specialist] §3.3 시그널 dual emitter "LibraryService / LibraryPane" + Browser autoload-or-scene 미명세 + drag-drop API 선택 미결
9. [godot-specialist] §3.1 Rule 7 freeze 타이밍 vs ADR-0007 submit() 동기/비동기 모순
10. [qa-lead] AC-37 / AC-47 / AC-50 측정 불가 (픽셀 임계값 / design TBD / measurement protocol 부재)
11. [godot-specialist + qa-lead] AC-24 byte-identical 검증 방법 미정의 (Godot Dictionary reference type)
12. [ux-designer] §9.4.1 + §3.1 Rule 3 Ctrl+drag 플랫폼 컨벤션 위반 + 이동 액션 discoverable surface 0

### Cross-specialist agreements (high-confidence)

- **DAG-vs-tree mismatch** raised by game-designer + systems-designer
- **Subpixel rendering perception failure** raised by art-director + systems-designer
- **Div-zero in v1+ formulas** raised by systems-designer + godot-specialist
- **Pillar 1 weight signal degradation** observed by art-director + game-designer
- **Pillar 4 replay discontinuity** raised by game-designer (Resolved 재플레이 트리 초기화 + #14 Alpha tier MVP-out)

### Specialist disagreements

없음. 6 specialist 모두 다른 angle에서 동일한 결함 패턴(명세-구현 정렬 부재 / 경계 case 미정의 / Pillar signal 약화)에 도달.

### Recommended revision order (dependency-based)

1. **Decision gate**: DAG vs Tree (C-1) — Pillar 4 명세가 따라옴
2. **Decision gate**: evidence_density 메커니즘 (C-3) — Pillar 1 명세가 따라옴
3. **Decision gate**: §3.3 시그널 토폴로지 (godot B-1/B-2) — §3.3 + §9.4.1 명세가 따라옴
4. 위 3개 결정 후 §4.3 경계 케이스, AC 측정 protocol, Art Bible 정합 수정은 mechanical revision
5. Workspace Layout ADR은 §9 PROVISIONAL 정리와 함께 별도 트랙으로 진행

### Out-of-scope (deferred via §9 PROVISIONAL marker)

- §9.4.3 OQ-W9 (gamepad CitationDrop), OQ-W10 (panning), §9.7 floor-resolution, §9.6 list view interaction model — Workspace Layout ADR 위임. 본 verdict의 sub-blocker로는 카운트되지 않음.

### Carry-over for next review

다음 /design-review 세션은 본 review log entry를 *prior verdict*로 인식하고 11 BLOCKING + 23 IMPORTANT 각각이 resolved/deferred/explicitly-rejected 어느 상태인지 항목별 추적 의무.
