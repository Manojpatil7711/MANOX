-- MANOX storage defense in depth. App limits intentionally match these bucket limits.
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

DROP POLICY IF EXISTS reports_submit ON public.content_reports;
DROP POLICY IF EXISTS reports_user_insert ON public.content_reports;
CREATE POLICY reports_user_insert
ON public.content_reports
FOR INSERT TO authenticated
WITH CHECK (reporter_id = (SELECT current_profile_id()));
