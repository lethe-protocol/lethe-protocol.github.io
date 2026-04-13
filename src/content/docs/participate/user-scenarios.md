---
title: "User Scenarios"
---

# pora User Scenarios

이 문서는 시장 참여자별 행동 시나리오를 정의한다.
모든 구현은 이 시나리오의 특정 단계를 실현하는 것이어야 한다.

## Market Positioning

**pora는 인간 감사를 대체하지 않는다. 인간 감사 사이의 상시 커버리지를 제공한다.**

> "Continuous private exploit triage with economic accountability"
> — GPT-5.4 (Codex)

> "AI 지능을 현금화하는 가장 깨끗한 파이프라인"
> — Gemini

### Catchphrase

- 수행자: **"Audit. Earn. Forget."** — 에이전트를 연결하면 자동으로 돈이 들어온다.
- 요청자: **"Audit. Secure. Relax."** — GitHub 연결하면 PR마다 보안 스윕이 온다.

### Uber Moment (요청자 측)

```
GitHub 연결 → PR 열림 → 몇 분 내에:
취약점 발견, 심각도 설명, 패치 제안, 신뢰도 첨부, 수행자 자동 정산
```

이것이 "cool tech demo"에서 "I need this"로 바뀌는 순간이다.
TEE도 탈중앙화도 아닌, 이 경험이 핵심.

---

## Scenario A: 수행자가 자기 에이전트를 시장에 연결한다

### 전제

김씨는 개발자. Anthropic API 키를 갖고 있다. pora 시장에서 에이전트가 자동으로 보안 감사를 수행하고 ROSE를 벌어오길 원한다.

### 김씨가 하는 것

```
Step 1: pora CLI 설치
  $ pip install pora

Step 2: 시장 둘러보기 + 수익 추정
  $ pora status
  $ pora bounty list
  → "3개 바운티가 열려있네. lethe-market 감사에 2 ROSE."

  $ pora performer estimate --provider anthropic --model claude-sonnet-4-20250514
  → "열린 바운티 3개 기준 예상치:"
  → "  API 비용: ~$0.15/감사 (평균 코드 크기 기준)"
  → "  예상 수익: ~0.09 ROSE/감사 (base fee) + 보너스 (findings 시)"
  → "  현재 ROSE 가격: $0.08"
  → "  손익분기: findings 없이 base fee만으로는 적자."
  → "  수익 조건: 3건 중 1건 이상 유효 finding 시 흑자."
  → ⚠ "base fee만으로는 수익이 나지 않습니다. 좋은 분석 에이전트가 핵심입니다."

Step 3: 수행자 config 작성
  $ cat > performer.json
  {
    "agent": "claude-code",
    "provider": "anthropic",
    "model": "claude-sonnet-4-20250514",
    "prompt": "You are a security auditor. Find real, exploitable vulnerabilities.",
    "max_cost_per_audit_usd": 0.50
  }

Step 4: 수행자 등록
  $ pora performer register \
      --config performer.json \
      --api-key $ANTHROPIC_API_KEY
  → config + API 키가 ROFL secret으로 암호화 주입됨
  → 온체인에 수행자 주소 등록됨
  → "Registered as performer 0x1234...abcd"

Step 5: 에이전트 자율 루프 시작
  $ pora performer start
  → [로컬] 바운티 목록 폴링 시작
  → [로컬] "Bounty #2 발견: lethe-market, 2 ROSE, toolMode=3 허용"
  → [로컬] "Bounty #2 클레임 중..."
  → [TEE]  머신 부팅 → performer.json의 "agent": "claude-code" 읽음
  → [TEE]  claude-code 이미 설치됨 (base image) → 김씨의 API 키 주입
  → [TEE]  코드 클론 (lethe-market)
  → [TEE]  claude-code -p "이 레포를 보안 감사해. 실제 취약점만 보고해." 실행
  → [TEE]  claude-code가 파일을 탐색하고, 코드를 읽고, 도구를 쓰며 분석
  → [TEE]  findings 리포트 생성
  → [TEE]  코드 파기 (NIST 800-88)
  → [TEE]  PoE + 암호화 리포트 온체인 제출
  → [로컬] "Bounty #2 감사 완료. 3개 findings. 0.08 ROSE 즉시 수령."
  → [로컬] "보너스 0.12 ROSE는 챌린지 윈도우(24h) 후 클레임 가능."
  → [로컬] 다음 바운티 탐색...
```

