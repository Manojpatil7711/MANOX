-- Public creator pages need a stable, restricted view across clean installs
-- and the existing production schema. Keep the six original public_profiles
-- columns in their original order, then append additional public fields.
BEGIN;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS country_code text,
  ADD COLUMN IF NOT EXISTS profession text,
  ADD COLUMN IF NOT EXISTS skills jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS creator_category text,
  ADD COLUMN IF NOT EXISTS other_link text;

CREATE OR REPLACE VIEW public.public_profiles
WITH (security_barrier = true)
AS
SELECT
  id,
  username,
  display_name,
  avatar_url,
  is_creator,
  created_at,
  bio,
  country_code,
  profession,
  skills,
  creator_category,
  other_link
FROM public.profiles;

GRANT SELECT ON public.public_profiles TO anon, authenticated;

COMMIT;
