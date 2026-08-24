-- 0002_profile_privacy.sql — Profile onboarding + privacy controls
BEGIN;

CREATE SCHEMA IF NOT EXISTS private;

-- Create a profile automatically after every Supabase Auth signup.
CREATE OR REPLACE FUNCTION private.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  base_username text;
  final_username text;
BEGIN
  base_username := split_part(COALESCE(NEW.email, 'user'), '@', 1);
  base_username := regexp_replace(lower(base_username), '[^a-z0-9_]+', '_', 'g');
  base_username := trim(both '_' from base_username);
  IF base_username = '' THEN base_username := 'user'; END IF;

  final_username := base_username;
  IF EXISTS (SELECT 1 FROM public.profiles WHERE username = final_username) THEN
    final_username := base_username || '_' || substr(NEW.id::text, 1, 6);
  END IF;

  INSERT INTO public.profiles (user_id, username, display_name)
  VALUES (
    NEW.id,
    final_username,
    COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'display_name'), ''), base_username)
  )
  ON CONFLICT (user_id) DO NOTHING;

  INSERT INTO public.profile_privacy (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.handle_new_user() FROM PUBLIC;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION private.handle_new_user();

-- Privacy is private account data; it is never part of the public profile.
CREATE TABLE IF NOT EXISTS public.profile_privacy (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  allow_messages text NOT NULL DEFAULT 'everyone'
    CHECK (allow_messages IN ('everyone', 'followers', 'no_one')),
  allow_contact_sharing boolean NOT NULL DEFAULT false,
  show_online_status boolean NOT NULL DEFAULT false,
  show_last_seen boolean NOT NULL DEFAULT false,
  read_receipts boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profile_privacy_user_id ON public.profile_privacy(user_id);

ALTER TABLE public.profile_privacy ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profile_privacy_select_own ON public.profile_privacy;
CREATE POLICY profile_privacy_select_own
ON public.profile_privacy FOR SELECT
TO authenticated
USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS profile_privacy_insert_own ON public.profile_privacy;
CREATE POLICY profile_privacy_insert_own
ON public.profile_privacy FOR INSERT
TO authenticated
WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS profile_privacy_update_own ON public.profile_privacy;
CREATE POLICY profile_privacy_update_own
ON public.profile_privacy FOR UPDATE
TO authenticated
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, UPDATE ON public.profile_privacy TO authenticated;

-- Backfill privacy rows for accounts that already exist.
INSERT INTO public.profile_privacy (user_id)
SELECT id FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

-- Backfill profiles for accounts created before this migration.
INSERT INTO public.profiles (user_id, username, display_name)
SELECT
  u.id,
  CASE
    WHEN EXISTS (SELECT 1 FROM public.profiles p WHERE p.username = split_part(COALESCE(u.email, 'user'), '@', 1))
      THEN split_part(COALESCE(u.email, 'user'), '@', 1) || '_' || substr(u.id::text, 1, 6)
    ELSE split_part(COALESCE(u.email, 'user'), '@', 1)
  END,
  COALESCE(NULLIF(trim(u.raw_user_meta_data->>'display_name'), ''), split_part(COALESCE(u.email, 'user'), '@', 1))
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.user_id = u.id);

COMMIT;
