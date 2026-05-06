# Reasoning Workspace — Design Decisions (2026-05-07 cycle 2)

> 2nd `/design-review` cycle (8 specialist + creative-director synthesis) 결과: **MAJOR REVISION NEEDED, 22 BLOCKING + ~50 IMPORTANT**.
> 본 문서는 22 BLOCKING + 핵심 IMPORTANT 응답 cascade 결정을 기록.
> 사용자 자율 모드 ("허락맡지말고 쭉 해줘") 하에 best-judgment defaults 적용 — 사용자 이의 시 다음 세션에서 reverse 가능.

---

## Decision 1 — Pillar 2 Bottom Rule: MVP Count-Based Acceptance + v1+ Court-Grade Track

**BLOCKING 대응**: game-designer Pillar 2 IMPORTANT — bottom rule "longer = more cited" 가 한국 상고심 court-grade weight를 inversion (5 inferior holdings ρ=1.0 vs 1 전합 판례 ρ=0.2).

### 결정

**MVP는 count-based bottom evidence rule 유지** (Gate ② 결정 보존). v1+에서 *weighted* 변형 ADR-0007 amendment를 통해 도입. MVP에서 본 한계는 **명시 documented limitation** — §4.4 "Pillar 2 도메인 한계" 절에서 sound-designer/qa-lead/리뷰어 모두 인지 가능하게 surface.

### Rationale

1. **Cycle 2 cascade 자체 scope 보호** — Gate ② revisit은 §4.3·§4.4·§7.1·§8.1.1.b·AC-37·entities.yaml·ADR-0007 amendment·#20 Library §3 검토 의무 — 본 cascade에서 처리하기에 과대 scope.
2. **인지 가능성 우선** — Bottom rule이 *cycle 1에서 BLOCKING #7 closure 채널*로 잠긴 직후 weighting 도입은 cascade discipline 손상 (creative-director 지적 — cascade 규율 회복이 본 cycle 우선).
3. **v1+ formula round + 자문가 검수 필요** — court_grade weight 매핑 (전합 / 부 / 하급심 / holding-level)은 한국 법조 자문가 1회 인터뷰 의무 (본 GDD §3.3 OQ-7 Verdict 라벨 의미론과 동시 자문 가능).
4. **Pillar 1 가시화 손상 X** — count-based bottom rule도 *인용을 쌓을수록 굵어진다* 직관 보존; Pillar 2 위반은 *invisible weight*로 한정 (player가 5 하급심 인용 = 1 전합 인용으로 *느끼는* 문제는 v1+ 자문가 검수 후 visual upgrade로 해소).

### Cascade impact (§4.4 + decisions log)

§4.4 evidence_density "Pillar 2 도메인 한계 명시" 절 추가 — count-based proxy + v1+ ADR-0007 amendment 트리거 + weighted 변형 forward declaration.

### v1+ Track (forward-declared)

ADR-0007 amendment 작성 시점에 다음 항목 ratify:
1. `precedent_seniority_bonus` subscore weight 활성 (현재 0.0 잠금 해제)
2. `evidence_density` weighted 변형 — `weighted_density(n) = Σ_i court_grade_weight(evidence_i) / EVIDENCE_PER_NODE_CAP_WEIGHTED`
3. court_grade_weight 매핑 — 전합: 1.5x, 부: 1.0x, 하급심: 0.5x (자문가 검수 후 잠금)
4. Bottom rule 시각 — 길이 + 두께 dual-channel 또는 색 진하기 추가 (color-blind safe 변형 art-director 검토)

---

## Decision 2 — 인장빨강 #10 Verdict Reveal Lockdown (Art Bible §4 강제)

**BLOCKING 대응**: art-director B-NEW-1, B-NEW-3, B-NEW-4 — 인장빨강 4건 violation (REJECTED flash, freeze 인장 모티프, 메모 카운터 cap 알림).

### 결정

