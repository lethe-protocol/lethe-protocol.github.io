---
title: "Evolution Strategy"
---

# Lethe Evolution Roadmap

Last updated: 2026-04-13

---

This document is the product of three rounds of structured multi-perspective debate. Six specialists — technical architect, security researcher, mechanism designer, legal analyst, adversarial red team, and ethics challenger — independently analyzed Lethe's evolution path. The vision holder made binding decisions on all contested points.

**Fixed constraint: "Vulnerability information is destroyed after verification." This is the vision. It does not change. If laws don't accommodate it, laws must evolve.**

Companion documents:

- [ROADMAP.md](ROADMAP.md) — operational progress tracker (testnet state, blockers, verification history)
- [VISION.md](VISION.md) — target architecture and long-term direction
- [MARKET_PRINCIPLES.md](MARKET_PRINCIPLES.md) — incentive design and market stance
- [ENCRYPTED_DELIVERY_ARCHITECTURE.md](ENCRYPTED_DELIVERY_ARCHITECTURE.md) — delivery system design
- [OASIS_ROFL_BLOCKERS.md](OASIS_ROFL_BLOCKERS.md) — upstream blockers
- [decisions/](decisions/) — Decision Records from structured debate

---

## Decision Records

| DR | Title | Status |
|----|-------|--------|
| [DR-001](decisions/DR-001-poe-to-poc.md) | Vision is fixed. PoE is core identity. | Decided |
| [DR-002](decisions/DR-002-findingcount-removal.md) | Remove findingCount from on-chain events | Decided |
| [DR-003](decisions/DR-003-competitive-verification.md) | Competitive verification over reputation as primary quality mechanism | Decided |
| [DR-004](decisions/DR-004-subscription-payment-model.md) | Transition from geometric decay to subscription payment | Decided |
| [DR-005](decisions/DR-005-immediate-security-fixes.md) | Immediate security fixes — P0/P1/P2 | Decided |
| [DR-006](decisions/DR-006-premise-dependency-graph.md) | Premise dependency graph — optimal evolution sequence | Decided |

---

## The Vision

> "When the finder forgets but the fixer remembers, the attack surface shrinks to zero."

Lethe destroys the auditor's copy of vulnerability information after verification. The requester receives findings + patches via encrypted delivery. What is erased is the intermediary's retention — not the requester's knowledge. The ecosystem learns through ruleset updates, not through sharing specific vulnerability instances.

This is not information destruction. It is **information sovereignty recovery** — vulnerability details belong to the code owner, not to the auditor.

---

## Premise Dependency Graph

The optimal evolution sequence, derived from 6-specialist debate with unanimous agreement on ordering:

```
IMMEDIATE (no dependencies, parallel execution):
  ■ Semgrep multi-language ruleset expansion .............. [1 week]
  ■ Terms of Service + liability disclaimers .............. [legal counsel]
  ■ Remove findingCount from events (DR-002) .............. [1-2 weeks]
  ■ Bundle Semgrep rules in container image ............... [2-3 days]
  ■ Remove sensitive fields from delivery manifest ........ [2-3 days]

SHORT-TERM (1-3 months):
  ■ Repo ownership verification in TEE worker ............. [2-3 weeks]
  ■ Payout calculation moved to contract .................. [4-6 weeks]
  ■ Dispute resolution decentralization — DESIGN .......... [4-6 weeks]
       ↓ unlocks

MID-TERM (3-6 months):
  ■ Dispute resolution — IMPLEMENTATION (P7) .............. [6-8 weeks]
       ↓ makes findingBonus meaningful
       ↓ unlocks multi-performer
  ■ Multi-performer foundation (P2) ....................... [8-12 weeks]
       ↓ requires P7
       ↓ unlocks feedback loops
  ■ ROFL resource expansion — negotiate with Oasis (P1) ... [external]
       ↓ unlocks LLM in TEE

LONG-TERM (6-12 months):
  ■ LLM 3-Tier pipeline in TEE (P3) ...................... [12-16 weeks]
       ↓ requires P1 (16GB+ RAM)
  ■ Utility token — staking + slashing ONLY (P9) ......... [8-12 weeks]
       ↓ requires P2 + P7 operational
       ↓ NO value capture / governance initially
  ■ Feedback loop — metadata only (P10) .................. [6-8 weeks]
       ↓ requires P2 + P7

DEFERRED (12+ months):
  ■ Token value capture / governance ...................... [after market self-sustains]
  ■ Multi-token / stablecoin payments ..................... [after user base]
  ■ Cross-chain payment layer ............................. [after PMF on Sapphire]
```

### Why This Order

**P7 (dispute) before P2 (multi-performer):** Without decentralized dispute resolution, the owner key is a single point of failure for the entire market. findingBonus activation is meaningless if disputes can't be resolved — bonuses get permanently frozen, and performers rationally optimize for executionFee only. (Mechanism designer + security researcher, independently)

**P2 before P9 (token):** Without multi-performer, there's nothing to stake against. Token without market = speculation without utility. P2+P9 simultaneous introduction is "critical risk" — Sybil + token manipulation compound attack. (Red team)