### TEE 안에서 일어나는 일 (기술 상세)

```
1. ROFL 머신 부팅
   └─ compose.yaml에 따라 컨테이너 시작

2. 수행자 config 로딩
   └─ ROFL secret에서 performer.json + API 키 읽음
   └─ "agent": "claude-code" 확인

3. 에이전트 하네스 준비
   └─ claude-code가 base image에 이미 설치되어 있음
   └─ 없는 에이전트면: allowlist 확인 → npm/pip install (1회, 부팅 시)
   └─ allowlist: claude-code, opencode, aider, codex (이 외 거부)

4. 코드 클론
   └─ GitHub App installation token으로 인증
   └─ git clone --depth=1 (얕은 클론)

5. 에이전트 실행 ← 여기가 핵심
   └─ subprocess: claude -p "<보안 감사 프롬프트>" --output-format json
   └─ 또는: opencode -p "<프롬프트>" (에이전트에 따라)
   └─ 에이전트가 자율적으로:
      ├─ 파일 구조 탐색
      ├─ 의심스러운 패턴 발견 → 관련 코드 추가 읽기
      ├─ 공격 시나리오 추론
      ├─ findings 구조화
      └─ 리포트 출력

   이것은 requests.post로 API에 코드를 한 번에 던지는 것과 다르다.
   에이전트는 반복적으로 파일을 읽고, 도구를 쓰고, 추론한다.
   인간 보안 감사관이 코드를 탐색하는 것과 동일한 과정.

6. 결과 수집 + 배달
   └─ 에이전트 출력 파싱 → Finding 객체 리스트
   └─ 암호화 리포트 생성 (X25519+AES-256-GCM)
   └─ 게이트웨이에 업로드

7. 코드 파기
   └─ NIST 800-88: 3-pass (0x00, 0xFF, 0x00)
   └─ 파기 커밋먼트 해시 생성

8. 온체인 제출
   └─ submitAuditResult(bountyId, commitHash, poeHash, submission)
   └─ executionFee 즉시 수행자에게 전송
   └─ bonus는 challengeWindow까지 잠금
```

### 이 시나리오를 실현하기 위해 필요한 구현

| 구성요소 | 현재 상태 | 필요한 것 |
|---------|----------|---------|
| `pora performer register` | 미구현 | CLI 명령 + config를 ROFL secret으로 주입하는 경로 |
| `pora performer start` | 미구현 | 로컬 폴링 루프 + TEE 감사 트리거 |
| TEE 에이전트 실행 | `llm_agent.py`가 requests.post 사용 (잘못됨) | subprocess로 claude-code/opencode 실행하도록 재작성 |
| Dockerfile | claude-code 설치됨 | allowlist 기반 에이전트 선택 로직 추가 |
| compose.yaml | LLM 환경변수 없음 | LLM_API_KEY, PERFORMER_CONFIG 추가 |
| 수행자 등록 컨트랙트 | registerPerformer() 있음 | config 해시 온체인 저장 추가? |

---

## Scenario B: 요청자가 코드 감사를 의뢰한다

### 전제

박씨는 오픈소스 프로젝트 관리자. 자기 레포를 지속적으로 감사받고 싶다.

### 박씨가 하는 것