**인장빨강 `#C8102E` 사용은 #10 Verdict Reveal Sequence 단독으로 lockdown** — Art Bible §4 시맨틱 ("결정적이다·돌이킬 수 없다·대법원의 공식 행위") 엄격 적용.

본 GDD §8.1.1·§8.1.4·§8.1.6에서 *전체 폐기*:
- §8.1.1 REJECTED flash → 미드그레이 점선 1.5px (shape cue + motion cue)
- §8.1.4 인장 모티프 (32px) → 폐기. 배너 단독 + `weight-stamp-deep` 오디오로 결정성 전달
- §8.1.6 메모 카운터 cap 알림 → 글꼴 무게 Medium 단독 처리

### Rationale

Art Bible §4 Design Test ("빨간색 요소를 지웠을 때 게임 플레이에 지장이 없는가? 지장이 있다면 빨강이 제 역할을 한 것이다") — 본 3 use case에서 빨강 제거 시 게임 진행에 지장 없음 → 빨강이 제 역할 X → 단순 *시각 노이즈*. 본 lockdown은 #10 Verdict Reveal 시점의 빨강이 *진정 결정적*임을 player에게 *희소 신호*로 보존.

### Cascade impact

- §8.1.1 REJECTED flash row 갱신 (미드그레이 점선 1.5px)
- §8.1.4 freeze overlay 인장 모티프 폐기 + AC-38 갱신 (스케일 변화 X, 단순 페이드인)
- §8.1.6 메모 카운터 글꼴 무게만 사용
- §8.1.7 Asset Spec triggers — `vfx_freeze_banner_stamp_01.png` 폐기, color tokens `#C8102E0D` 폐기

### Art Bible amendment 트리거

art-director가 Art Bible §4 색 사용 정책에 다음 1줄 추가 의무:
> "인장빨강 `#C8102E`는 #10 Verdict Reveal Sequence 단독 사용. 본 게임 어떤 다른 화면·feedback 상태에서도 인장빨강 사용 금지 — 결정성 신호의 희소성 보존."

---

## Decision 3 — AccessKit Role Floor Lock (OQ-W7 부분 종결)

**BLOCKING 대응**: accessibility BLOCKING #1 — AccessKit role 미정의로 스크린 리더 empty output.

### 결정

§9.6에 **AccessKit role floor 명세**를 *본 GDD에서 직접 lock*. OQ-W7 "AccessKit verification" 위임 scope를 *floor 정의*에서 *floor 검증 (verification)*으로 reframe — UI Foundation epic은 actual screen reader 출력 측정만 책임.

### Spec (§9.6에서 잠금)

- **Tree canvas root Control**: `accessibility_role = AccessibilityRole.ROLE_TREE`. `accessibility_description = "가설 트리 캔버스. F2를 눌러 텍스트 목록 보기로 전환. Space로 인용 첨부 (LibraryPane → DeskPane 두 단계)."`
- **각 HypothesisNode Control**: `accessibility_role = ROLE_TREE_ITEM`. `accessibility_name = node.label` (full 60자, ellipsis 미적용). `accessibility_description = "depth %d, evidence %d개 첨부됨, 자식 %d개" % [depth, len(evidence), child_count]`.
- **Memo panel RichTextLabel**: `accessibility_name`을 underlying memo 문자열로 programmatically 설정 (Godot 4.6 RichTextLabel AccessKit 자동 노출 미보장 한계 — godot-specialist Item 9 IMPORTANT 인용).

### Rationale

기존 OQ-W7 "Tree canvas traversal AccessKit 검증"은 *floor 부재* 상태에서 verification만 위임 — 결과적으로 UI Foundation epic 시작 시점에 floor를 0부터 설계해야 함. Floor를 GDD에서 잠그면 UI Foundation epic은 *spec-driven* implementation 가능 + verification은 일관된 standard 보유.

### v1+ Track

- RichTextLabel AccessKit BBCode 처리 — Godot 4.7+에서 native 지원 시 `accessibility_name` programmatic 설정 폐기 검토.

---

## Decision 4 — KB CitationDrop Pattern Lock (Space-mark / Space-attach / Esc-cancel)

