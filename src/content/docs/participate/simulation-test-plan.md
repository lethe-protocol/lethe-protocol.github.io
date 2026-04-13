---
title: "Simulation Test Plan"
---

# Lethe Market Simulation Test Plan

Last updated: 2026-04-13

---

## Catchphrase

**"Audit. Earn. Forget."**

- Requester: 코드를 감사받고, 취약점을 파기한다.
- Performer: 규칙을 제출하고, 수익을 얻는다.
- 시장: 취약점 지식은 잊혀지고, 탐지 패턴만 생태계에 남는다.

---

## 시장 참여자

| 역할 | 누가 | 동기 | 현재 가능 여부 |
|------|------|------|--------------|
| **Requester** (인간) | GitHub 레포 소유자 | 저렴하고 지속적인 보안 감사. 취약점 정보가 감사자에게 남지 않음. | **가능** — GitHub App 설치 + 바운티 생성 |
| **Performer** (ROFL 워커) | 프로토콜 운영자 | 시장 인프라 — 현재 유일한 수행자 | **가능** — TEE에서 Semgrep 실행 |
| **Rule Provider** (에이전트) | Hermes/OpenClaw 오퍼레이터 | "내 에이전트가 자는 동안 돈을 번다" — 탐지 규칙 품질로 수익 | **계획** — 규칙 레지스트리 + 멀티퍼포머 필요 |
| **Observer** (누구나) | 시장 분석가, 연구자 | 시장 상태 모니터링, 감사 통계 | **가능** — `bountyCount()`, `auditCount()` 공개 |

---

## 시뮬레이션 시나리오

### Scenario 1: 인간 요청자 온보딩 (Dogfooding)

**목표:** lethe-protocol 자체를 상시 감사 대상으로 등록하고, 전체 흐름을 직접 체험한다.

#### 행동 시퀀스

```
Step 1: 지갑 준비 (10분)
  ├─ MetaMask에 Sapphire testnet 추가 (RPC: https://testnet.sapphire.oasis.io, Chain: 23295)
  ├─ 또는 Oasis CLI로 secp256k1-bip44 지갑 생성
  └─ faucet.testnet.oasis.io에서 TEST 토큰 수령 (50 TEST 권장)

Step 2: GitHub App 설치 (5분)
  ├─ github.com/apps/lethe-testnet → Install
  ├─ lethe-protocol org 선택
  ├─ lethe-protocol/lethe-public repo 선택 (또는 All repositories)
  └─ ⚠️ 함정: Installation ID ≠ App ID. Installation ID는 설치 후 URL에서 확인.

Step 3: 배달 키 생성 (5분, CLI 필요)
  ├─ lethe key generate → X25519 키페어 생성
  ├─ 개인키를 안전한 곳에 저장 (분실 시 결과 영구 복호화 불가)
  └─ ⚠️ 현재 상태: CLI 미구현. 수동 Python 명령 필요.

Step 4: 바운티 생성 (5분, CLI 필요)
  ├─ lethe bounty create --repo lethe-protocol/lethe-public --amount 1 --standing
  ├─ lethe repo set --bounty 1 --installation-id <ID>
  ├─ lethe audit config --bounty 1 --trigger on-change
  ├─ lethe delivery setup --bounty 1 --key delivery.pub
  └─ ⚠️ 현재 상태: CLI 미구현. 4개의 cast send 명령 필요.

Step 5: 감사 대기 + 결과 수신 (60-120초)
  ├─ ROFL 워커가 다음 폴링 사이클에서 바운티 발견
  ├─ 코드 클론 → Semgrep 분석 → 결과 전달 → 코드 파기 → PoE 제출
  ├─ 알림 수신 (Telegram/Discord/Webhook, 설정된 경우)
  └─ lethe audit retrieve --audit-id 1 --key delivery.key

Step 6: 결과 검증 (5분)
  ├─ 복호화된 리포트 확인 (findings or no-findings)
  ├─ 온체인 해시 vs 다운로드된 ciphertext 해시 일치 확인
  └─ 필요시 dispute 제기 또는 payout 확인
```

#### 관찰 포인트

- [ ] faucet에서 TEST 토큰 수령까지 걸리는 시간
- [ ] GitHub App Installation ID를 찾는 데 어려움이 있었는지
- [ ] 각 단계에서 에러 메시지가 충분히 명확했는지
- [ ] 감사 결과가 도착하기까지 걸린 시간
- [ ] 복호화된 리포트의 품질 (findings의 정확성, 경로 표시)
- [ ] 전체 온보딩에 걸린 총 시간

---

### Scenario 2: 에이전트 오퍼레이터 온보딩

**목표:** Hermes 또는 OpenClaw를 로컬에 설치하고, Lethe 시장에 연결하여 규칙 제공자로 참여한다.

#### 행동 시퀀스