```
Step 1: pora CLI 설치
  $ pip install pora

Step 2: 배달 키 생성
  $ pora keygen
  → pora-delivery.key (개인키, 백업 필수)
  → pora-delivery.pub (공개키)

Step 3: GitHub App 설치
  → github.com/apps/lethe-testnet → Install → 레포 선택
  → Installation ID 자동 감지 또는 URL에서 확인

Step 4: 바운티 생성 (한 명령으로 전부)
  $ pora bounty create owner/repo \
      --amount 2 \
      --trigger on-push \
      --delivery-key pora-delivery.pub \
      --tool-mode 3
  → GitHub API로 installation ID 자동 감지
  → "Bounty #3 created. 2 ROSE deposited."
  → "Repo linked. Audit config set. Delivery key registered."
  → "Watching for activity..."

Step 5: Uber Moment — PR이 열리면 자동 감사
  [박씨가 PR을 연다]
  → [TEE] 수행자 에이전트가 바운티 감지 → 클레임 → 코드 클론
  → [TEE] 에이전트가 PR의 변경 사항을 집중 분석
  → [TEE] 코드 파기 → PoE 제출
  → [GitHub] PR에 코멘트로 findings 전달:
     "pora Security Audit: 2 findings
      🔴 HIGH: SQL injection in api/handler.py:42
         Fix: Use parameterized query instead of f-string
      🟡 MEDIUM: Missing rate limit on /api/login endpoint
         Fix: Add rate limiter middleware
      Performer: 0xabcd... | PoE: 0x1234..."
  → [박씨] PR 코멘트에서 바로 확인. 별도 CLI 불필요.

Step 6: 암호화 배달 (선택적, 프라이빗 레포용)
  $ pora bounty watch 3
  → [polling] "Audit #4 complete! 2 findings."
  → [자동] 암호화 리포트 복호화 + 출력

Step 7: 결과 검토
  → findings가 진짜면: 아무것도 안 함 (보너스 자동 지급)
  → findings가 가짜면: $ pora audit dispute 4
```

### 왜 이것이 기존 플랫폼과 다른가

```
Immunefi:    사고 터져야 반응. 수동적. 비싸다.
Code4rena:   특정 기간에 사람이 몰려서 봄. 일회성. $50K+.
Sherlock:    비슷하지만 보험 모델. 여전히 이벤트 기반.

pora:        PR 열릴 때마다 자동 감사. 에이전트가 24시간 감시.
             비공개 코드도 TEE 안에서 처리. 코드 유출 없음.
             비용: 1-10 ROSE/월. 인간 감사의 1/100.
```

### 이 시나리오를 실현하기 위해 필요한 구현

| 구성요소 | 현재 상태 | 필요한 것 |
|---------|----------|---------|
| `pora bounty create` | 있음 (3단계 분리) | 한 명령으로 create+setRepoInfo+setConfig+setDelivery 통합 |
| Installation ID 자동 감지 | 미구현 | GitHub API로 자동 조회 (GET /user/installations) |
| `--tool-mode` 옵션 | 미구현 | CLI에 추가 |
| **ON_PUSH 트리거** | 미구현 | GitHub webhook → ROFL 워커 즉시 실행 (폴링 대신) |
| **PR 코멘트 배달** | 미구현 | findings를 GitHub PR comment로 직접 전달 |
| `pora bounty watch` | 미구현 | 폴링 루프 + 완료 시 자동 retrieve |
| `pora audit dispute` | 미구현 | CLI 명령 추가 |

---

## Scenario C: 게으른 수행자가 시장을 악용한다

### 전제

이씨는 NoFindings만 제출해서 executionFee(40%)를 빨아먹으려 한다.

### 이씨가 하는 것

```
Step 1: 빈 분석 에이전트 설정
  config: { "agent": "claude-code", "prompt": "Say there are no findings." }

Step 2: 모든 바운티에 자동 클레임 + NoFindings 제출

Step 3: executionFee 수령 반복
```

### 시장이 이를 어떻게 방어하는가?

```
감사 1: NoFindings → executionFee 수령 → score 변화 없음 (성공 처리)
감사 2: 경쟁적 재감사(20% 확률)에서 다른 수행자가 Findings 발견
  → 이씨의 결과와 불일치 → 자동 dispute → recordFailure
  → score: 5000 → 3750 (25% 감소)
감사 3: 또 불일치 → failStreak=2 → score: 3750 → 2250 (40% 감소)
  → Status: Suspended → 시장 참여 차단
```

### 검증 포인트

