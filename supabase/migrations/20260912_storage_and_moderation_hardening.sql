BEGIN;

-- Storage defense in depth: match the app's supported upload types and the
-- existing bucket size limits so direct Storage API calls cannot broaden them.
UPDATE storage.buckets
SET file_size_limit = 52428800,
    allowed_mime_types = ARRAY[
      'image/jpeg', 'image/png', 'image/webp', 'image/gif',
      'video/mp4', 'video/quicktime', 'video/x-m4v', 'video/webm', 'video/3gpp'
    ]::text[]
WHERE id = 'manox-media';

UPDATE storage.buckets
SET file_size_limit = 2097152,
    allowed_mime_types = ARRAY[
      'image/jpeg', 'image/png', 'image/webp', 'image/gif'
    ]::text[]
WHERE id = 'manox-avatars';

-- Remove the legacy reporter policy that incorrectly compared reporter_id
-- directly with auth.uid(). reporter_id is a profile UUID in the live schema.
DROP POLICY IF EXISTS reports_submit ON public.content_reports;

-- Keep reporting identity bound to the authenticated user's current profile.
DROP POLICY IF EXISTS reports_user_insert ON public.content_reports;
CREATE POLICY reports_user_insert
ON public.content_reports
FOR INSERT
TO authenticated
WITH CHECK (reporter_id = (SELECT current_profile_id()));

COMMIT;
