-- Ensure published feed rows always have a stable cursor timestamp.
-- Backfill existing published rows first, then enforce the invariant.
UPDATE public.contents
SET published_at = created_at
WHERE status = 'published'
  AND published_at IS NULL;

ALTER TABLE public.contents
  DROP CONSTRAINT IF EXISTS contents_published_requires_timestamp;

ALTER TABLE public.contents
  ADD CONSTRAINT contents_published_requires_timestamp
  CHECK (status <> 'published' OR published_at IS NOT NULL);

CREATE INDEX IF NOT EXISTS contents_feed_published_cursor_idx
  ON public.contents (published_at DESC, id DESC)
  WHERE status = 'published'
    AND visibility IN ('public', 'followers')
    AND audience_category = 'general';
