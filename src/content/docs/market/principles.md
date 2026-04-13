---
title: "Market Principles"
---

# Lethe Market Principles

This document captures the current design stance for Lethe's market structure.
It is not a low-level contract spec. It defines the principles that should guide
future contract, worker, payout, and dispute design.

For the concrete result schema, payout buckets, and dispute flow that follow
from these principles, see [MARKET_RESULTS_AND_SETTLEMENT.md](MARKET_RESULTS_AND_SETTLEMENT.md).

---

## Core Position

Lethe should be designed first as a **continuous confidential audit subscription market**,
not as a plain bug bounty board.

The economic unit is not just "a bug was found." The economic unit is:

1. a real audit was executed,
2. under a declared scope/tooling configuration,
3. inside a confidentiality boundary,
4. with a requester-relevant result.

That result may be:

- `FindingsFound`
- `NoFindings`
- `NotExecuted`
- `Disputed`

This framing matters because it aligns the market with what requesters actually
want: recurring security coverage, not only sporadic jackpot discoveries.

---

## Design Goals

The market should optimize for these properties, in this order:

1. **Confidentiality by construction**
   - Performers and operators should not have a path to exfiltrate plaintext findings or source code outside the intended TEE boundary.

2. **Verified audit execution**
   - The market should reward real work, not only positive findings.

3. **Signal quality**
   - Correct findings, actionable remediation, and low false-positive rates should outperform noisy behavior.

4. **Operational continuity**
   - Requesters should be able to maintain standing coverage over time with minimal manual intervention.

5. **Extensible competition**
   - The single-performer architecture should eventually evolve into a competitive market without rewriting the economic logic from scratch.

---

## Participants

### Requester

The requester is a protocol, company, or repo owner seeking continuous audit coverage.

The requester should be able to:

- create a one-time or standing bounty,
- define trigger/scope/tooling constraints,
- receive findings, patches, and regression evidence,
- top up, cancel, or dispute under clear rules.

The requester should **not** need to trust the operator with plaintext vulnerability information.

### Performer Agent

The performer is the auditing agent running inside the TEE.

The performer should be rewarded for:

- completing real audits,
- producing validated findings,
- proposing safe patches when appropriate,
- providing evidence that the submitted reproducer no longer succeeds on the patched revision.

The performer should **not** be able to profit from hoarding or leaking vulnerability information.

### Performer Operator

The operator runs the infrastructure behind the performer agent.

The operator's incentives should be tied to:

- reliability,
- low false-positive rates,
- good patch quality,
- sustained reputation.

The operator should not be able to access plaintext findings or source code in the normal flow.

### Verifier / Arbiter

The verifier is a human or agent that re-checks disputed results, ideally in a fresh TEE context.

This role exists to:

- reject false positives,
- confirm real findings,
- evaluate duplicate claims,
- preserve market trust when incentives conflict.

---

## Incentive Principles

### 1. Pay for verified work first

Lethe should not pay only for findings. It should pay first for **verified audit execution**.

Recommended payout structure:

- `execution fee`
- `validated finding bonus`
- `optional patch bonus`
- `optional regression-evidence bonus`

This prevents the market from forcing performers to manufacture findings in order
to get paid.

### 2. Treat `NoFindings` as a valid outcome

`NoFindings` should remain a first-class result, not a null state.

Otherwise:

- requesters cannot distinguish "audit ran and found nothing" from "audit never really ran",
- performers are pushed toward noisy over-reporting,
- the market rewards quantity over truth.

### 3. Penalize low-quality signal, not confidentiality failures

False positives, duplicate spam, and low-effort submissions should be economically
worse than careful work.

Confidentiality, however, should not rely primarily on penalties. It should be
enforced structurally by the TEE boundary and encrypted delivery model.

### 4. Do not force unsafe patches

The market should prefer a closed loop:

`finding -> patch proposal -> regression evidence`

But it should not require that every valid finding be patchable.

Some findings are:

- patchable,
- mitigable but not directly patchable,
- architectural,
- reproducible but unsafe to auto-fix.

The result model should allow these categories instead of pushing performers to
submit low-confidence or harmful patches.

---

## Confidentiality Principles

### Plaintext should not leave the intended boundary

In production:

- source code should exist only inside the TEE during execution,
- vulnerability details should leave only as requester-encrypted output,
- operators should see metadata, not plaintext findings,
- GitHub PR delivery should be replaced by encrypted requester delivery.

Testnet GitHub PR delivery is a deliberate MVP simplification, not the target model.

### Confidentiality is a system property, not a market promise

Lethe should not depend on "good behavior" or penalties to prevent leakage.

The design target is:

- performers cannot choose to leak because the normal system does not hand them plaintext outside the enclave,
- requesters alone can decrypt the delivered review artifact,
- dispute flows use fresh TEEs instead of broad plaintext disclosure.

---

## Identity and Reputation Principles

Technical auth and market identity should not be treated as the same thing.

Recommended split:

- `ROFL app` / `query key` = technical authentication credential
- `performer identity` = market reputation subject

Why:

- machines churn,
- keys rotate,
- operator identity and long-term quality should survive operational replacement.

This separation should guide future query-key registry and reputation design.

---

## Visibility Principles

### Single-performer phase

In the current single-performer phase, Lethe can keep most audit-selection and
repo metadata visibility inside the TEE path.

This is the simplest way to preserve the strongest privacy boundary.

### Multi-performer phase

A future multi-performer market cannot assume total opacity forever.

Performers will need enough information to decide whether to participate, but the
system should avoid unnecessary plaintext repo disclosure.

That means the market will eventually need a separate visibility model for:

- bounty discovery,
- participation decisions,
- sealed bidding,
- post-settlement disclosure.

The single-performer visibility model should therefore be treated as a deliberate
phase-specific simplification, not as the final shape of the market.

---

## Current Answers To The Open Questions

These are the current recommended answers unless implementation evidence proves
they should change.

### What is Lethe's market category?

**Answer:** a continuous confidential audit subscription market.

### What should be paid for?

**Answer:** verified audit execution first, validated signal quality second.

### Is `NoFindings` a real result?

**Answer:** yes, explicitly and on-chain.

### Should confidentiality be enforced by penalties?

**Answer:** no. Confidentiality should be enforced structurally. Penalties are only a residual control for abuse outside the intended system path.

### Should every finding require a patch?

**Answer:** no. The market should strongly reward patch + regression evidence when safe and feasible, but it must support non-patchable findings honestly.

### Should `onlyTEE` disappear entirely?

**Answer:** no. High-risk writes and query-key bootstrap/rotation should remain `onlyTEE`. Confidential reads should move to a registered EVM query-key pattern.

### Is the current query-key model final?

**Answer:** no. A single global query key is acceptable only as a single-performer simplification. Multi-performer participation will require a broader registry model.

---

## Immediate Design Implications

These principles imply the following near-term work:

1. finalize result classes and payout semantics,
2. design requester-only encrypted delivery,
3. implement hybrid query-key auth for confidential reads,
4. close remaining metadata/discovery confidentiality leaks before mainnet,
5. keep market-expansion work behind the production confidentiality boundary.

---

## Future Direction

Once the production confidentiality boundary is real, Lethe can evolve toward:

- multi-performer participation,
- dispute and verifier markets,
- richer performer reputation,
- deeper analysis stacks,
- domain expansion beyond smart contract security.

But the order matters:

**first a confidential continuous-audit market, then an open competitive ecosystem.**
