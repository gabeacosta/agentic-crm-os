# Agentic CRM OS

![Status](https://img.shields.io/badge/status-schema_%2B_state_machine-4169E1?style=flat-square) ![Postgres](https://img.shields.io/badge/Postgres-16-4169E1?style=flat-square&logo=postgresql&logoColor=white) ![Tests](https://img.shields.io/badge/tests-passing-22c55e?style=flat-square)

A multi-tenant lead lifecycle schema for PostgreSQL, plus `fn_transition_lead()` — a state-machine function that uses `SELECT ... FOR UPDATE` row locking so concurrent callers transitioning the same lead serialize instead of racing.

**What this is**: 13 SQL migrations (schema) + one PL/pgSQL function (state machine) + a test suite that checks the transition rules and audit-trail writes. No application server, no API layer — this is the data-layer pattern extracted from a production real-estate lead pipeline, not the pipeline itself.

## The problem `fn_transition_lead()` solves

Two events can race to transition the same lead — a voicemail-drop webhook and a live-call-ended webhook both firing for the same lead within milliseconds, for example. Without a lock, both read the same starting status, both validate against it, and the second write silently clobbers the first (a lost update). `fn_transition_lead()` takes the row lock with `FOR UPDATE` *before* validating the transition, so the second caller blocks until the first commits, then re-validates against the post-commit state — not the stale state it started with.

The lock itself is real and inspectable — see the `FOR UPDATE` clause in `migrations/013_lead_state_machine.sql`. `tests/test_state_machine.sql` currently exercises the sequential cases (valid/illegal/same-status transitions, plus the `events`/`audit_log` writes) against a single connection; it does not yet include an automated two-connection race test proving the lock serializes concurrent callers. That test is still on the list, not shipped.

## Schema

| Table | Purpose |
|---|---|
| `tenants` | Multi-tenant isolation; `plan` constrained to real product tiers (`growth_engine`, `lead_recovery`, `dealiq_internal`) |
| `users` | Tenant-scoped, role-checked (`admin`/`member`/`viewer`) |
| `leads` | Core entity — JSONB for name/property/owner/distress signals, plus the `status` state machine |
| `irelop_scores` | 100-point lead scoring (Motivation/Opportunity/Profile), tiered HOT/WARM/COOL/PASS |
| `jobs` | Async job queue with priority ordering and per-job LLM cost tracking |
| `voice_events` | Call events (Retell/Bland/Vapi) linked to leads, with transcript + score-impact JSONB |
| `llm_cost_log` | Append-only per-call cost/latency log |
| `events` | Immutable event log — every state transition lands here |
| `audit_log` | Immutable audit trail for user + system actions |
| `api_keys` | bcrypt-hashed keys, prefix stored separately for log-safe identification |
| `kill_switch` | Global/tenant/service circuit breaker |

## Lead lifecycle

```
new → contacted → qualified → offer_made → negotiating → under_contract → pending_close → closed_won
              ↘ nurturing ↗        ↘ objection ↗                                        ↘ closed_lost
                    ↘ disqualified (from new/contacted/qualified/nurturing/re_engaged)
```

Legal transitions live in `lead_status_transitions` (a data table, not a hardcoded `CASE`) — adding a new transition is a data change, not a migration.

## Try it

```bash
make up        # start Postgres
make migrate   # apply all 13 migrations
make test      # run the state-machine test suite (sequential transition + audit-trail checks)
make psql      # open a shell to poke around
make clean     # tear down + destroy the volume
```

## What's redacted / not included

- No API server — pick your own framework; the schema and function are framework-agnostic.
- `migrations/012_seed_data.sql` uses fictional data (`Acme Realty`, `John Smith`, `example.com`) — replace before real use.
- No production usage numbers are claimed here. This is the pattern; production numbers live in the [portfolio case studies](https://github.com/gabeacosta/ai-portfolio/blob/main/CASE_STUDIES.md) where they're backed by receipts.

---
Part of the [AI Infrastructure Portfolio](https://github.com/gabeacosta/ai-portfolio)