**P3-lite before P3-full:** Multi-language Semgrep ruleset expansion costs 1 week with zero dependencies. LLM requires 16GB+ RAM (P1), which depends on Oasis. Do the cheap win now. (Tech lead)

### Dangerous Combinations

| Combination | Risk | Source |
|------------|------|--------|
| P2 + P9 simultaneous | CRITICAL | Sybil + token manipulation |
| P1 + P2 simultaneous | CRITICAL | LLM non-determinism + multi-performer = dispute explosion |
| P2 + P9 + P7 simultaneous | CRITICAL | Governance attack monopolizes disputes |

**Rule: Validate each premise change before starting the next.**

---

## Immediate Security Fixes (DR-005)

These block any production deployment. No feature work until resolved.

### P0 — Must fix (0-4 weeks)

1. **Remove result metadata from on-chain events.** `AuditSubmitted` and `AuditResultSubmitted` currently emit `findingCount`, `findingOutcome`, `remediationOutcome` in plaintext. Enables zero-cost reconnaissance. Fix: events emit `(auditId, bountyId)` only.

2. **Remove sensitive fields from delivery manifest.** `resultType` and `findingCount` in plaintext manifest. Fix: move inside encrypted envelope.

3. **Bundle Semgrep rules in container image.** Network-fetched rules = supply chain attack vector. Fix: local path + `--metrics=off`.

### P1 — Fix within 3 months

4. **Repo ownership verification.** Anyone can create bounty for any repo. Fix: TEE worker verifies requester is repo collaborator via GitHub API.

5. **Payout calculation in contract.** Worker currently decides its own payout. Fix: worker submits result tuple only, contract computes payout from PayoutPolicy.

### P2 — Fix within 6 months

6. **Connect ReputationRegistry to LetheMarket.** Currently zero integration. Fix: call `recordSuccess`/`recordFailure` from audit submission and dispute resolution.

7. **Activate findingBonus > 0.** Current: all payout as executionFee. Fix: 40% execution / 30% finding / 20% patch / 10% regression. Finding bonus released after challenge window. (Requires P7 to be meaningful.)

---

## Market Mechanism Evolution

### Current State (single-performer, testnet)

```
Requester → createBounty(ROSE) → ROFL TEE audits → 
  findings + patch encrypted to requester → source code erased → PoE on-chain
```

Working. Verified E2E on Sapphire testnet.

### Target State (competitive market)

```
Requester → createBounty(ROSE/stablecoin) → 
  Multiple performers sealed-bid → Winner audits in TEE →
  Result submitted (contract computes payout) →
  Random 20% get second-opinion verification →
  Dispute? → Fresh TEE re-verification (not onlyOwner) →
  Reputation updated → Findings + patch encrypted to requester → Erasure → PoE
```

### Key Mechanism Decisions

**Payout structure** (DR-004, mechanism designer):
```
executionFee:     40% — paid for verified execution regardless of result
findingBonus:     30% — released after challenge window
patchBonus:       20% — for safe, applicable patches
regressionBonus:  10% — for regression evidence
```

**Quality assurance** (DR-003): Competitive verification with probabilistic sampling (20% random second opinion). Reputation is supplementary signal, not primary mechanism. `slashAmount > 5 × (C_audit - C_submit)` ensures honest auditing is dominant strategy.

**Payment model** (DR-004): Transition from geometric decay (10% of remaining pool) to fixed per-audit fee. "Standing bounty" renamed to "audit credit pool." Remaining credits visible on-chain.

---

## Legal Strategy

### Jurisdictional Approach (legal analyst)

| Tier | Jurisdictions | Confidence | Strategy |
|------|--------------|------------|----------|
| 1 | Switzerland, Singapore, ADGM | High | Immediate operation. Regulatory sandbox. |
| 2 | UK, South Korea | Medium | FCA/KISA sandbox. Conditional on legal review. |
| 3 | US, EU | Low (initially) | Serve customers, but entity + escrow outside. |

### Key Legal Arguments

1. **Lethe destroys the auditor's copy, not the requester's.** The requester retains findings + patches and can fulfill any reporting obligations (NIS2, CRA).
2. **PoE aligns with GDPR data minimization** (Article 5(1)(c)). Unnecessary retention of vulnerability information is itself a security risk.
3. **"Audit" terminology creates implied warranty risk.** Terms of Service must define scope as "automated security analysis," not professional assurance.

### Regulatory Change Advocacy

- Propose TEE-based erasure standard to NIST (extending SP 800-88)
- Join Confidential Computing Consortium (Linux Foundation)
- Submit NIS2 implementation guidance: "auditor vulnerability retention minimization"
- Publish legal scholarship: "Information Erasure as Security"

---

## MANIFESTO Strengthening

From ethics challenger's analysis (v2), with vision holder approval:

### Precision improvements (vision unchanged, articulation strengthened)

