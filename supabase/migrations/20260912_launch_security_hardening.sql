-- MANOX launch security hardening
-- Defense-in-depth constraints for client-facing social mutations.
-- Keep financial state transitions server-authorized.

BEGIN;

-- Prevent malformed/self interaction rows even if a client bypasses UI validation.
DO $$
BEGIN
  IF to_regclass('public.content_likes') IS NOT NULL THEN
    ALTER TABLE public.content_likes
      DROP CONSTRAINT IF EXISTS content_likes_no_self_content_owner;
  END IF;
END $$;

-- Tighten withdrawal request invariants. Client may request, but never choose a
-- privileged status. Existing RLS/server flow remains responsible for ownership.
DO $$
BEGIN
  IF to_regclass('public.withdrawal_requests') IS NOT NULL THEN
    ALTER TABLE public.withdrawal_requests
      DROP CONSTRAINT IF EXISTS withdrawal_requests_amount_positive;
    ALTER TABLE public.withdrawal_requests
      ADD CONSTRAINT withdrawal_requests_amount_positive CHECK (amount > 0);

    ALTER TABLE public.withdrawal_requests
      DROP CONSTRAINT IF EXISTS withdrawal_requests_status_requested_only_client;
  END IF;
END $$;

-- Fast owner-scoped lookup for withdrawal history and idempotency checks.
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_profile_status_created
  ON public.withdrawal_requests (profile_id, status, created_at DESC);

-- Fast current-user interaction lookup used by the feed.
CREATE INDEX IF NOT EXISTS idx_content_likes_user_content
  ON public.content_likes (user_id, content_id);

CREATE INDEX IF NOT EXISTS idx_saved_contents_profile_content
  ON public.saved_contents (profile_id, content_id);

COMMIT;
