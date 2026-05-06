# Submission & Evaluation — Design Review Log

> 본 파일은 `design/gdd/submission-evaluation.md`의 design review 이력을 추적합니다.
> 각 항목은 `/design-review` 실행 시 자동 추가됩니다.

---

## Review — 2026-05-06 — Verdict: NEEDS REVISION → Approved (revisions applied in-session)
Scope signal: L
Specialists: none (lean mode — single-session analysis)
Blocking items: 3 | Recommended: 5 | Nice-to-have: 4

### Summary
1차 lean review에서 BLOCKING 3건 식별 — (1) §3.1.4·§4.7·EC-5·AC-19 4지점 verdict 매핑 모순 (player_disp == correct_disp + 0.3 ≤ score < 0.5 영역 미정의 + EC-5 verdict 클레임이 함수와 불일치), (2) §4.2 core_citation_coverage 수식이 출력 범위 [0,1] 위반 가능 (player 측 순회로 holding 다중 인용 시 1.5까지 확장), (3) AC-19 verdict 집합이 §4.7 함수로 도달 불가능. 사용자 결정 후 in-session 수정으로 12 항목(BLOCKING 3 + Recommended 5 + Nice-to-have 4) 전수 적용. 핵심 결정: (a) 파기환송 임계값 0.5 → 0.3 (disp_match 시) — 처분 일치 신호 보존 + 학습 곡선 유지 우대, (b) coverage 수식을 정답 인용(c) 측 순회로 재구조화 — 자연 cap [0,1] + 표준 recall 의미론, (c) AC-19를 결정적 단언(final_score==0.37 + verdict=="파기환송")으로 재서술. 부수 정정: §7.1 임계값 표 3행→2행 통합(verdict_threshold_low 공유), AC-7/12/14 갱신, §6 #6 row에 freeze 계약 forward-constraint 명시, AC-22 측정 방법론(`Performance.get_monitor(MEMORY_STATIC)` delta) 명시, OQ-2 ADR 사전 스코프 4건 명시.

### Key Decisions
- **Verdict policy**: disp_match + 0.3 ≤ score < 0.7 → 파기환송 (관대 정책 채택). disp_match + score < 0.3 → 각하 (한국 법조계 용례와 다른 게임 의미론을 §3.1.4에 합리화 + OQ-7 변호사 자문 위임).
- **Coverage 수식 방향**: 정답 인용 c 측 순회 — `(Σ_c max(σ(p,c) for p in P)) / |C|`. 자연 cap [0,1] + 같은 case 다중 holding 인용으로 인한 외관적 과장 회피.
- **재평가 정책**: EC-8 캐시 X, 항상 재계산 — AC-23 byte-identical 보장이 캐시 불필요 + 가중치 변경 자동 반영.

### Forward Constraints Surfaced
- **#6 Reasoning Workspace** v1+ 디자인 시 §3.2 freeze 계약(submit() 시점에 workspace memo 불가변 스냅샷) 통합 의무. §6 Dependencies 표에 명시.

### ADR-XXXX (Submission Evaluation Algorithm) — 사전 스코프 (OQ-2)
1. PlayerSubmission/EvaluationResult Resource 정적 타입 트리 + 경로
2. EvaluationService autoload 등록 순서 (LibraryService → CaseService → EvaluationService 권장)
3. verdict 임계값 외부화 위치 (entities.yaml constant + per-case override 금지 룰)
4. comment_templates.tres 위치 + 형식 (단순 Dictionary vs i18n 트리, OQ-8과 연동)

Prior verdict resolved: First review (no prior).

### Re-review 권장 시점
- **Full mode**: ADR-XXXX Accepted 직후 — game-designer (Pillar 1 정합), systems-designer (수식 boundary), qa-lead (AC 테스트성), creative-director (verdict 의미론 lawyer-pre-consult) 4 specialist 적대적 검토.
- **Lawyer consult 후**: OQ-7·OQ-9 자문가 피드백 반영 시 verdict label·holding 부분 매칭 0.5 변별력 재검증.