**Current:** "Erasing information makes us safer."
**Strengthened:** Keep, and add: *"When the finder forgets but the fixer remembers, the attack surface shrinks to zero."*

**Current:** "After the audit, no one holds the vulnerability."
**Corrected:** *"After the audit, no intermediary holds the vulnerability. Only the code owner receives the finding, encrypted and paired with a patch. The information returns to where it belongs — and nowhere else."*

### New section: Ecosystem Immunity

> Individual vulnerability details are erased. But the patterns that produce vulnerabilities are not. Each audit cycle feeds back into detection rulesets. A reentrancy bug found in Protocol A doesn't survive as "Protocol A's function X is vulnerable" — it survives as "this reentrancy pattern is dangerous," which then protects Protocol B, C, and D without ever exposing A's specifics. The ecosystem learns the lesson without anyone holding the weapon.

### Structural evils this vision resolves (ethics challenger)

1. **Auditor-Vulnerability Arsenal** — Large audit firms accumulate thousands of unpatched vulnerability details. One breach = thousands of protocols exposed. Lethe: auditor retains nothing.
2. **Vulnerability Timing Attack** — Researchers hold findings until TVL grows. Lethe: information doesn't survive long enough to be timed.
3. **Regressive Audit Cost** — $50K-$200K per audit excludes small protocols. Lethe: agent-based continuous audit at 1/100th cost.
4. **Forced Code Disclosure** — "Give us your code to get audited" = security paradox. Lethe: code never leaves TEE.

---

## Risk Register

### Platform Risk: Oasis Dependency

Two active upstream blockers (`oasisprotocol/cli#694`, `oasis-sdk#2223`). ROFL resource limit (4GB/2vCPU) blocks LLM path. Mitigation: extract `AppdClient` to Protocol interface, evaluate alternative TEE platforms (Phala, Marlin, self-hosted TDX) within 8-12 weeks if Oasis doesn't provide resource expansion roadmap.

### Security Risk: Owner Key Single Point of Failure

`resolveAuditDispute` is `onlyOwner`. Owner key compromise = total market fund theft. Mitigation: P7 (dispute decentralization) is the highest-priority structural change. Interim: multisig for owner, timelock on critical functions.

### Market Risk: Analysis Quality Ceiling

Semgrep-only analysis limits market credibility. Known patterns only. Mitigation: immediate multi-language ruleset expansion (1 week), LLM integration after ROFL resource expansion.

### Adoption Risk: Zero Users

No frontend. Manual `cast send` for bounty creation. Mitigation: Terms of Service preparation (immediate), GitHub Action / CLI tool (short-term), web dashboard (mid-term).

### Regulatory Risk: PoE Legal Status

Not tested in any jurisdiction. Mitigation: Switzerland/Singapore/ADGM regulatory sandbox entry. GDPR alignment as positive framing. Legal counsel before first paying customer.

---

## 12-Month Milestones

| Quarter | Milestone | Risk |
|---------|-----------|------|
| **Q1** | P0 security fixes + retrieval CLI + multi-language Semgrep + ToS + challenge window live validation | Low — most code exists |
| **Q2** | Dispute resolution design + implementation + payout contract migration + first 5 users (white-glove) | Medium — contract restructure |
| **Q3** | Multi-performer foundation (2+ independent auditors) + ROFL resource expansion + external contract audit | High — Oasis dependency + audit timeline |
| **Q4** | LLM 3-Tier pipeline + competitive verification live + monthly 50+ audits | High — market bootstrap |

---

## What We Explicitly Defer

| Item | Why | Revisit When |
|------|-----|-------------|
| Own token | Existential regulatory risk. No network effects to tokenize yet. | Multi-performer market operational |
| Token governance | Governance capture risk with small token supply | Market self-sustaining at $50K+ MRR |
| Multi-chain | Sapphire confidentiality is non-negotiable for TEE attestation | After PMF on Sapphire |
| Full feedback loop | Conflicts with PoE — requires "erasure-retention boundary" design | After P7 + P2 operational |
| Domain expansion | Core audit market not yet proven | After $1M+ ARR |

---

## Debate Process

This roadmap was produced through three rounds of structured debate:

**Round 1 (v1):** Assumption mapping → blind spot forcing → counterfactual scenarios. Produced DR-002 through DR-004. Initial DR-001 suggested vision compromise — rejected by vision holder.

**Round 2 (v2):** Vision-fixed exploration. "What can this vision achieve?" Produced corrected DR-001, DR-005, MANIFESTO strengthening. Key reframe: Lethe's innovation is not "destruction" but "information sovereignty recovery."

**Round 3 (v3):** Premise change exploration. "What becomes possible when constraints change?" Produced DR-006 (dependency graph). Key finding: P7 (dispute resolution) is the hidden highest-leverage premise — it gates P2 (multi-performer), which gates P9 (token), which gates the full market.

Each Decision Record contains the tension (who argued what), rejected alternatives (what was not chosen and why), and reopen conditions (what would change this decision).

---

*"What must be forgotten shall be forgotten. What must be remembered shall be remembered."*
