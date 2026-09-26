-- Speeds up feed mapping when checking which visible posts the current user saved.
-- The application filters by profile_id and then matches a page of content_id values.
CREATE INDEX IF NOT EXISTS saved_contents_profile_content_idx
  ON public.saved_contents (profile_id, content_id);
