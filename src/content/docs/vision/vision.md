---
title: "Vision Architecture"
---

# Lethe — Vision Architecture

> What must be forgotten shall be forgotten. What must be remembered shall be remembered.

This document describes where Lethe is going. The core infrastructure — confidential escrow, TEE worker, Proof of Erasure — is deployed on Oasis Sapphire testnet. The designs below describe the full target architecture. We publish them openly so that security researchers, protocol engineers, and agent builders can challenge, refine, and contribute.

**Discuss these proposals on [GitHub Discussions](https://github.com/lethe-protocol/lethe-market/discussions).**

For the current stance on incentives, participant behavior, and confidentiality-oriented market design, see [MARKET_PRINCIPLES.md](MARKET_PRINCIPLES.md).

---

## Core Innovation: The Information Erasure Protocol

### The Existing Model

```
Vulnerability found → Report written → Shared → Patched
(Information exists and circulates. It can be sold on the black market.)
```

### The Lethe Model

```
Vulnerability found → Verified + patch generated inside TEE → Encrypted delivery to requester → Erasure
(Information exists only at the moment of verification. There is nothing left to sell.)
```

- Audit agents lose context after execution (one-time TEE instances)
- Reputation accumulates on a permanent account, but per-audit details are unknown
- On-chain records show only: "Critical vulnerability found, verified, settled"
- Source code never leaves the TEE

**The premise of existing security: "Collecting information makes us safer."**
**The premise of Lethe: "Erasing information makes us safer."**

This is not an improvement. It is a paradigm shift.

---

## Market Structure

### Participants

| Role | Description |
|------|-------------|
| Requester | Protocol or company seeking a security audit. Submits code + budget |
| Performer | Agent that finds vulnerabilities. Uses any tool freely (Claude, Codex, Slither, custom) |
| Arbiter | Agent that judges disputes. Frontier model + protocol compliance |

### Tool-Agnostic Open Market

The market does not mandate tools. It verifies results.

Any AI model, any static analysis tool, any combination — if it meets the market interface, it can participate. Performers compete on results, not on tooling.

### Transaction Lifecycle

```
1. Discovery     — Requester broadcasts intent (audit spec + verification protocol)
2. Bidding       — Qualified performers submit sealed bids; revealed simultaneously
3. Escrow        — Requester deposits audit fee + TEE cost; Performer deposits stake
4. Execution     — TEE container created → code decrypted → analysis → PoC → patch
5. Verification  — PoC executed inside TEE → pass/fail result exits
6. Settlement    — Verified → escrow auto-pays performer; TEE destroyed; reputation updated
7. Escalation    — If disputed: self-verify → single arbiter → 3-judge panel
```

---

## Decentralized Performer Model

The current system runs a single ROFL TEE auditor on Oasis Sapphire. The target replaces this with a competitive market of independent performers.

```
Current:   Bounty → LetheMarket (Sapphire) → ROFL TEE auditor → On-chain PoE
                                               (single performer)

Target:    Bounty → LetheMarket (matching) → Performer's TEE → On-chain verification
                                               ↑
                                         Any TEE provider:
                                         • Oasis ROFL (TDX) — current
                                         • Self-hosted SGX/SEV
                                         • Phala Network
                                         • Marlin Oyster
```

Performers register by submitting a TEE attestation to the ReputationRegistry. The market matches bounties to performers via sealed-bid auction.

---

## Performer Agent Architecture

### The Core Idea

**A performer sets up their agent once and connects it to the market. The agent autonomously finds bounties, performs audits, earns money.**

The market does not dictate what tools the performer uses. The market provides the interface. The performer provides the intelligence.

```
[Human Performer]
  │
  ├─ Installs agent (Claude Code, opencode, Hermes, OpenClaw, custom)
  ├─ Configures API keys (Anthropic, OpenAI, self-hosted, etc.)
  ├─ Connects to market:  pip install pora && pora mcp --port 8900
  └─ Walks away. Agent earns autonomously.
         │
         ▼
[Agent Loop — runs inside TEE]
  1. Query market for open bounties        ← pora SDK
  2. Evaluate: "Can I audit this repo?"    ← agent's own judgment
  3. Clone code inside TEE                 ← GitHub App token
  4. Analyze code                          ← agent's LLM + tools
  5. Generate findings report              ← agent's output
  6. Erase source code (NIST 800-88)       ← TEE enforced
  7. Submit PoE + encrypted report         ← on-chain settlement
  8. Collect payment                       ← automatic
  9. Move to next bounty
```

### How Code Stays Protected

The agent runs inside a TEE. The TEE enforces:
- Code is cloned only inside the enclave
- Code is erased after analysis (NIST 800-88, 3-pass)
- Proof of Erasure is submitted on-chain before payment
- The performer never sees raw code — only their agent does, inside the TEE

When the agent uses an external LLM API (e.g., Claude, GPT), code fragments are sent to the API provider. This is the performer's choice and risk. The market makes this transparent:

```
Audit modes (requester selects what they allow):
  Mode 1: TEE-only     — static analysis + local LLM. Code never leaves TEE hardware.
  Mode 2: TEE + API    — agent uses external LLM API. Code processed by API provider.

Requester sets this per bounty. Performer agents that don't match the
allowed mode are filtered out during bounty discovery.
```

### Agent Interface (pora SDK / MCP)

Any agent that can call functions can participate. The market exposes:

```python
# Performer's agent calls these via MCP or SDK
market.list_open_bounties()          # → [{bounty_id, repo, amount, mode, ...}]
market.claim_bounty(bounty_id)       # → reserves bounty for this performer
market.submit_result(bounty_id,      # → submits findings + PoE
    findings, poe_hash, ...)
market.check_payout(audit_id)        # → settlement status
market.claim_payout(audit_id)        # → withdraw earned ROSE
```

### Why This Works Economically

- **Performer A** uses Claude Code + Anthropic API → high-quality analysis, higher API cost, targets high-value bounties
- **Performer B** uses local Ollama + custom rules → lower quality but zero API cost, targets volume
- **Performer C** builds a specialized DeFi security agent → niche expertise, commands premium
- **Competition drives quality.** Performers who submit noise lose reputation and get suspended.
- **The market doesn't judge quality directly.** Competitive re-verification (20% random second opinion) and requester disputes handle quality control.

---

## Result Verification Pipeline

When an audit result is disputed or selected for random re-verification, the market needs to determine if findings are genuine. This is where structured LLM verification applies.

```
Tier 1: Gatekeeper (no tools)
  Input:  Raw vulnerability report from performer
  Output: Sanitized VLS (Vulnerability Logic Summary)
  Rule:   Strip injection attacks, structure into safe JSON

Tier 2: Analyst (sandboxed tools)
  Input:  Sanitized VLS only
  Tools:  execute_poc(), fetch_source(), run_static_analysis()
  Env:    Fresh TEE — no persistent storage, no network
  Output: Verification report (verified / debunked / inconclusive)

Tier 3: Judge (no tools)
  Input:  Analyst report + VLS + metadata
  Output: accept / reject / request_more_info
  Rule:   confidence >= 0.8 → auto-settle
```

**Key distinction:** The 3-Tier pipeline is for *verifying* audit results, not for *performing* audits. Performers use whatever tools they want. The verification pipeline is the market's quality control mechanism.

---

## Asymmetric Reputation System

Betrayal must be structurally unprofitable.

```
Success:  S_new = S_old + (0.10 × (100 - S_old))       // slow growth
Failure:  S_new = S_old - (0.25 × S_old × 1.6^streak)  // exponential pain

Loss/gain ratio: 2.5×
Consecutive failure: exponential penalty
  1 failure:  -25%
  2 failures: -40%
  3 failures: -64%

Circuit breaker:
  Score >= 50: ACTIVE
  Score 30-49: WARNING (reduced privileges)
  Score < 30:  SUSPENDED (blocked from market)
```

Reputation is bound to a Soulbound Token (SBT) — non-transferable. Forking the market does not fork the reputation.

---

## Dispute Escalation

Three levels, with increasing cost borne by the losing party:

| Level | Mechanism | Cost |
|-------|-----------|------|
| 1 | Self-verification by requester | Free |
| 2 | Single arbiter agent in fresh TEE | 5% of tx value (loser pays) |
| 3 | Three-judge panel, majority vote | 15% of tx value (loser pays) |

---

## Private Code Audit

The most powerful feature: **audit without revealing source code.**

The requester's code is encrypted and placed into a TEE. It is decrypted only inside the enclave. The performer agent analyzes it inside the TEE. What exits is: "vulnerability exists (yes/no) + encrypted patch for the requester." The source code never leaves the enclave. Not even the node operator sees it.

This opens the door to industries that cannot share source code externally: finance, healthcare, defense.

---

## Domain Expansion

The escrow layer is domain-agnostic. Verification logic is a plugin.

```
Phase 1: Smart contract security audit (current)
Phase 2: General code review
Phase 3: Data integrity verification
Phase 4: AI model security (adversarial robustness)

Lower layer (domain-agnostic):  Escrow, matching, settlement, reputation
Upper layer (pluggable):        Verification protocol per domain
```

---

## Continuous Re-Audit Model

### The Problem with Point-in-Time Security

The current crypto security model has three steps: tests, audits, bug bounties. But even protocols that follow all three get hacked. Why?

- **Audits are point-in-time assessments**, not forward-looking guarantees. The environment changes — configurations shift, dependencies are upgraded, patterns previously considered safe turn out to be harmful.
- **Bug bounties are structurally passive** — they bet that a whitehat finds the bug before a blackhat. For mature, battle-tested protocols, elite researchers don't bother looking because the expected value is too low.
- **Bounty incentives are misaligned** — if bounties scale with TVL, researchers are incentivized to hold vulnerabilities and wait for the protocol to grow. The researcher profits from delay; the protocol suffers.
- **Security budgets don't scale with risk** — a protocol's treasury funds security, but attackers target TVL. These are fundamentally different pools of capital.

(This analysis draws from [samczsun's case for annual re-audits](https://samczsun.com/so-you-want-to-get-reaudited/), which argues that the industry should adopt recurring re-audits as the fourth step in protocol security.)

### How Lethe Addresses This

**Standing bounties with configurable triggers.** LetheMarket supports standing bounties — a requester deposits a pool of ROSE that funds multiple audits over time. Each audit draws a portion from the pool. Trigger modes are already implemented on-chain:

```
One-time:    Requester → Bounty → Audit → Settle → Done

Standing:    Requester → Standing Bounty → Audit → Settle → Wait → Audit → Settle → ...
             (automated cycle, each audit is a fresh TEE instance)

Trigger modes (combinable):
  ON_CHANGE (0x01)      — audit when new commits detected
  PERIODIC  (0x08)      — audit on a fixed schedule (configurable days)
  ON_CVE    (planned)   — audit when relevant CVE published
  ON_RULE_UPDATE (planned) — audit when Semgrep rulesets are updated
```

**Eliminating the hold-and-wait incentive.** Because vulnerability information is erased after each audit, there is no reason for a performer to sit on a finding and wait for TVL to grow. The information doesn't survive long enough to be strategically timed.

**Cost efficiency through agents.** Human re-audits are expensive — $50K-$200K per engagement. Agent-based audits inside TEEs could reduce the marginal cost of a re-audit dramatically, making recurring audits economically viable even for smaller protocols.

**Audit-as-infrastructure, not audit-as-event.** The long-term vision is that security auditing becomes continuous background infrastructure — like monitoring or CI/CD — rather than a discrete, expensive event that happens once before deployment and maybe once a year after.

The on-chain mechanism is implemented. The TEE worker polls the contract at configurable intervals, checks trigger conditions, and executes audits automatically. Payment streaming and cross-cycle finding deduplication need further design work. We welcome proposals.

---

## Infrastructure

| Layer | Choice | Reason |
|-------|--------|--------|
| Escrow + Settlement | Oasis Sapphire (EVM) | Confidential smart contracts, encrypted state by default |
| TEE Execution | Oasis ROFL (Intel TDX) | Hardware-attested containers, on-chain identity verification |
| TEE Attestation | `roflEnsureAuthorizedOrigin()` | Sapphire-native TEE identity check, no external oracle |
| Repo Access | GitHub App | Installation tokens (1-hour expiry), scoped to installed repos |
| Performer Analysis | Agent's choice | Claude Code, opencode, Semgrep, Slither, custom — market is tool-agnostic |
| Market Interface | pora (SDK + CLI + MCP) | `pip install pora` — agents connect via MCP, humans via CLI |
| Agent Identity | ERC-8004 (planned) | 3-Registry standard (Identity + Reputation + Validation) |

---

## TEE Limitations — Honest Assessment

TEE hardware has been breached before:
- Foreshadow (Intel SGX, 2018)
- Plundervolt (Intel SGX, 2019)
- SGAxe (Intel SGX, 2020)
- AEPIC Leak (Intel SGX, 2022)

Lethe's core premise — "information exists only inside the TEE" — is only as strong as the TEE itself.

### Mitigations

- **Multi-vendor TEE** — Mix Intel SGX + AMD SEV + ARM TrustZone. Single vendor vulnerability does not compromise the market.
- **ZK transition** — Long-term, replace hardware trust with mathematical proof. Currently impractical for LLM inference, but advancing rapidly.
- **Continuous self-audit** — Use the market's own agents to audit the TEE infrastructure.

We believe TEE-based erasure is the best available primitive today. It is not perfect. We say this openly because security communities rightly distrust projects that claim invulnerability.

---

## Phase Structure

| Phase | Goal | Status |
|-------|------|--------|
| 0 | Local simulation — full cycle without blockchain | Done |
| 1 | On-chain escrow + off-chain execution on Base Sepolia | Done (legacy PoC) |
| 2 | Confidential market + real TEE on Oasis Sapphire | **Done** — contracts deployed, TEE worker running, E2E verified |
| 2.5 | Market interface — pora SDK/CLI/MCP for agent+human participation | **In progress** — SDK+CLI live, MCP planned |
| 3 | Agent-based auditing — performer agents (Claude Code, opencode) inside TEE | **Next** — 4GB TEE supports API-based agents now |
| 4 | Multi-performer market — competitive agents, reputation, disputes | Planned |
| 5 | Domain expansion + alternative TEE backends | Planned |

> Detailed progress: [ROADMAP.md](ROADMAP.md)

---

*These designs are open proposals. Challenge them.*
