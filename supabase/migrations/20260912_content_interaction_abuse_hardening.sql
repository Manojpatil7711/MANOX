-- Launch hardening: bound user-generated comment text and prevent duplicate
-- active reports for the same reporter/content pair.

ALTER TABLE public.content_comments
  DROP CONSTRAINT IF EXISTS content_comments_body_length_check;

ALTER TABLE public.content_comments
  ADD CONSTRAINT content_comments_body_length_check
  CHECK (length(btrim(body)) BETWEEN 1 AND 1000);

CREATE UNIQUE INDEX IF NOT EXISTS content_reports_one_active_report_idx
  ON public.content_reports (reporter_id, content_id)
  WHERE status IN ('open', 'reviewing');

CREATE INDEX IF NOT EXISTS idx_content_comments_content_visible_created
  ON public.content_comments (content_id, created_at DESC)
  WHERE status = 'visible';
