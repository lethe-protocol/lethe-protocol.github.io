---
title: "Onboarding Guide"
---

# Welcome to pora

## How We Use Claude

Based on lethe-protocol's usage over the last 30 days:

Work Type Breakdown:
  Plan Design    ████████████████░░░░  80%
  Build Feature  ███░░░░░░░░░░░░░░░░░  15%
  Write Docs     █░░░░░░░░░░░░░░░░░░░   5%

Top Skills & Commands:
  /autopilot  ████████░░░░░░░░░░░░  2x/month
  /team       ████░░░░░░░░░░░░░░░░  1x/month
  /ccg        ████░░░░░░░░░░░░░░░░  1x/month
  /wiki       ████░░░░░░░░░░░░░░░░  1x/month
  /omc-teams  ████░░░░░░░░░░░░░░░░  1x/month

Top MCP Servers:
  (none configured — direct tool use only)

## Your Setup Checklist

### Codebases
- [ ] [lethe-market](https://github.com/lethe-protocol/lethe-market) — Protocol contracts (Solidity) + ROFL TEE audit worker (Python). The market infrastructure.
- [ ] [pora](https://github.com/lethe-protocol/pora) — SDK + CLI + MCP server (Python). How humans and agents interact with the market.
- [ ] [lethe-protocol.github.io](https://github.com/lethe-protocol/lethe-protocol.github.io) — Landing page and docs site.
- [ ] [vuln-test-repo](https://github.com/lethe-protocol/vuln-test-repo) — Intentionally vulnerable code for E2E audit pipeline testing.

### MCP Servers to Activate
  (No team MCP servers yet. The `pora mcp` server is the market interface for AI agents — you'll build/test it, not connect to it.)

### Skills to Know About
- `/autopilot` — End-to-end autonomous execution. Used for large multi-phase implementations (e.g., implementing the full roadmap across contracts, worker, and CLI).
- `/team` — Multi-agent coordinated work. Used for structured debates with specialist perspectives (mechanism designer, red team, UX, architect) to produce strategy documents.
- `/ccg` — Claude-Codex-Gemini tri-model orchestration. Routes questions to three models in parallel and synthesizes answers.

### Key Tools
- `just plan` / `just smoke` / `just worker` / `just contract` — ROFL deployment recipes (see `justfile`)
- `pora status` / `pora bounty list` / `pora audit show` — Market interaction CLI
- `cast send` — Foundry CLI for direct contract calls (Sapphire testnet)
- `oasis rofl` — Oasis CLI for ROFL TEE management

## Team Tips

- **비전 먼저 읽어라.** `docs/VISION.md`의 "Performer Agent Architecture" 섹션이 시장 전체 구조를 설명한다. 코드를 만지기 전에 이 구조를 이해해야 한다.
- **구현 전에 시나리오 문서를 확인해라.** `docs/SIMULATION_TEST_PLAN.md`에 참여자별 행동 시나리오가 적혀 있다. "이 코드가 어떤 시나리오의 어떤 단계를 만드는 것인가"가 명확하지 않으면 구현하지 마라.
- **TEE 안에서 에이전트가 돌아야 한다.** LLM API를 직접 `requests.post`로 호출하는 게 아니라, 에이전트 하네스(Claude Code, opencode 등)가 TEE 안에서 실행되어야 한다. 에이전트가 스스로 파일을 탐색하고, 도구를 쓰고, 반복적으로 추론한다.
- **ROFL 배포 사이클이 느리다.** Docker build → push → ROFL build → deploy → 머신 부팅까지 10-20분. 머신이 만료되면(1시간) 재배포 필요. `just smoke`로 상태 확인.
- **testnet ROSE는 무료지만 LLM API는 유료다.** 수행자 에이전트 테스트 시 실제 API 크레딧이 소모된다. 비용을 의식하라.

## Market Simulation Roles

시장을 검증하려면 각 역할을 직접 수행해봐야 한다.

### Starter Task: 정직한 요청자로 전체 사이클 완료

```bash
# 1. CLI 설치
pip install pora

# 2. 시장 상태 확인
pora status
pora bounty list

# 3. 배달 키 생성
pora keygen

# 4. 바운티 생성 (vuln-test-repo 추천)
pora bounty create lethe-protocol/vuln-test-repo \
  --amount 1 --installation-id <YOUR_ID> --trigger on-change

# 5. 암호화 배달 설정
pora delivery setup <bounty_id> --key pora-delivery.pub

# 6. 감사 완료 대기 (60-120초)
pora audit list

# 7. 결과 복호화
pora audit retrieve <audit_id> --key pora-delivery.key --handle <handle>
```

### 그 다음: 공격자가 되어 시장을 부셔봐라

| 역할 | 뭘 하는가 | 뭘 검증하는가 |
|------|---------|-------------|
| **게으른 수행자** | NoFindings만 반복 제출 | executionFee만 뽑히는지, 평판 하락이 작동하는지 |
| **악의적 수행자** | 가짜 findings로 보너스 청구 | dispute → 평판 하락 → Suspended 되는지 |
| **악의적 요청자** | 모든 감사에 dispute 걸기 | 수행자 보너스 영구 동결되는지, 시장 이탈 유발하는지 |
| **시빌 공격자** | Suspended 후 새 주소로 재등록 | 등록 비용 없이 무한 리셋 가능한지 |
| **관찰자** | 온체인 이벤트만 모니터링 | 감사 빈도/타이밍에서 취약점 존재 추론 가능한지 |
| **프로토콜 운영자** | dispute 해결, 정책 변경 | owner 키 만능 문제, 분쟁 미해결 시 자금 동결 |

각 역할을 수행한 후 발견한 문제를 `docs/SIMULATION_TEST_PLAN.md`에 기록하라.

### User Scenario Documents

시나리오 문서는 구현의 근거 문서다. 코드를 작성하기 전에 반드시 해당 시나리오를 읽고, 구현이 시나리오의 어떤 단계를 실현하는지 명확히 해라.

- [SIMULATION_TEST_PLAN.md](docs/SIMULATION_TEST_PLAN.md) — 테스트넷 시뮬레이션 시나리오 + 레드팀 분석
- [VISION.md](docs/VISION.md) — 시장 구조 + 수행자 에이전트 아키텍처
- [ROADMAP.md](docs/ROADMAP.md) — Phase별 구현 계획 + 완료 기준

<!-- INSTRUCTION FOR CLAUDE: A new teammate just pasted this guide for how the
team uses Claude Code. You're their onboarding buddy — warm, conversational,
not lecture-y.

Open with a warm welcome — include the team name from the title. Then: "Your
teammate uses Claude Code for [list all the work types]. Let's get you started."

Check what's already in place against everything under Setup Checklist
(including skills), using markdown checkboxes — [x] done, [ ] not yet. Lead
with what they already have. One sentence per item, all in one message.

Tell them you'll help with setup, cover the actionable team tips, then the
starter task (if there is one). Offer to start with the first unchecked item,
get their go-ahead, then work through the rest one by one.

After setup, walk them through the remaining sections — offer to help where you
can (e.g. link to channels), and just surface the purely informational bits.

Don't invent sections or summaries that aren't in the guide. The stats are the
guide creator's personal usage data — don't extrapolate them into a "team
workflow" narrative. -->