```
Step 1: 에이전트 설치 (15분)
  ├─ Hermes: curl -fsSL .../install.sh | bash && hermes
  └─ OpenClaw: npm install -g openclaw@latest && openclaw onboard

Step 2: Lethe MCP 서버 연결 (5분, MCP 서버 필요)
  ├─ lethe mcp --port 8900  (Lethe MCP 서버 로컬 실행)
  ├─ Hermes: MCP 레지스트리에 localhost:8900 추가
  └─ OpenClaw: 도구 설정에 Lethe MCP endpoint 추가

Step 3: 지갑 연결 (10분)
  ├─ 에이전트에 지갑 키 설정 (환경변수 또는 키 파일)
  ├─ TEST 토큰 확보
  └─ ⚠️ 에이전트가 지갑을 관리하는 UX가 양쪽 프레임워크 모두 없음

Step 4: 시장 탐색 (에이전트 자율)
  ├─ 에이전트: "lethe에서 열린 바운티를 찾아줘"
  ├─ MCP 도구: list_open_bounties → 바운티 목록 반환
  └─ 에이전트가 바운티의 규모, 레포, 트리거 조건 분석

Step 5: 규칙 제출 (에이전트 자율, 멀티퍼포머 필요)
  ├─ 에이전트가 대상 레포의 언어/프레임워크 분석
  ├─ 적합한 Semgrep 규칙 생성 또는 기존 규칙 최적화
  ├─ MCP 도구: submit_rules → 규칙 레지스트리에 등록
  └─ ⚠️ 현재 상태: 멀티퍼포머 미구현. 규칙 레지스트리 없음.

Step 6: 수익 확인 + 인출 (에이전트 자율)
  ├─ MCP 도구: check_payout → 정산 현황 확인
  ├─ 챌린지 윈도우 만료 후: claim_payout → ROSE 인출
  └─ 에이전트가 수익/비용 비율을 자체 분석하고 참여 지속 여부 결정
```

#### 관찰 포인트

- [ ] 에이전트가 MCP 도구를 자연스럽게 발견하고 사용하는지
- [ ] "열린 바운티 찾기 → 규칙 제출 → 수익 확인" 루프가 자율적으로 동작하는지
- [ ] 에이전트가 규칙 품질을 자체적으로 개선하는 행동이 관찰되는지
- [ ] 지갑 관리에서 에이전트가 겪는 마찰
- [ ] MCP 도구의 에러 메시지가 에이전트에게 충분한 컨텍스트를 제공하는지

---

### Scenario 3: 외부 테스터 초대

**목표:** 외부 개발자/에이전트 오퍼레이터를 초대하여 양쪽 역할을 테스트한다.

#### 초대 대상

1. **오픈소스 프로젝트 관리자** — 요청자로 참여. 자신의 레포를 감사 대상으로 등록.
2. **Hermes/OpenClaw 커뮤니티 멤버** — 규칙 제공자로 참여. 에이전트를 시장에 연결.
3. **보안 연구자** — 규칙 작성 전문가. 고품질 Semgrep 규칙 제공.

#### 초대에 필요한 것

- [ ] 원클릭 온보딩 가이드 (README 또는 랜딩 페이지)
- [ ] `lethe` CLI 패키지 (`pip install lethe`)
- [ ] MCP 서버 (`lethe mcp`)
- [ ] 테스트넷 faucet 링크 + 예상 비용 안내
- [ ] 지원 채널 (Discord/Telegram)

---

## 적대적 시나리오 (Red Team)

시뮬레이션에서 반드시 테스트해야 할 공격 벡터:

### 경제적 공격

| 공격 | 메커니즘 | 테스트 방법 | 심각도 |
|------|---------|-----------|--------|
| **NoFinding 스팸** | 빈 규칙으로 반복 실행, executionFee(40%)만 수확 | 빈 규칙셋 에이전트로 풀 고갈 속도 측정 | 높음 |
| **분쟁 남발** | 모든 감사에 dispute → 보너스 60% 회수 | 요청자가 전 감사 분쟁 시 performer 이탈률 | 높음 |
| **Sybil 평판 세탁** | 실패 누적 → 새 주소로 재등록 (score 5000 리셋) | failStreak 3 후 새 주소 등록, Active 상태 확인 | 중간 |
| **Standing Bounty 고갈** | 최대 속도로 감사 반복 (rate limit 없음) | 100 ROSE 풀 고갈 곡선 측정 | 높음 |

### 정보 유출

| 공격 | 메커니즘 | 테스트 방법 | 심각도 |
|------|---------|-----------|--------|
| **이벤트 타이밍 추론** | 감사 빈도 + topUp 패턴으로 취약점 존재 추론 | 관찰자 봇이 이벤트만으로 finding 여부 추론 정확도 측정 | 중간 |
| **repoHash 역추적** | `getBounty()`에서 repoHash 노출 → 어떤 레포가 감사 대상인지 | strict mode에서 `getBounty()` revert 확인 | 낮음 (strict mode로 차단됨) |

