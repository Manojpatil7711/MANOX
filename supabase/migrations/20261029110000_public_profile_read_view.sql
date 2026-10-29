-- Public creator pages need to read other users' public profile fields.
-- Keep private fields (notably gender and date of birth) out of this API surface.
BEGIN;

CREATE OR REPLACE VIEW public.public_profiles
WITH (security_barrier = true)
AS
SELECT
  id,
  username,
  display_name,
  avatar_url,
  bio,
  country_code,
  profession,
  is_creator,
  skills,
  creator_category,
  other_link
FROM public.profiles;

GRANT SELECT ON public.public_profiles TO anon, authenticated;

COMMIT;
