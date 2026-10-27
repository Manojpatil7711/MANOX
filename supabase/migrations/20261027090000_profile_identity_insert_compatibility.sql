-- Keep profile identity consistent with auth.uid() on fresh installs.
-- Existing deployed schemas without user_id are left structurally unchanged.
BEGIN;

CREATE OR REPLACE FUNCTION public.manox_sync_profile_auth_identity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  -- jsonb_populate_record ignores fields absent from the target row type,
  -- so this trigger function remains compatible with schemas lacking user_id.
  NEW := jsonb_populate_record(NEW, jsonb_build_object('user_id', NEW.id));
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'user_id'
  ) THEN
    DROP TRIGGER IF EXISTS manox_sync_profile_auth_identity_trg ON public.profiles;
    CREATE TRIGGER manox_sync_profile_auth_identity_trg
      BEFORE INSERT ON public.profiles
      FOR EACH ROW EXECUTE FUNCTION public.manox_sync_profile_auth_identity();
    DROP POLICY IF EXISTS profiles_owner_insert ON public.profiles;
    CREATE POLICY profiles_owner_insert ON public.profiles
      FOR INSERT TO authenticated
      WITH CHECK (id = (select auth.uid()) AND user_id = (select auth.uid()));
  ELSE
    DROP POLICY IF EXISTS profiles_owner_insert ON public.profiles;
    CREATE POLICY profiles_owner_insert ON public.profiles
      FOR INSERT TO authenticated
      WITH CHECK (id = (select auth.uid()));
  END IF;
END;
$$;

COMMIT;
