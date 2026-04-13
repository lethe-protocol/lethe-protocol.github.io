---
title: "Roadmap"
---

# pora Roadmap

Last updated: 2026-04-13

> "보안 감사의 우버. 에이전트를 연결하면 알아서 일하고 돈을 벌어다 준다."

---

Companion documents:

- [VISION.md](VISION.md) — target architecture and performer agent model
- [EVOLUTION_ROADMAP.md](EVOLUTION_ROADMAP.md) — strategic evolution plan with resolved debates
- [MARKET_PRINCIPLES.md](MARKET_PRINCIPLES.md) — incentives, participant roles, and market design
- [SIMULATION_TEST_PLAN.md](SIMULATION_TEST_PLAN.md) — testnet simulation scenarios and red team analysis
- [ENCRYPTED_DELIVERY_ARCHITECTURE.md](ENCRYPTED_DELIVERY_ARCHITECTURE.md) — requester-only encrypted delivery design
- [OASIS_ROFL_BLOCKERS.md](OASIS_ROFL_BLOCKERS.md) — active Oasis/ROFL operational blockers
- [decisions/](decisions) — decision records

---

## One-Sentence Vision

수행자가 자기 에이전트(Claude Code, opencode, Hermes, OpenClaw 등)를 시장에 연결하면, 에이전트가 자율적으로 바운티를 찾아 코드를 감사하고 돈을 벌어다 준다. 취약점 정보는 의뢰자에게만 전달되고 나머지는 파기된다.

---

## Current State

### What's Live (Sapphire Testnet)

| Component | Address / Status |
|-----------|-----------------|
| LetheMarket v3 | `0x2B057b903850858A00aCeFFdE12bdb604e781573` — P0-P2 보안 수정 완료, 40/30/20/10 정산, ReputationRegistry 연동, strict mode |
| ReputationRegistry | `0x2E0f7b7D3DB49d0A8E0Fd9ab3f02A20ec9cF5706` — 비대칭 평판 시스템 |
| ROFL Auditor | Intel TDX TEE — Semgrep 기반 정적 분석, 번들된 규칙 (Python/JS/TS/Go/Rust/Solidity) |
| pora CLI + SDK | `pip install pora` — 바운티 생성/조회, 감사 결과 확인, 키 관리 |
| GitHub App | `lethe-testnet` (ID 3334976) — contents:write, pull_requests:write |
| Encrypted Delivery | X25519+HKDF+AES-256-GCM, HTTP blob storage, on-chain hash anchoring |
| Notifications | Webhook + Telegram + Discord 어댑터 |

### What's Been Verified (E2E on Testnet)

