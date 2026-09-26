-- Normalize the privacy message audience values to the canonical database column.
BEGIN;

ALTER TABLE public.profile_privacy
  DROP CONSTRAINT IF EXISTS profile_privacy_allow_messages_check;

UPDATE public.profile_privacy
SET allow_messages = CASE lower(trim(allow_messages))
  WHEN 'followers' THEN 'followers'
  WHEN 'no one' THEN 'no_one'
  WHEN 'no_one' THEN 'no_one'
  WHEN 'nobody' THEN 'no_one'
  ELSE 'everyone'
END;

ALTER TABLE public.profile_privacy
  ALTER COLUMN allow_messages SET DEFAULT 'everyone';

ALTER TABLE public.profile_privacy
  ADD CONSTRAINT profile_privacy_allow_messages_check
  CHECK (allow_messages IN ('everyone', 'followers', 'no_one'));

COMMIT;
