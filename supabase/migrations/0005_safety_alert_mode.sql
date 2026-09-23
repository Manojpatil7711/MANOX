-- 0005_safety_alert_mode.sql
-- Safety Alert Mode compatible with MANOX profiles.id = auth.users.id architecture.

BEGIN;

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS gender text,
  ADD COLUMN IF NOT EXISTS safety_role text,
  ADD COLUMN IF NOT EXISTS safety_role_verified boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS safety_notifications_enabled boolean NOT NULL DEFAULT false;

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_gender_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_gender_check
  CHECK (gender IS NULL OR lower(gender) IN ('female','male','other','prefer_not_to_say'));

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_safety_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_safety_role_check
  CHECK (safety_role IS NULL OR lower(safety_role) IN ('police','social_worker'));

CREATE TABLE IF NOT EXISTS safety_presence (
  profile_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS safety_alerts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  escalation smallint NOT NULL CHECK (escalation IN (1,2)),
  latitude double precision NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude double precision NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','acknowledged','resolved','cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  acknowledged_at timestamptz,
  resolved_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_safety_alerts_source ON safety_alerts(source_profile_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_safety_presence_location ON safety_presence(latitude, longitude);

ALTER TABLE safety_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS safety_presence_owner ON safety_presence;
CREATE POLICY safety_presence_owner ON safety_presence FOR ALL
  USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS safety_alert_insert_female ON safety_alerts;
CREATE POLICY safety_alert_insert_female ON safety_alerts FOR INSERT WITH CHECK (
  source_profile_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = source_profile_id AND lower(coalesce(p.gender,'')) = 'female'
  )
);

DROP POLICY IF EXISTS safety_alert_select_owner ON safety_alerts;
CREATE POLICY safety_alert_select_owner ON safety_alerts FOR SELECT USING (
  source_profile_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
      AND lower(coalesce(p.safety_role,'')) IN ('police','social_worker')
      AND p.safety_role_verified = true
  )
);

CREATE OR REPLACE FUNCTION dispatch_safety_alert_notifications()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.escalation = 1 THEN
    INSERT INTO notifications(user_id, notification_type, title, body, entity_type, entity_id)
    SELECT p.id, 'safety_alert', 'Safety Alert',
      'A nearby verified safety alert needs attention.', 'safety_alert', NEW.id
    FROM profiles p
    JOIN safety_presence sp ON sp.profile_id = p.id
    WHERE p.id <> NEW.source_profile_id
      AND p.safety_role_verified = true
      AND lower(coalesce(p.safety_role,'')) IN ('police','social_worker')
      AND p.safety_notifications_enabled = true
      AND (6371 * acos(least(1, greatest(-1,
        cos(radians(NEW.latitude)) * cos(radians(sp.latitude)) *
        cos(radians(sp.longitude) - radians(NEW.longitude)) +
        sin(radians(NEW.latitude)) * sin(radians(sp.latitude))
      )))) <= 5;
  ELSE
    INSERT INTO notifications(user_id, notification_type, title, body, entity_type, entity_id)
    SELECT p.id, 'safety_alert', 'Safety Alert',
      'A nearby MANOX safety alert was raised.', 'safety_alert', NEW.id
    FROM profiles p
    JOIN safety_presence sp ON sp.profile_id = p.id
    WHERE p.id <> NEW.source_profile_id
      AND p.safety_notifications_enabled = true
      AND (6371 * acos(least(1, greatest(-1,
        cos(radians(NEW.latitude)) * cos(radians(sp.latitude)) *
        cos(radians(sp.longitude) - radians(NEW.longitude)) +
        sin(radians(NEW.latitude)) * sin(radians(sp.latitude))
      )))) <= 2;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS safety_alert_dispatch_trg ON safety_alerts;
CREATE TRIGGER safety_alert_dispatch_trg
AFTER INSERT ON safety_alerts
FOR EACH ROW EXECUTE FUNCTION dispatch_safety_alert_notifications();

COMMIT;
