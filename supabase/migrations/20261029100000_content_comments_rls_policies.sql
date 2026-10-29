-- Restore the scoped feed-comment policies in the clean-install migration chain.
-- Do not use a blanket "visible comments" policy: comment reads must follow
-- the parent content's visibility, and writes must require allow_comments=true.
BEGIN;

ALTER TABLE public.content_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS content_comments_visible_read ON public.content_comments;
DROP POLICY IF EXISTS content_comments_insert_own ON public.content_comments;
DROP POLICY IF EXISTS content_comments_delete_own ON public.content_comments;
DROP POLICY IF EXISTS comments_access_read ON public.content_comments;
DROP POLICY IF EXISTS comments_user_insert ON public.content_comments;
DROP POLICY IF EXISTS comments_user_delete ON public.content_comments;
DROP POLICY IF EXISTS comments_user_update ON public.content_comments;

CREATE POLICY comments_access_read
  ON public.content_comments
  FOR SELECT
  TO authenticated
  USING (
    status = 'visible'
    AND EXISTS (
      SELECT 1
      FROM public.contents c
      WHERE c.id = content_comments.content_id
        AND (
          c.owner_user_id = (SELECT auth.uid())
          OR (
            c.status = 'published'
            AND (
              c.visibility = 'public'
              OR (
                c.visibility = 'followers'
                AND EXISTS (
                  SELECT 1
                  FROM public.profile_follows f
                  WHERE f.follower_id = (SELECT auth.uid())
                    AND f.following_id = c.owner_user_id
                )
              )
            )
          )
        )
    )
  );

CREATE POLICY comments_user_insert
  ON public.content_comments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = (SELECT public.current_profile_id())
    AND status = 'visible'
    AND length(btrim(body)) BETWEEN 1 AND 1000
    AND EXISTS (
      SELECT 1
      FROM public.contents c
      WHERE c.id = content_comments.content_id
        AND c.allow_comments = true
        AND (
          c.owner_user_id = (SELECT auth.uid())
          OR (
            c.status = 'published'
            AND (
              c.visibility = 'public'
              OR (
                c.visibility = 'followers'
                AND EXISTS (
                  SELECT 1
                  FROM public.profile_follows f
                  WHERE f.follower_id = (SELECT auth.uid())
                    AND f.following_id = c.owner_user_id
                )
              )
            )
          )
        )
    )
  );

CREATE POLICY comments_user_delete
  ON public.content_comments
  FOR DELETE
  TO authenticated
  USING (user_id = (SELECT public.current_profile_id()));

CREATE POLICY comments_user_update
  ON public.content_comments
  FOR UPDATE
  TO authenticated
  USING (
    user_id = (SELECT public.current_profile_id())
    OR (SELECT public.is_platform_admin())
  )
  WITH CHECK (
    user_id = (SELECT public.current_profile_id())
    OR (SELECT public.is_platform_admin())
  );

GRANT SELECT ON public.content_comments TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.content_comments TO authenticated;

COMMIT;
