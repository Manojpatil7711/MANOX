-- Remove redundant indexes created by earlier overlapping hardening passes.
-- Keep primary/constraint-backed indexes and the first canonical equivalent index.
DROP INDEX IF EXISTS public.idx_comments_content;
DROP INDEX IF EXISTS public.idx_content_comments_content_visible_created;
DROP INDEX IF EXISTS public.idx_content_comments_user_id;
DROP INDEX IF EXISTS public.idx_content_likes_content;
DROP INDEX IF EXISTS public.uq_content_likes_user_content;
DROP INDEX IF EXISTS public.idx_content_reports_status;
DROP INDEX IF EXISTS public.uq_profile_follows_pair;
DROP INDEX IF EXISTS public.idx_content_comments_visible_content_created;