# MANOX Google Play UGC Compliance Gate

MANOX is a social/creator app with public user-generated content. This release gate is based on the current Google Play UGC and User Data requirements.

## Required product controls

- Terms of Use / Community Guidelines acceptance before creating or uploading UGC.
- Clearly labelled in-app **Report content** action.
- Clearly labelled in-app **Report user** action.
- Clearly labelled in-app **Block user** action.
- Server-side report persistence and moderation queue.
- Server-side moderation decisions and audit trail.
- Timely removal/restriction of content or accounts when reports are actioned.
- In-app account deletion path.
- External account-deletion web resource for users who no longer have the app installed.
- Privacy Policy accessible inside the app and through the Play Store listing.
- Accurate Play Console Data Safety declarations.
- Accurate Content Rating / UGC questionnaire.
- Working reviewer/demo credentials when authentication is required.

## Current MANOX backend readiness

The Supabase production schema already contains `content_reports`, `user_blocks`, `moderation_decisions`, `content_safety_reviews`, `content_status_history`, `creator_safety_actions`, and moderation roles. RLS policies are enabled for the sensitive moderation tables.

The following were added in the current compliance pass:

- `legal_consents` for versioned Terms/Privacy/Community Guidelines acceptance.
- `profile_reports` for reporting user profiles.
- `delete-account` authenticated Supabase Edge Function for account deletion.
- `/community-safety` in-app compliance screen.

## Release blockers before Play production

1. Wire the visible Report/Block actions into every public post/profile/user interaction surface.
2. Ensure the upload/create flow checks the server-backed legal consent before publishing UGC.
3. Publish a public HTTPS Privacy Policy and account-deletion request page.
4. Complete Play Console Data Safety, Content Rating, App Content and UGC declarations.
5. Test moderator action flows with moderator/admin accounts.
6. Pass Flutter analyze, tests, debug/release AAB build and install smoke tests.

Do not mark MANOX Play Store ready until all six release blockers are verified.