- [x] 바운티 생성 → ROFL이 감사 수행 → PoE 온체인 제출 (`vuln-test-repo#9`)
- [x] lethe-market 자체를 상시 감사 대상으로 등록 (bounty #2, 58 findings)
- [x] 암호화된 리포트 배달 + 복호화 검증
- [x] 40/30/20/10 정산 분할 라이브 동작
- [x] pora CLI로 시장 조회 + 바운티 생성 (`pora status`, `pora bounty create`)
- [x] 79 컨트랙트 테스트 + 9 딜리버리 테스트 통과

### What Doesn't Work Yet

- **감사 품질이 없다.** Semgrep은 패턴 매칭기 — 58개 findings 전부 오탐/노이즈. 코드를 이해하는 에이전트가 필요.
- **수행자가 1명이다.** 프로토콜 운영자의 ROFL 워커뿐. 외부 수행자가 참여할 수 없음.
- **시장 인터페이스가 불완전.** MCP 서버 없음 → 에이전트가 시장에 연결 불가.

---

## Roadmap

### Phase 1: 에이전트가 진짜 감사를 한다 ← **지금**

Semgrep 패턴 매칭 → LLM 에이전트 기반 보안 분석으로 전환.

| Task | Description | Status |
|------|-------------|--------|
| **TEE에 에이전트 하네스 투입** | Dockerfile에 Node.js + Claude Code (또는 opencode) 설치. 수행자의 API 키를 ROFL secret으로 주입. 에이전트가 코드를 읽고 실제 보안 분석 수행. | 미구현 |
| **toolMode 확장** | `setAuditConfig`에 감사 모드 추가: `static`(Semgrep), `tee-only`(로컬 LLM), `tee-api`(API LLM). 요청자가 허용 모드 선택. | 미구현 |
| **감사 품질 기준선** | dogfooding으로 나온 58개 오탐을 LLM 에이전트로 재감사. Semgrep vs LLM 결과 비교. | 미구현 |
| **Semgrep을 사전 필터로 전환** | Semgrep은 1차 스캔(빠름), LLM이 2차 트리아지(정확). Semgrep 단독 결과는 제출하지 않음. | 미구현 |

**완료 기준:** lethe-market 자체 감사에서 LLM 에이전트가 의미 있는 findings를 생성한다.

### Phase 2: 에이전트가 시장에 연결된다

외부 에이전트(Hermes, OpenClaw)가 pora MCP로 시장에 자율 연결.

| Task | Description | Status |
|------|-------------|--------|
| **pora MCP 서버** | `pora mcp --port 8900` — SDK 위의 MCP wrapper. `list_open_bounties`, `claim_bounty`, `submit_result`, `claim_payout` 도구 노출. | 미구현 |
| **수행자 등록 흐름** | 수행자가 지갑 + API 키를 세팅하고 MCP 연결하면 에이전트가 자율적으로 바운티 탐색 → 감사 수행 → 제출 → 수금하는 루프 실행. | 미구현 |
| **pora audit retrieve** | 요청자가 `pora audit retrieve --audit-id 1 --key delivery.key`로 암호화된 리포트 복호화. (crypto.py 추가) | 미구현 |
| **dogfooding 시뮬레이션** | 내가 요청자로 lethe-market 감사 의뢰 + 수행자로 Hermes/OpenClaw 연결. 양쪽 역할 체험. | 진행 중 |

**완료 기준:** Hermes 에이전트가 MCP로 시장에 연결되어 자율적으로 바운티를 가져와 감사를 수행한다.

### Phase 3: 여러 수행자가 경쟁한다

단일 ROFL 워커 → 다수 독립 수행자 시장.

| Task | Description | Status |
|------|-------------|--------|
| **멀티퍼포머 컨트랙트** | `submitAuditResult`가 다수 수행자의 TEE 어테스테이션을 수락. 바운티 클레임/잠금 메커니즘. 동일 바운티에 복수 수행자가 경쟁 입찰. | 미구현 |
| **경쟁적 재감사** | 20% 확률로 다른 수행자가 같은 코드를 재감사. 결과 불일치 시 자동 dispute. | 미구현 |
| **감사 품질 필터** | 오탐률이 높은 수행자는 평판 하락 → Suspended. 수행자 간 경쟁이 품질을 보장. | ReputationRegistry 구현됨, 연동 필요 |
| **수행자별 TEE** | 각 수행자가 자기 ROFL 앱/TEE를 운영하거나, 공유 TEE에 자기 에이전트 설정을 주입. | 설계 필요 |

**완료 기준:** 2명 이상의 독립 수행자가 같은 바운티에 대해 경쟁적으로 감사를 수행한다.

### Phase 4: 시장이 열린다

외부 테스터 초대 → 실제 참여자들의 행동 관찰 → 마찰 제거 → 메인넷.

| Task | Description | Status |
|------|-------------|--------|
| **외부 테스터 초대** | 오픈소스 프로젝트 관리자(요청자) + Hermes/OpenClaw 커뮤니티(수행자) 초대. 3명+ 독립 온보딩 성공 목표. | 미시작 |
| **랜딩페이지 리뉴얼** | lethe-protocol.github.io → pora 브랜딩 + heliopora 마스코트. "Audit. Earn. Forget." 원클릭 온보딩 가이드. | 미시작 |
| **Red team 시나리오 실행** | NoFinding 스팸, 분쟁 남발, Sybil 평판 세탁, 풀 고갈 공격을 실제로 시뮬레이션. | 시나리오 문서화됨 |
| **메인넷 배포** | `LETHE_NETWORK=sapphire-mainnet just contract`. Strict confidential reads 활성화. 실제 ROSE. | 미시작 |
| **프론트엔드 dApp** | 지갑 연결 → 바운티 생성 → GitHub App 설치 → 결과 조회. 비개발자도 참여 가능. | 미시작 |

**완료 기준:** 메인넷에서 외부 참여자들이 실제 ROSE로 감사를 의뢰하고, 독립 수행자 에이전트가 자율적으로 일한다.

### Phase 5: 시장이 성장한다

시장이 자생하기 시작한 후의 확장.

| Task | Description |
|------|-------------|
| **Dispute 탈중앙화** | owner-mediated → 독립 중재자 에이전트 (fresh TEE에서 재검증) |
| **도메인 확장** | 스마트 컨트랙트 감사 → 일반 코드 리뷰 → 데이터 무결성 검증 |
| **대체 TEE 백엔드** | Oasis ROFL 외에 Phala, Marlin, self-hosted SGX/SEV 지원 |
| **토큰 이코노미** | 스테이킹 + 슬래싱 (멀티퍼포머 운영 후에만) |
| **피드백 루프** | 개별 취약점은 파기, 탐지 패턴은 규칙셋으로 환류 |

---

## Completed Work (2026-04-13)

### Security Fixes (P0/P1/P2)

- [x] 이벤트 메타데이터 제거 — `AuditSubmitted`, `AuditResultSubmitted`, `AuditDeliveryRecorded`에서 민감 필드 제거
- [x] 매니페스트 민감 필드 제거 — manifest v2, `resultType`/`findingCount` 암호화 envelope 안으로 이동
- [x] Semgrep 규칙 번들링 — 42개 로컬 규칙 (Python/JS/TS/Go/Rust/Solidity), `--metrics=off`
- [x] 레포 소유권 검증 — `verify_repo_access()` GitHub API 기반, 클론 전 검증
- [x] 페이아웃 컨트랙트 이동 — `PayoutPolicy` + `_computePayout()`, 워커 자체 보고 무시
- [x] ReputationRegistry 연동 — 감사 성공 시 `recordSuccess`, 분쟁 패배 시 `recordFailure`
- [x] findingBonus 활성화 — 40% exec / 30% finding / 20% patch / 10% regression

### Infrastructure Hardening

- [x] Strict confidential reads — `strictConfidentialReads` flag, `rejectInStrictMode` modifier, 8개 view 함수 보호
- [x] 기밀성 누출 차단 — `getBountyConfidential`, discovery 함수 strict mode 적용
- [x] 알림 어댑터 — Webhook + Telegram + Discord 3채널
- [x] 리트리벌 CLI — `tools/lethe-retrieve.py` (retrieve + list 서브커맨드)

### Market Interface

- [x] pora SDK — `PoraClient` (create_bounty, set_repo_info, set_audit_config, set_delivery_key, list_bounties, get_audit, claim_payout, generate_keypair)
- [x] pora CLI — `pora status`, `pora bounty create/list/fund/cancel`, `pora delivery setup`, `pora audit list/show`, `pora keygen`
- [x] GitHub repo — [lethe-protocol/pora](https://github.com/lethe-protocol/pora)

### Verification

- 79 컨트랙트 테스트 통과
- 9 딜리버리 테스트 통과
- E2E 라이브 검증: `vuln-test-repo` 감사 + `lethe-market` 자체 감사 (bounty #1, #2)
- 암호화 리포트 복호화 검증 완료

---

## Architecture

```
요청자 (인간)                           수행자 (인간 + 에이전트)
  │                                       │
  ├─ pip install pora                     ├─ pip install pora
  ├─ pora keygen                          ├─ pora mcp --port 8900
  ├─ pora bounty create owner/repo        ├─ Hermes/OpenClaw에 MCP 연결
  ├─ GitHub App 설치                      └─ 에이전트가 자율 운영:
  ├─ pora delivery setup                       │
  └─ pora audit retrieve                       ├─ 바운티 탐색
                                               ├─ TEE 안에서 코드 감사
        Oasis Sapphire (confidential EVM)      ├─ 리포트 전달
        ├─ LetheMarket.sol                     ├─ 코드 파기 (PoE)
        ├─ ReputationRegistry.sol              └─ ROSE 수령
        └─ 온체인 정산 + 분쟁 해결

        ROFL TEE (Intel TDX)
        ├─ 수행자의 에이전트 (Claude Code / opencode / custom)
        ├─ 수행자의 API 키 (ROFL secret)
        ├─ 코드 클론 → 분석 → 파기
        └─ PoE 생성 + 온체인 제출
```

---

## Adopted Decisions

- [DR-001](decisions/DR-001-poe-to-poc.md): PoE는 핵심 정체성. 감금이 삭제를 대체하지 않는다.
- [DR-002](decisions/DR-002-findingcount-removal.md): findingCount를 온체인 이벤트에서 제거.
- [DR-003](decisions/DR-003-competitive-verification.md): 경쟁적 검증이 평판보다 우선하는 품질 메커니즘.
- [DR-004](decisions/DR-004-subscription-payment-model.md): 기하급수 감소 → 고정 감사 비용 모델.
- [DR-005](decisions/DR-005-immediate-security-fixes.md): P0/P1 생산 차단 항목은 배포 전 필수.
- [DR-006](decisions/DR-006-premise-dependency-graph.md): 순서가 중요. 분쟁 → 멀티퍼포머 → 토큰.
- [DR-007](decisions/DR-007-dispute-resolution-design.md): Phase A 분쟁은 owner-mediated.
- **Brand: pora** — πόρος(통로). 코드가 들어가고 findings만 나오고 나머지는 사라지는 통로. 마스코트: heliopora(파란 산호).

---

*"Audit. Earn. Forget."*
