# MANOX No. 2 — Feature Activation

No. 2 activates the existing routed feature destinations for the regular MANOX flow. The application router already exposes Search, Beats, Learn, Trending, Sports and Women Safety routes. This checkpoint documents that these destinations must be wired from the user-facing Home/navigation UI and verified end-to-end before production release.

## Acceptance checklist
- Search opens `/search`.
- Beats opens `/beats`.
- Learn opens `/learn`.
- Trending opens `/trending`.
- Sports opens `/sports`.
- Women Safety opens `/women-safety`.
- No destination should silently do nothing when tapped.
- Kids mode must not expose adult/main-flow destinations.

## QA
This commit is a routing/activation checkpoint. APK manual verification remains required for tap behavior and backend/content functionality.
