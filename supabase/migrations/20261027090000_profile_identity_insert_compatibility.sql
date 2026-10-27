-- Keep profile identity consistent with auth.uid() on fresh installs.
-- Existing deployed schemas without user_id are left structurally unchanged.
BEGIN;

CREATE OR REPLACE FUNCTION public.manox_sync_profile_auth_identity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  -- Work through the row's JSON representation so schemas without user_id
  -- remain compatible. Preserve any established non-null legacy mapping.
  IF (to_jsonb(NEW) ->> 'user_id') IS NULL THEN
    NEW := jsonb_populate_record(NEW, jsonb_build_object('user_id', NEW.id));
  END IF;
  RETURN NEW;
END;
$$;

-- The historical auth signup trigger inserted only user_id and let profiles.id
-- receive a random UUID. The app and interaction tables now consistently use
-- profiles.id = auth.users.id, so make future signup rows use that identity too.
-- Dynamic SQL keeps this compatible with deployments where profiles.user_id
-- no longer exists.
CREATE OR REPLACE FUNCTION private.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $
DECLARE
  base_username text;
  final_username text;
  display_name_value text;
BEGIN
  base_username := split_part(COALESCE(NEW.email, 'user'), '@', 1);
  base_username := regexp_replace(lower(base_username), '[^a-z0-9_]+', '_', 'g');
  base_username := trim(both '_' from base_username);
  IF base_username = '' THEN base_username := 'user'; END IF;

  final_username := base_username;
  IF EXISTS (SELECT 1 FROM public.profiles WHERE username = final_username) THEN
    final_username := base_username || '_' || substr(NEW.id::text, 1, 6);
  END IF;
  display_name_value := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data->>'display_name'), ''),
    base_username
  );

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'user_id'
  ) THEN
    EXECUTE 'INSERT INTO public.profiles (id, user_id, username, display_name)
             VALUES ($1, $1, $2, $3)
             ON CONFLICT (user_id) DO NOTHING'
      USING NEW.id, final_username, display_name_value;
  ELSE
    EXECUTE 'INSERT INTO public.profiles (id, username, display_name)
             VALUES ($1, $2, $3)
             ON CONFLICT (id) DO NOTHING'
      USING NEW.id, final_username, display_name_value;
  END IF;

  INSERT INTO public.profile_privacy (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

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
