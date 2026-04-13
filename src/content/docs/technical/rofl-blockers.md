---
title: "ROFL Blockers"
---

# Oasis ROFL Blockers

Last updated: 2026-04-12

This document tracks operational blockers that are below Lethe product logic and currently look like Oasis ROFL / CLI / provider issues.

## Active Blocker: Strict-Mode Rollout Revalidation

### Status

- Lethe product path is working:
  - query-key registration is live
  - signed confidential reads are implemented
  - encrypted delivery MVP is live
  - requester retrieval + webhook delivery are verified end-to-end
- The remaining strict-mode revalidation is blocked by ROFL machine lifecycle drift, not by a known Lethe contract or worker bug.

### Why We Believe This Is External

The same codebase already completed:

- settlement-aware on-chain submission
- encrypted delivery with non-zero `ciphertextHash` and `manifestHash`
- requester-side decryption with `scripts/retrieve_delivery.py`

The remaining failing case is specifically the live operator rollout/replacement path under strict mode.

### Observed Symptoms

- `oasis rofl show --format json` reports active replicas.
- The configured machine pointer still resolves to an expired machine.
- `oasis rofl machine show` shows `accepted (EXPIRED)` for the configured machine ID.
- `oasis rofl machine logs --yes` returns `404 Not Found` for that machine.
- `oasis rofl deploy --replace-machine --yes` does not give a reliable operator-visible signal that a fresh machine was actually rented and started.
- Fresh bounty `#3` on market `0x7796554b460a5c38C28075Ab15EDC0a8fECa8201` remains `Open` while `auditCount()` does not increase.

### Concrete Reproduction Snapshot

At the time of writing:

- Market: `0x7796554b460a5c38C28075Ab15EDC0a8fECa8201`
- Query key registration: non-zero and on-chain
- Encrypted delivery E2E: already verified on bounty `#2`
- Strict-mode fresh validation bounty: `#3`
- `bountyCount() == 3`
- `auditCount() == 2`
- `getBounty(3)` remains `Open`
- Webhook inbox shows no new event for bounty `#3`

### Related Upstream Issues

- `oasisprotocol/cli#694` — active issue for this exact rollout / observability symptom set
  - <https://github.com/oasisprotocol/cli/issues/694>
- `oasisprotocol/cli#487` — expired machine handling for `rofl deploy`
  - <https://github.com/oasisprotocol/cli/issues/487>
- `oasisprotocol/cli#584` — fix crash/regression around `--replace-machine` with expired machine IDs
  - <https://github.com/oasisprotocol/cli/pull/584>
- `oasisprotocol/cli#580` — CLI should more clearly surface expired instance state
  - <https://github.com/oasisprotocol/cli/issues/580>
- `oasisprotocol/oasis-sdk#2223` — documented workaround direction for ROFL signed queries
  - <https://github.com/oasisprotocol/oasis-sdk/issues/2223>
- `oasisprotocol/oasis-sdk#1999` — ROFL query / Sapphire EVM query documentation gap
  - <https://github.com/oasisprotocol/oasis-sdk/issues/1999>

## Filed Upstream Issue

Filed as:

- `oasisprotocol/cli#694`
- <https://github.com/oasisprotocol/cli/issues/694>

Original submission text:

Body:

```md
### Summary

We are seeing a confusing ROFL operational state on testnet:

- `oasis rofl show --format json` reports active replicas
- the configured machine pointer still resolves to a machine that shows `accepted (EXPIRED)`
- `oasis rofl machine logs --yes` for that machine returns `404 Not Found`
- `oasis rofl deploy --replace-machine --yes` does not give us a reliable operator-visible signal that a fresh machine was actually rented and started

This makes it hard to tell whether a new rollout really happened, and it blocks strict-mode validation of our ROFL app.

### Environment

- Oasis testnet
- ROFL app using managed provider flow
- CLI version in active use on 2026-04-12

### Observed behavior

1. `oasis rofl show --format json` shows active replicas.
2. `oasis rofl machine show` for the configured machine ID shows `accepted` but also expired state.
3. `oasis rofl machine logs --yes` returns `404 Not Found`.
4. `oasis rofl deploy --replace-machine --yes` completes, but from the operator point of view we still cannot confidently observe a fresh machine start.

### Expected behavior

One of the following should happen clearly:

- a fresh machine ID is created and surfaced to the operator, with logs available, or
- the CLI should fail closed and state that replace-machine did not converge to a fresh runnable machine

### Why this matters

From the application side, we can see that active replicas exist, but we cannot correlate them to a fresh rollout with accessible logs. That makes rollout validation ambiguous and turns debugging into guesswork.

### Related issues

- oasisprotocol/cli#487
- oasisprotocol/cli#580
- oasisprotocol/cli#584
```

## Local Operator Guidance

Until this is resolved upstream:

- treat `active replicas > 0` and `configured machine pointer is fresh` as separate checks
- do not treat `--replace-machine` success alone as proof of a clean rollout
- fail closed in local automation if the configured machine pointer remains expired after replacement
- keep strict-mode validation blocked unless a fresh startup can be observed or downstream behavior proves the new worker is live
