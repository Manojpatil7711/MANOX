-- Private profile details used by the authenticated profile editor.
-- Date of birth must never be exposed through the public profile query.

CREATE TABLE IF NOT EXISTS public.profile_private_details (
  profile_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  date_of_birth date,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.profile_private_details ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profile_private_details_select_own ON public.profile_private_details;
CREATE POLICY profile_private_details_select_own
ON public.profile_private_details FOR SELECT
TO authenticated
USING ((select auth.uid()) = profile_id);

DROP POLICY IF EXISTS profile_private_details_insert_own ON public.profile_private_details;
CREATE POLICY profile_private_details_insert_own
ON public.profile_private_details FOR INSERT
TO authenticated
WITH CHECK ((select auth.uid()) = profile_id);

DROP POLICY IF EXISTS profile_private_details_update_own ON public.profile_private_details;
CREATE POLICY profile_private_details_update_own
ON public.profile_private_details FOR UPDATE
TO authenticated
USING ((select auth.uid()) = profile_id)
WITH CHECK ((select auth.uid()) = profile_id);

DROP POLICY IF EXISTS profile_private_details_delete_own ON public.profile_private_details;
CREATE POLICY profile_private_details_delete_own
ON public.profile_private_details FOR DELETE
TO authenticated
USING ((select auth.uid()) = profile_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.profile_private_details TO authenticated;

CREATE OR REPLACE FUNCTION public.touch_profile_private_details_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profile_private_details_updated_at_trg ON public.profile_private_details;
CREATE TRIGGER profile_private_details_updated_at_trg
BEFORE UPDATE ON public.profile_private_details
FOR EACH ROW EXECUTE FUNCTION public.touch_profile_private_details_updated_at();
