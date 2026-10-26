# MANOX Premium Product Roadmap

Status: execution plan; completion must be supported by tests or observable evidence.
Baseline: `main` at commit `89b031aa8c5c15fb5588b838e0e531ad2983a8e0` (2026-10-15).
Principle: reliability and safety before feature breadth. Do not label a feature complete because its UI exists.

## Product bar
- Premium visual quality: consistent type scale, spacing, iconography, loading/empty/error states, accessible contrast, touch targets, responsive layouts, restrained motion, and clear navigation.
- Trust: private-by-default sensitive data, explicit permissions, working report/block flows, account deletion, age-appropriate safety, transparent monetization, and auditable withdrawal states.
- Performance: paginated feeds, bounded media preloading, thumbnail-first rendering, cached profile data with invalidation, cancellation/disposal of async work, retry/backoff for transient errors, and offline/network feedback.
- No fake controls: every visible action has an implemented outcome, a disabled reason, or is removed.

## Phase 0 — Establish truth (P0)
1. Record current `main`, open PRs, workflow results, dependency and schema state.
2. Review overlapping Watch/Profile PRs (#16/#17) and media lifecycle PR (#18) before selecting a single coherent implementation; do not blindly merge duplicate work.
3. Re-run formatter, analyzer, unit/widget tests, database tests, and debug APK build from a clean checkout.
4. Make a feature matrix: UI present, backend wired, authorization enforced, failure state handled, test exists, device verified.
Exit gate: reproducible green CI; all failures documented and assigned.

## Phase 1 — Security and data integrity (P0)
- Audit Supabase RLS for every user-owned table; test anonymous, owner, other-user, and privileged paths.
- Verify Storage upload/read/delete policies, content ownership, signed/public URL assumptions, upload limits, MIME/type validation, and orphan cleanup.
- Verify report/block flows affect feeds and interactions server-side, not only UI.
- Review authentication/session expiry, deep links, privacy settings, legal consent, child-safety controls, secrets, and production logging.
- Treat creator earnings as a ledger: idempotent events, server-authoritative balances, immutable transaction records, explicit withdrawal state machine, duplicate-request prevention, audit trail, and KYC/payment-provider compliance before real payouts.
Exit gate: negative authorization tests pass; no client-trusted balance or secret; destructive actions confirmed and recoverable where appropriate.

## Phase 2 — Core app reliability (P0)
Test end-to-end: sign-up/login/logout/password reset; cold start/session restore; feed pagination/refresh; profile edit/view/privacy; follow; like/comment/save/share; notifications; upload/publish/delete; report/block; settings; account deletion.
- Handle loading, empty, error, retry, offline, permission denied, deleted media, expired URLs, and stale sessions.
- Prevent duplicate requests and stale async setState; dispose video controllers; cancel subscriptions; avoid unbounded preloading.
- Add regression tests for each fixed defect and tests for navigation/deep links.
Exit gate: critical journeys pass on Android device/emulator, including poor network and app restart.

## Phase 3 — Premium UX and creator tools (P1)
- Establish shared design tokens and reusable buttons, fields, cards, sheets, dialogs, skeletons, toasts, and empty/error states.
- Simplify navigation and information hierarchy; ensure one-handed touch targets and screen-reader labels.
- Creator Studio: media import, trim/crop/rotate, speed, audio, text/captions, cover selection, draft save/restore, export validation. Only expose tools that truly work.
- Ensure preview/export parity, progress/cancel, memory-safe media processing, and clear storage/performance limits.
- Watch feed: reliable play/pause, mute, progress, next/previous, lifecycle handling, captions/accessibility, and bounded preloading.
Exit gate: visual review on small and large screens; editor/export regression suite passes.

## Phase 4 — Differentiated advanced features (P2; only after gates)
- Creator analytics with explicitly defined metrics and honest data coverage.
- Draft scheduling and publishing controls where platform/API permissions allow.
- Semantic content discovery and user-controlled feed preferences, with privacy-respecting data use.
- AI-assisted captions, clip suggestions, and beat-sync as opt-in tools with user review; disclose limitations and never fabricate analytics.
- Creator marketplace, gifts, monetization and withdrawals only after legal, fraud, abuse, tax/KYC and payment-provider review.
Exit gate: each feature has an owner, cost/latency budget, abuse review, telemetry, rollback plan, and measurable user value.

## Phase 5 — Release readiness (P0)
- Verify package ID, app name/icon, versioning, Android API compatibility, release signing, backup/restore behavior, permissions, deep links, privacy policy, support contact, account deletion URL, Play Data Safety declarations, screenshots, and store listing.
- Run release-mode build and test on real devices; inspect crash/ANR, startup time, memory, upload failures, accessibility, and network resilience.
- Keep secrets out of repo; verify production config separately from debug/test config.
Exit gate: signed AAB verified; store declarations match actual behavior; no open P0 defects; rollback and support process documented.

## Bug prevention routine for every change
1. Reproduce and record the bug or user outcome.
2. Identify root cause and affected flows; inspect current implementation before editing.
3. Make the smallest safe change; avoid unrelated redesign/schema changes.
4. Add a regression test first or alongside the fix.
5. Run formatter, analyzer, relevant tests, database/security tests when applicable, and APK build.
6. Review diff for secrets, permissions, accessibility, loading/error states, and regressions.
7. Open a focused PR with evidence and a manual test checklist.
8. Merge only after checks pass; verify the merged main build and record device-test status.

## Current execution queue
1. Inspect and reconcile PRs #16, #17, #18; choose one Watch/Profile path and validate media lifecycle changes.
2. Resolve conflicts in security hardening PR #11 and review its diff before merge.
3. Review safety PRs #8/#9, upload UX #7, profile UX #6, and index cleanup #14 against current main and tests.
4. Re-run clean CI and record results; do not infer production readiness from a successful debug APK.
5. Complete feature matrix and Android smoke tests, then move through phases in order.

## Evidence log
- 2026-10-15: GitHub Actions reports successful main-branch APK Build and Supabase Database Tests. This is historical CI evidence, not proof of current green status or real-device/production verification.
- Not yet verified by this document: current live Supabase policies, production signing secrets, Play Console status, real-device flows, crash/ANR metrics, actual payout readiness.
