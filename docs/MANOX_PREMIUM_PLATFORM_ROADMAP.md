# MANOX Premium Platform Roadmap

Status date: 2026-10-29
Base: `feat/premium-video-editor-text-styles` (PR #28)
Rule: keep `main` unchanged until review, automated checks, and device QA pass.

## Product bar

MANOX should earn a premium rating through reliable everyday flows, creator control, safety, speed, and a coherent design system—not by copying competitors' branding or adding superficial buttons. A feature is not complete until its real action works, errors are recoverable, accessibility is considered, and regression tests exist.

## Competitor benchmark (capability benchmark, not a claim of feature parity)

| Product benchmark | User expectation to meet | MANOX implementation target | Acceptance evidence |
|---|---|---|---|
| Instagram | Reliable profile, media posts, comments, follows, discovery, reporting and blocking | Make profile identity and social graph consistent with the deployed Supabase schema; make comment errors visible and retryable | Signed-in device test, persisted records, RLS tests, reload verification |
| TikTok | Fast vertical video browsing, understandable creator tools, responsive playback | Stable video feed, clear media loading states, pagination, upload progress and useful preview failures | Slow-network and large-media tests; no black/blank preview without an explanation |
| YouTube | Predictable playback, creator identity, saved content, useful discovery and accessible controls | Durable saved items, creator profile posts, reliable feed filters, accessible action labels | Repository/widget tests and persistence checks across app restart |
| CapCut | Usable trim, crop/ratio, filters, text, stickers, layers, audio and export | Keep editor tools genuinely connected to preview/export; label effects honestly; guard failed exports without corrupting the original | Exported media inspected on-device; source survives a failed export; per-tool regression coverage |
| Mature social platforms | Privacy controls, moderation, account recovery, predictable settings and clear consent | Complete block/report, comment controls, account/security settings, legal-consent flow and safe defaults | RLS/security tests, route audit, UGC compliance checklist, account lifecycle tests |

## Current verified baseline

- Repository: `Manojpatil7711/MANOX`; Flutter/Dart application with Supabase backend.
- Two relevant open pull requests exist: PR #27 (profile/comments identity-schema fix) and PR #28 (media upload/editor/comments stabilization).
- CI evidence inspected on 2026-10-29: Debug APK build and Supabase database security tests succeeded for the PR #28 head. This is not proof of complete runtime correctness.
- Current user-reported defects to close: profile screen failing to open/load, comments failing after submit, video posting/preview failures, duplicate/confusing filter names, and an overall dated feel.
- PR #28 currently advertises 26 filter labels, 12 text presets, 10 colours, 40 stickers, decorative elements, masks, and keyframe-style motion. These controls must be checked against actual exported output before they are marketed as fully supported.
- Do not merge to `main`, run destructive production migrations, or write test records into the user's production account as part of this roadmap.

## P0 — Reliability before visual expansion

1. **Profile identity**
   - Verify the deployed schema's `profiles.id` identity mapping and keep all reads/writes consistent.
   - Ensure a missing profile is created safely and idempotently; handle concurrent creation without hiding unrelated errors.
   - Confirm avatar upload, profile save, profile post query, and profile navigation.
   - Do not expose email addresses as public display names.

2. **Comments**
   - Test first-time user with no profile, existing user, empty comment, 1,000-character boundary, offline/error response, and double tap.
   - After a successful insert, show one comment immediately; after failure, preserve the draft and show retry.
   - Confirm author display names and ordering from the real backend.

3. **Media posting**
   - Upload media bytes to Storage and persist only a valid storage path/URL, never a device-local path.
   - Verify MIME type, extension and file signature; enforce size limits; clean up orphaned uploads after a failed post.
   - Test image, MP4, MOV, unsupported type, truncated file, and interrupted upload.
   - Confirm posts render on a second signed-in device/session.

4. **Release and regression gates**
   - Run formatter, static analysis, all Flutter tests, Supabase RLS/database tests, and Debug APK build.
   - Test on a physical Android device: sign-in, profile, edit/save, create image post, create video post, comments, likes, save/unsave, follow/unfollow, report/block, logout/login.
   - Record failures; do not label a feature fixed based only on compilation.

## P1 — Premium creator experience

- A unified editor layout with clearly named categories: Trim, Crop, Speed, Filters, Text, Stickers, Elements, Audio, Masks, Export.
- Remove near-duplicate filter labels; each visible preset must have a distinct, tested effect or be removed.
- Text styles must visibly differ in the exported file, not only in the settings sheet. Ensure all selected text colour values are accepted by the installed FFmpeg build.
- Stickers/elements must have predictable placement, remain inside the frame, and be removable individually.
- Make preview and export agree on ratio, filter, text placement and audio.
- Preserve the original file until export succeeds; on failure restore the source and offer a clear retry.
- Show export progress, prevent duplicate export, handle cancellation/low storage, and clean temporary files.
- Use no paid API or required paid asset pack for the baseline editor.

## P2 — Premium social product

- Home feed: clear For You / Following / Latest semantics, stable pagination, deduplication, pull-to-refresh and retry.
- Creator profile: avatar, display name, unique handle, bio, creator category, posts, follower/following counts, and edit controls that work.
- Discovery/search: useful empty/loading/error states; never fabricate trending metrics.
- Messaging and notifications: real persisted state, permission-aware notifications, block/report enforcement.
- Saved content: folder actions, persistence after restart, and clear empty state.
- Settings: account/email, password/security, privacy, blocked accounts, reports/help, community guidelines, privacy policy, logout.
- Monetization: show only truthful balances/statuses; payout flows must use server-verified state and must never imply a guaranteed earning.

## P3 — Safety, performance, accessibility and release

- Verify row-level security for every user-owned table and storage object path; no service-role secrets in the client.
- Apply age-appropriate content restrictions consistently in feeds, search, comments and media publishing.
- Add accessible labels, scalable text, sufficient contrast, touch targets, and clear loading/empty/error states.
- Measure startup time, feed rendering, media upload/export duration and memory on representative Android devices.
- Audit navigation for dead ends, duplicated controls, placeholder pages and inconsistent naming.
- Release only after clean CI, device smoke tests, privacy/UGC checklist, versioning, and recoverable failure paths.

## 10/10 release scorecard

A 10/10 is an acceptance target, not a score claimed today. Each category must pass evidence-based review:

- [ ] Core journeys work end-to-end on a physical Android device.
- [ ] Profile, comments and video posting bugs are reproduced, fixed, and regression-tested.
- [ ] All visible buttons perform their stated action; no dead controls or misleading placeholders.
- [ ] Editor effects are visible in exported media and source media is recoverable on failure.
- [ ] CI is green: formatting, analysis, Flutter tests, database/RLS tests, APK build.
- [ ] Privacy, consent, moderation, blocking/reporting and storage policies are tested.
- [ ] UI is consistent, responsive, accessible and free of duplicate/confusing tool labels.
- [ ] Performance and low-storage/offline/error states are tested.
- [ ] Monetization and payouts show server-confirmed data only.
- [ ] Release notes, version, install/update and final QA evidence are prepared.

## Working order

1. Close the PR #27 / PR #28 overlap safely; review the combined diff before either merge.
2. Fix and prove profile/comments/media posting on device.
3. Complete editor output fidelity and export failure recovery.
4. Run the full regression suite and audit all primary navigation/actions.
5. Polish premium visual consistency only after reliability gates pass.
6. Prepare a release candidate and final scorecard; keep `main` protected until evidence is green.