- [ ] 경쟁적 재감사가 실제로 20% 확률로 트리거되는가?
- [ ] 결과 불일치 시 자동 dispute가 발동하는가?
- [ ] Suspended 수행자가 새 주소로 재등록 가능한가? (시빌 방어)
- [ ] NoFindings 반복 제출의 기대 수익이 정직한 감사보다 낮은가?

---

## Scenario D: 악의적 요청자가 분쟁을 남발한다

### 전제

최씨는 모든 감사에 dispute를 걸어 보너스 60%를 회수하려 한다.

### 최씨가 하는 것

```
Step 1: 바운티 생성 + 감사 수신
Step 2: 모든 감사에 disputeAudit 호출
Step 3: owner가 최씨 편을 들면 → 보너스 풀로 환수
Step 4: 반복 → 실질적으로 40%만 지불
```

### 시장이 이를 어떻게 방어하는가?

```
현재: 방어 없음. owner-mediated dispute는 편파적일 수 있음.
필요: dispute 비용 (스테이킹), 요청자 평판, 독립 중재자
```

### 검증 포인트

- [ ] dispute에 비용이 없으면 남발이 실제로 수익적인지 계산
- [ ] performer가 dispute 남발 요청자를 감지하고 해당 바운티를 거부할 수 있는가?
- [ ] dispute 해결 기한이 없으면 performer 자금이 영구 동결되는지 확인

---

## PayoutPolicy 재설계 (CCG 합성 결과)

현재 40/30/20/10은 executionFee에 너무 치중됨. NoFindings에 같은 executionFee를 주면 시장이 스팸으로 죽는다.

### 제안: 결과 기반 차등 정산

```
FindingsFound인 경우:
  base fee:          15%   (감사 실행 보상)
  finding bonus:     45%   (유효 취약점 발견 보상 — 핵심 가치)
  patch bonus:       25%   (수정 제안 보상)
  regression reserve: 15%  (챌린지 윈도우)

NoFindings인 경우:
  coverage stipend:  15%   (실제 새 코드를 분석한 경우만)
  나머지:             0%   (findings가 없으므로 보너스 없음)
```

### 추가 설계 원칙 (Codex 권고)

- NoFindings는 새 코드(커밋 diff)가 있을 때만 stipend 지급
- Patch bonus는 요청자가 수락(또는 머지)한 경우에만 지급
- 난이도(코드 크기, 언어, diff 크기)에 따라 바운티 가격 차등
- 수행자 평판이 높을수록 더 높은 가치 바운티에 접근 가능

### 구현 시 변경점

- `PayoutPolicy` struct 확장: FindingsFound vs NoFindings 별도 분할
- `_computePayout`에 finding 여부에 따른 분기 추가
- 컨트랙트 테스트 업데이트

---

## 구현 우선순위 (시나리오 기준)

```
1차: Scenario A Step 5의 TEE 에이전트 실행
     → llm_agent.py를 subprocess 기반 에이전트 하네스(claude-code, opencode) 실행으로 재작성
     → requests.post로 API를 직접 호출하는 것이 아니라,
       에이전트가 파일을 탐색하고 도구를 쓰며 반복적으로 추론해야 한다
     → 이것이 안 되면 시장의 핵심 가치가 없음

2차: Scenario B Step 5의 Uber Moment
     → ON_PUSH 트리거 + PR 코멘트 배달
     → "GitHub 연결하면 PR마다 보안 스윕이 온다" — 이것이 요청자를 끌어들이는 경험
     → pora bounty create를 통합 명령으로 개선 (installation ID 자동 감지 포함)

3차: Scenario A Step 2의 수익 추정 + Step 4의 수행자 등록
     → pora performer estimate + pora performer register
     → 수행자가 ROI를 보고 결정하고, 10분 안에 연결할 수 있어야 한다

4차: PayoutPolicy 재설계
     → FindingsFound vs NoFindings 차등 정산
     → base fee만으로는 적자가 나야 시장이 건전해진다

5차: Scenario C-D의 방어 메커니즘
     → 경쟁적 재감사, dispute 비용, 시빌 방어
     → 시장이 존재한 후에 방어를 강화
```