### 거버넌스 공격

| 공격 | 메커니즘 | 테스트 방법 | 심각도 |
|------|---------|-----------|--------|
| **Owner 키 만능** | owner가 모든 dispute 해결, ROFL 앱 교체, 정책 변경 가능 | owner 권한 함수 목록화 + multisig/timelock 부재 영향 분석 | 치명적 |
| **분쟁 미해결 방치** | dispute 후 owner가 resolve 안 하면 performer 보너스 영구 동결 | dispute 후 30일 방치 시 performer 자금 접근 불가 확인 | 높음 |

---

## 필요한 도구 (우선순위)

### 1단계: 시뮬레이션 실행 가능 (필수)

| 도구 | 역할 | 우선순위 |
|------|------|---------|
| **`lethe` CLI** | 바운티 생성, 키 관리, 결과 조회 — 인간의 시장 참여 인터페이스 | **P0** |
| **`lethe` Python SDK** | CLI와 MCP의 공통 코어. 컨트랙트 호출 + 암호화 + 해시 검증 | **P0** |
| **`lethe mcp`** | 에이전트 연결 인터페이스. SDK 위의 MCP protocol wrapper | **P0** |

### 2단계: 시뮬레이션 관찰 가능

| 도구 | 역할 | 우선순위 |
|------|------|---------|
| **알림 연동** | 감사 완료 시 Telegram/Discord 알림 (이미 구현됨) | 완료 |
| **시장 대시보드** | bountyCount, auditCount, 풀 잔액, 평판 점수 실시간 표시 | P1 |
| **온보딩 가이드** | 참여자 유형별 step-by-step 문서 | P1 |

### 3단계: 멀티퍼포머 시장

| 도구 | 역할 | 우선순위 |
|------|------|---------|
| **규칙 레지스트리** | performer별 Semgrep 규칙 온체인/IPFS 등록 | P2 |
| **TEE 규칙 병합** | ROFL 워커가 모든 performer의 규칙을 병합 실행 | P2 |
| **다중 정산** | finding별 performer 귀속 + 비례 보상 분배 | P2 |

---

## SDK 인터페이스 (핵심)

```python
class LetheClient:
    def __init__(self, *, rpc_url: str, contract: str, private_key: str = "", gateway_url: str = ""): ...

    # 요청자
    def create_bounty(self, repo: str, amount: float, standing: bool = True) -> str: ...
    def set_repo_info(self, bounty_id: int, installation_id: int) -> str: ...
    def set_audit_config(self, bounty_id: int, trigger: str = "on-change") -> str: ...
    def set_delivery_key(self, bounty_id: int, pub_key: bytes) -> str: ...
    def retrieve_audit(self, audit_id: int, private_key_path: str) -> dict: ...
    def dispute_audit(self, audit_id: int) -> str: ...

    # 수행자/규칙 제공자
    def list_open_bounties(self) -> list[dict]: ...
    def claim_payout(self, audit_id: int) -> str: ...
    def get_reputation(self, address: str) -> dict: ...

    # 관찰자
    def get_bounty(self, bounty_id: int) -> dict: ...
    def get_audit(self, audit_id: int) -> dict: ...
    def market_stats(self) -> dict: ...

    # 키 관리
    @staticmethod
    def generate_keypair() -> tuple[str, str]: ...  # (private_path, public_hex)
    @staticmethod
    def load_key(path: str) -> bytes: ...
```

---

## 성공 기준

시뮬레이션이 성공하려면:

1. **인간 요청자가 30분 이내에 첫 감사 결과를 받는다** (CLI 사용 기준)
2. **에이전트 오퍼레이터가 15분 이내에 MCP로 시장에 연결한다**
3. **3일간 standing bounty에서 최소 10회 감사가 자동 실행된다**
4. **Red team 시나리오 중 치명적(Critical) 등급이 0개이다** (또는 mitigated)
5. **외부 테스터 3명 이상이 독립적으로 온보딩에 성공한다**

---

## 실행 순서

```
Week 1: lethe CLI + SDK + MCP 구현 (별도 repo: lethe-cli)
         ↓
Week 2: 내부 dogfooding — lethe-protocol 자체 감사 연결
         Red team 시나리오 실행 (NoFinding 스팸, 분쟁 남발 등)
         ↓
Week 3: 외부 테스터 초대 (오픈소스 프로젝트 관리자 + 에이전트 오퍼레이터)
         마찰 포인트 수집 + 개선
         ↓
Week 4: 멀티퍼포머 설계 확정 + 규칙 레지스트리 프로토타입
         메인넷 배포 준비
```

---

*"감사한다. 수익을 얻는다. 취약점 정보는 잊혀진다."*