**BLOCKING 대응**: ux-designer + accessibility BLOCKING — AC-45 KB-only workflow 통과 위해 cross-pane citation 키보드 경로 필수, OQ-W9 gamepad 패턴과 mirror 가능.

### 결정

§9.4.2 키보드 단축키 표에 **Space (LibraryPane focus) → "pending citation" 활성** + **Space (DeskPane node focus, pending 활성) → 첨부** + **Esc (pending 활성) → 취소** 3-step 패턴 lock.

### Spec (§9.4.2)

| Step | Key | Action |
|---|---|---|
| 1 | Tab to LibraryPane → 카드 focus | 표준 Tab traversal |
| 2 | Space | "pending citation" 상태 활성 — 좌상단 floating 배지 "[library_id] 인용 대기 중" + status bar 안내 |
| 3 | Tab to DeskPane → node focus | 표준 Tab traversal (pending 상태는 application-level — Pane 전환 무관) |
| 4 | Space | pending library_id를 포커스 노드에 첨부 (Rule 4 정책 — cap·중복·타입 검증). 성공 시 `weight-stamp` audio + bottom rule grow + pending 해제. 거부 시 §5.3 정책 mirror + pending *유지* |
| 5 (취소) | Esc | pending 취소, 배지 사라짐, status bar "인용 대기 취소" |

### Rationale

OQ-W9 gamepad 두 단계 discrete 대안과 *동일 mental model* — Space (KB) ↔ A button (gamepad), Esc (KB) ↔ B button (gamepad). 두 입력 modality 간 학습 전이 자연. AC-45 (KB-only workflow) 통과 가능 + accessibility 의무 충족.

### Cascade impact

- §9.4.2 키보드 단축키 표 3행 추가
- AC-45 wording 갱신 — 8-step KB workflow 명시
- AC-46 OQ-W9 dependency 보존 (gamepad만 ADVISORY 유지)

---

## Decision 5 — §8.1.1.b Inner Padding Direct Lock (Workspace Layout ADR 위임 폐기)

**BLOCKING 대응**: art-director B-NEW-5 — Gate ② tradeoff (a) "art-director가 §8.1.1 revision 시 padding 명시" 미이행, ADR 위임만 표시.

### 결정

§8.1.1.b에 **inner padding spec을 본 GDD에서 직접 lock** (Workspace Layout ADR 위임 폐기 + Art Bible §3.1 amendment 트리거).

### Spec (§8.1.1.b)

| 영역 | 값 |
|---|---|
| Top padding | 6px |
| Left padding | 8px |
| Right padding | 8px |
| Bottom padding | 4px (rule 부재) / 2px text + 2px rule 영역 (rule 활성) |
| Effective text box (rule 부재) | 184×38px |
| Effective text box (rule 활성) | 184×40px |
| Label 폰트 | Pretendard Regular 14pt (line-height 18px) |

Bottom rule 활성 시 좌측 8px padding 시작점에서 grow → ρ × 184px 길이.

### Rationale

Inner padding은 *visual spec*이고 *layout decision*과 분리 가능 — ADR scope (Control class·Pane resizing·signal topology)와 별개. 직접 잠그면 Workspace Layout ADR 작성을 단순화 + cycle 2 cascade에서 즉시 closure.

### AC-37 정합 갱신

기존 픽셀 수치 (40/120/200px ±2px) → (36.8/110.4/184px ±2px) — 184px = 200px − 8px×2.

### Art Bible amendment 트리거

art-director가 Art Bible §3.1 200×48 hero shape 명세에 본 padding spec 등재 의무.

---

## Cascade Discipline 강화 (creative-director Decision 2 권고)

본 cycle은 cycle 1 cascade가 §3에 적용되었으나 §8/§9/AC tables에 propagate 누락 → 5 BLOCKING 회귀 발생. 본 cycle 종결 후 *cascade discipline checklist* 적용:

