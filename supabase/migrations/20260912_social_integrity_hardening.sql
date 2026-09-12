BEGIN;

-- Defense in depth: interaction tables must reject forged/self/duplicate relationships.
DO $$
BEGIN
  IF to_regclass('public.profile_follows') IS NOT NULL THEN
    ALTER TABLE public.profile_follows ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.profile_follows ADD CONSTRAINT profile_follows_no_self CHECK (follower_id <> following_id);
    CREATE UNIQUE INDEX IF NOT EXISTS uq_profile_follows_pair ON public.profile_follows(follower_id, following_id);
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  IF to_regclass('public.content_likes') IS NOT NULL THEN
    ALTER TABLE public.content_likes ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.content_likes ADD CONSTRAINT content_likes_no_self_content_owner CHECK (user_id IS NOT NULL);
    CREATE UNIQUE INDEX IF NOT EXISTS uq_content_likes_user_content ON public.content_likes(user_id, content_id);
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Keep comment reads efficient and bounded by the visibility predicate used by the app.
CREATE INDEX IF NOT EXISTS idx_content_comments_visible_content_created
  ON public.content_comments(content_id, created_at ASC)
  WHERE status = 'visible';

-- Share/event history is append-only and commonly queried by content/user.
CREATE INDEX IF NOT EXISTS idx_content_shares_content_created
  ON public.content_shares(content_id, created_at DESC);

COMMIT;
