-- MANOX profile/privacy compatibility migration
-- Keeps the existing profiles.user_id architecture and aligns privacy fields
-- with the Flutter settings implementation.

BEGIN;

-- Existing MANOX profiles use user_id -> auth.users(id).
-- If the table was created by an older profile script, keep that schema intact.

CREATE TABLE IF NOT EXISTS public.profile_privacy (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  private_account boolean NOT NULL DEFAULT false,
  allow_messages text NOT NULL DEFAULT 'everyone',
  allow_contact_sharing boolean NOT NULL DEFAULT false,
  show_online_status boolean NOT NULL DEFAULT false,
  show_last_seen boolean NOT NULL DEFAULT false,
  read_receipts boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.profile_privacy ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.profile_privacy
  ADD COLUMN IF NOT EXISTS user_id uuid;
ALTER TABLE public.profile_privacy
  ADD COLUMN IF NOT EXISTS private_account boolean NOT NULL DEFAULT false;
ALTER TABLE public.profile_privacy
  ADD COLUMN IF NOT EXISTS allow_messages text NOT NULL DEFAULT 'everyone';
ALTER TABLE public.profile_privacy
  ADD COLUMN IF NOT EXISTS allow_contact_sharing boolean NOT NULL DEFAULT false;
ALTER TABLE public.profile_privacy
  ADD COLUMN IF NOT EXISTS show_online_status boolean NOT NULL DEFAULT false;
ALTER TABLE public.profile_privacy
  ADD COLUMN IF NOT EXISTS show_last_seen boolean NOT NULL DEFAULT false;
ALTER TABLE public.profile_privacy
  ADD COLUMN IF NOT EXISTS read_receipts boolean NOT NULL DEFAULT true;
ALTER TABLE public.profile_privacy
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

UPDATE public.profile_privacy
SET user_id = id
WHERE user_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS profile_privacy_user_id_key
  ON public.profile_privacy(user_id);

ALTER TABLE public.profile_privacy
  DROP CONSTRAINT IF EXISTS profile_privacy_allow_messages_check;
ALTER TABLE public.profile_privacy
  ADD CONSTRAINT profile_privacy_allow_messages_check
  CHECK (allow_messages IN ('everyone', 'followers', 'no_one'));

DROP POLICY IF EXISTS "Users can view own privacy" ON public.profile_privacy;
CREATE POLICY "Users can view own privacy"
  ON public.profile_privacy FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own privacy" ON public.profile_privacy;
CREATE POLICY "Users can insert own privacy"
  ON public.profile_privacy FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own privacy" ON public.profile_privacy;
CREATE POLICY "Users can update own privacy"
  ON public.profile_privacy FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

INSERT INTO public.profile_privacy (id, user_id)
SELECT id, id FROM auth.users
ON CONFLICT (id) DO UPDATE SET user_id = EXCLUDED.user_id;

COMMIT;
