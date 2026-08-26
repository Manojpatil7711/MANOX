-- Normalize the privacy message audience values to match the Flutter dropdown.
BEGIN;

ALTER TABLE public.profile_privacy
  DROP CONSTRAINT IF EXISTS profile_privacy_who_can_message_check;

UPDATE public.profile_privacy
SET who_can_message = CASE lower(trim(who_can_message))
  WHEN 'followers' THEN 'followers'
  WHEN 'no one' THEN 'no_one'
  WHEN 'no_one' THEN 'no_one'
  WHEN 'nobody' THEN 'no_one'
  ELSE 'everyone'
END;

ALTER TABLE public.profile_privacy
  ALTER COLUMN who_can_message SET DEFAULT 'everyone';

ALTER TABLE public.profile_privacy
  ADD CONSTRAINT profile_privacy_who_can_message_check
  CHECK (who_can_message IN ('everyone', 'followers', 'no_one'));

COMMIT;
