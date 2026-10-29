-- MANOX comments were created with RLS enabled but without explicit policies.
-- This made comment reads/inserts fail on clean installs despite the UI being wired.
BEGIN;

ALTER TABLE public.content_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS content_comments_visible_read ON public.content_comments;
CREATE POLICY content_comments_visible_read
  ON public.content_comments
  FOR SELECT
  TO anon, authenticated
  USING (status = 'visible');

DROP POLICY IF EXISTS content_comments_insert_own ON public.content_comments;
CREATE POLICY content_comments_insert_own
  ON public.content_comments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND status = 'visible'
    AND length(btrim(body)) BETWEEN 1 AND 1000
  );

DROP POLICY IF EXISTS content_comments_delete_own ON public.content_comments;
CREATE POLICY content_comments_delete_own
  ON public.content_comments
  FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

GRANT SELECT ON public.content_comments TO anon, authenticated;
GRANT INSERT, DELETE ON public.content_comments TO authenticated;

COMMIT;
