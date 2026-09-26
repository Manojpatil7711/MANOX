-- MANOX feed interaction hardening.
-- Constraints are intentionally idempotent for safe redeploys.
ALTER TABLE public.content_comments
  DROP CONSTRAINT IF EXISTS content_comments_body_length_check;
ALTER TABLE public.content_comments
  ADD CONSTRAINT content_comments_body_length_check
  CHECK (length(btrim(body)) BETWEEN 1 AND 1000);

CREATE UNIQUE INDEX IF NOT EXISTS content_reports_one_active_report_idx
  ON public.content_reports (reporter_id, content_id)
  WHERE status IN ('open', 'reviewing');

CREATE INDEX IF NOT EXISTS idx_content_comments_visible_created
  ON public.content_comments (content_id, created_at DESC)
  WHERE status = 'visible';

CREATE UNIQUE INDEX IF NOT EXISTS uq_profile_follows_pair
  ON public.profile_follows (follower_id, following_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_content_likes_user_content
  ON public.content_likes (user_id, content_id);
