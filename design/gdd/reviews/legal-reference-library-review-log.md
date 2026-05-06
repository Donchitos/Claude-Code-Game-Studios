# Review Log: Legal Reference Library

> **System**: #20 Legal Reference Library
> **Doc**: design/gdd/legal-reference-library.md
> **Status Source**: design/gdd/systems-index.md

리뷰 이력 (최신이 위). 각 엔트리는 그 시점의 verdict, blockers, 해소 여부를 기록.

---

## Review — 2026-05-04 — Verdict: NEEDS REVISION (in-session: 2/5 resolved)
Mode: lean (single-session, no specialist agents)
Scope signal: L (Foundation, multi-system 의존, 새 ADR 1+ 필요)
Specialists: 없음 (lean) — `--depth full` 재실행 시 game-designer + systems-designer + qa-lead + narrative-director + performance-analyst + godot-specialist + creative-director 가능
Blocking items: 5 → 2 in-session 해소, 3 자문 입력 자료로 보존
Recommended items: 12
Nice-to-have: 3
Prior verdict resolved: First review

### Blockers

| # | 항목 | 상태 |
|---|------|------|
| 1 | 저장 형식 명세 vs 스키마 예시 모순 (3.1.3 "Markdown+YAML" 선언, 3.1.4는 YAML 단독) | **Resolved (post-review same session)** — ADR-0001 Library Storage Format Proposed (.tres + Godot 커스텀 Resource 채택) + GDD 3.1.3·3.1.4 정정 적용 |
| 2 | 법령 스키마 — 조의2(sub-article) 및 호(item) 누락 | **Deferred** — 자문가 Q5와 묶어 검수 |
| 3 | Holding ID 합성 규칙 미명시 | **Resolved** — Section 3.1.2에 합성 규칙 추가 (런타임 `<file.id>/holding-<N>` 결합, 책임=Library 로더) |
| 4 | AC-15 메모리 측정 방법론 부재 | **Deferred** — 측정 프로토콜 추가 또는 ADVISORY 격하, godot-specialist 자문 후 결정 |
| 5 | Section 4.1 vs 7.3 권위 가중 활성 조건 모순 | **Resolved** — 4.1 본문 명시 + 7.3 노브 셀에 OQ-5 위임 + Open Questions에 OQ-5 신규 (a/b/c 옵션) |

### Top Recommendations (deferred to next pass)
- "항목" 단위 vs "파일" 단위 용어 정리 (3.1.1 vs 3.1.4)
- `referenced_by_cases` 수동 큐레이션 부담 — OQ-4와 묶기
- 4.1 공식 다항식 placeholder 의도 명시
- 3.1.4 예시 사실관계 (시행일·선고일) 자문 검수 항목 추가
- 검색 정렬 — ID 직접 매칭 보조 키
- EC-2 검색 0건 한국어 오타 정책 — v1+ Levenshtein OQ
- AC-16 측정 환경(빌드·H/W) 명시
- AC-17 v1+ 시점 AC 분리

### Senior Verdict 요약
GDD는 디자이너 1인 4시간 도달 가능 깊이의 거의 최대치. Anti-Pillar 가드(`court_grade_weight=0` 잠금, EC-2 자동 추천 거부, EC-3 페이지네이션 거부)가 Pillar 2·4를 침해하지 않게 공식·EC 양쪽에서 막은 점이 강점. 잔여 3 블로커는 모두 자문가 답변에 의존하므로 자문 회의 입력으로 가져가는 것이 효율적. 자문 통과 시 Provisional → Approved 게이트 충족 가능.

### Next Action
1. `/architecture-decision` — Library Storage Format ADR (Markdown vs YAML vs Godot Resource) — 블로커 #1 선결 조건
2. 자문 회의 (한국 변호사 또는 법학 교수 1인, 1시간) — Q1-Q5 + 블로커 #1·#2·#4 + 시드 데이터 5-10건
3. 자문 회의 후 GDD 갱신 → Provisional → Approved
4. 그 후 `/design-system case-data-schema` (#1)