1. **Decision → grep token mapping**: 각 design decision 후 영향 받는 키워드를 grep — 본 cycle 예시:
   - "border modulation" → 0 hits 검증
   - "drop-shadow" / "drop shadow" → 본 GDD 0 hits, ux-designer hover affordance 정합
   - "인장빨강" / "C8102E" → §10 Verdict Reveal 외 0 hits
   - "권장" in AC text → 0 hits (모든 AC는 unconditional)
   - "OS.get_ticks_msec" → 0 hits
   - "Input.get_action_press_timestamp" → 0 hits
2. **Section coverage matrix**: 결정 별 영향 받는 section list 명시 (예: Gate ② → §3.1 Rule 4·§4.3·§4.4·§7.3·§8.1.1·§8.1.1.b·§9.5·AC-37·AC-51).
3. **3rd review cycle scheduled** — 본 cycle 응답 cascade의 회귀 부재 검증 의무.

---

## Decision summary

| # | Decision | BLOCKING 닫힘 |
|---|---|---|
| 1 | Pillar 2 MVP count-based + v1+ court-grade track | game-designer Pillar 2 |
| 2 | 인장빨강 #10 lockdown + 4 use case 폐기 | art-director B-NEW-1·3·4 |
| 3 | AccessKit role floor lock (§9.6) | accessibility #1, #2 (F2 discoverability cross-link) |
| 4 | KB CitationDrop Space/Esc 패턴 (§9.4.2) | ux-designer + accessibility #8 (AC-45) |
| 5 | §8.1.1.b inner padding direct lock | art-director B-NEW-5 |

**남은 BLOCKING (mechanical cascade revision으로 처리, 본 문서 별도 design decision X)**:
- (cascade) AC-51 stale, §9.5 hover drop-shadow → §8.1.1·§9.4.1·§9.5 갱신
- (formula) §4.3 div-zero formula row guard, 0·log2(0) convention, nodes[] BFS canonical order → §3.1 Rule 6 + §4.3 갱신
- (engine API) AC-50 phantom API → InputEvent.time, AC-48 OS.get_ticks_msec → Time.get_ticks_msec, AC-48 50ms → 16ms → §10 갱신
- (Pillar 1 silent regression) submission-evaluation §3.1.2 5th check 추가 → submission-evaluation.md §3.1.2 갱신
- (audio mix) weight-stamp 3→5 variants, weight-stamp-deep UI bus → §8.2 갱신
- (visual) freeze 60→80%, READ_ONLY 5%→15%, 미드그레이 색 통일 → §8.1 갱신
- (atomicity) Invariant 5 evidence move atomic, Invariant 6 tuning validation → §4.2 갱신

---

## Pillar 정합 자가검수 (post-cycle 2 decisions, per `feedback_domain_authenticity` 메모리)

5 결정 모두 5 pillar + 한국 상고심 도메인 진정성 위반 점검:

- **Decision 1** (Pillar 2 MVP count): ⚠️ *known limitation* — MVP는 한국 법조 court-grade weight inversion 위험을 안고 ship; v1+ 자문가 검수에서 visual + algorithm 동시 upgrade 의무. 본 trade-off는 사용자 결정 후 escalate 가능.
- **Decision 2** (인장빨강 lockdown): ✅ Art Bible §4 정합 + Pillar 4 ("끝나도 따라온다") 결정문 시퀀스의 sonic+visual 희소 신호 보존.
- **Decision 3** (AccessKit floor): ✅ 한국 법조 도메인 외 — 일반 접근성 표준 준수, Pillar 무관.
- **Decision 4** (KB CitationDrop): ✅ 한국 법조 도메인 외 — 일반 접근성 표준 준수, Pillar 무관.
- **Decision 5** (Inner padding direct lock): ✅ Art Bible 인쇄 미학 정합 (200×48 hero shape의 "꾸밈 없고 구조만 있다" 정신 — padding이 명시될수록 인쇄 정합).

5 결정 중 4건 위반 부재; Decision 1은 MVP scope 한계를 명시 surface한 *수용된 단순화*로 분류 — 사용자 검토 권장.
