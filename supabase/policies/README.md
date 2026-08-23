# Supabase RLS and policies (MANOX)

This file documents the policies created by supabase/migrations/0001_init.sql and the security reasoning.

Summary of implemented policies

- Profiles: only profile owner may SELECT/UPDATE their row. Public profile data is exposed via the `public_profiles` view only (which contains no payout/KYC fields).
- Posts: public SELECT allowed for posts with visibility='public'; owners may insert/update/delete their posts; author_id must match the calling user's profile.
- Follows/Likes: inserts and deletes only allowed by the authenticated profile owner (DB check prevents self-follow).
- Notifications: SELECT allowed for the notification recipient only. Notifications insertion is server-side only.
- Earnings ledger: SELECT allowed for the owner only; the ledger is writeable only by server/service-role processes—no client-side INSERT/UPDATE/DELETE policies are created.
- Withdrawal requests: authenticated owners may create requests (INSERT) subject to server-side review for status transitions; no client-side UPDATE/DELETE policies exist.

Server-side operations

- Any mutation or state transition regarding earnings, payouts, or withdrawal state changes must be implemented server-side (Edge Function or server with service_role key). Use database functions or transactions that enforce business rules (idempotency, balance checks, ledger entries, status transition validation).

Follow-up migration notes

- The migration attempts to add a foreign key from `profiles.user_id` to `auth.users(id)` only if the `auth.users` table is present. Some hosting environments may restrict cross-schema constraints during normal migrations. If the FK cannot be added automatically, run the following as an admin or in a follow-up migration:

  ALTER TABLE profiles ADD CONSTRAINT fk_profiles_user_id FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE;

- Do not relax RLS policies to "open" modes without an independent security review.
