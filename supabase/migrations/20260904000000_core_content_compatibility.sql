-- Core content/publishing compatibility baseline.
-- The production database contains these objects from earlier feature migrations,
-- but the repository migration set was missing that historical baseline. Keep this
-- migration idempotent so clean CI replays can reproduce the objects required by
-- later migrations.

BEGIN;

-- Historical production schema includes platform_role on profiles, while the
-- repository's early baseline does not. Restore that compatibility column before
-- defining admin-aware functions below.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS platform_role text NOT NULL DEFAULT 'user';

CREATE TABLE IF NOT EXISTS public.contents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id uuid NOT NULL,
  content_type text NOT NULL DEFAULT 'video',
  title text,
  description text,
  media_url text,
  thumbnail_url text,
  status text NOT NULL DEFAULT 'processing',
  visibility text NOT NULL DEFAULT 'public',
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  media_urls jsonb NOT NULL DEFAULT '[]'::jsonb,
  audience_category text NOT NULL DEFAULT 'general',
  creator_skill text,
  kids_category text,
  allow_comments boolean NOT NULL DEFAULT true,
  allow_downloads boolean NOT NULL DEFAULT true
);

CREATE INDEX IF NOT EXISTS contents_owner_user_idx ON public.contents(owner_user_id);

ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.saved_contents (
  profile_id uuid NOT NULL,
  content_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  folder_name text NOT NULL DEFAULT 'Watch later',
  PRIMARY KEY (profile_id, content_id)
);

CREATE INDEX IF NOT EXISTS saved_contents_profile_content_idx
  ON public.saved_contents(profile_id, content_id);

ALTER TABLE public.saved_contents ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.creator_wallets (
  creator_id uuid PRIMARY KEY,
  available_balance_minor bigint NOT NULL DEFAULT 0,
  pending_balance_minor bigint NOT NULL DEFAULT 0,
  lifetime_earned_minor bigint NOT NULL DEFAULT 0,
  currency_code text NOT NULL DEFAULT 'INR',
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.withdrawal_methods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid NOT NULL,
  method_type text NOT NULL,
  provider_customer_ref text,
  masked_destination text,
  verified boolean NOT NULL DEFAULT false,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.withdrawal_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid NOT NULL,
  method_id uuid NOT NULL,
  amount_minor bigint NOT NULL,
  currency_code text NOT NULL DEFAULT 'INR',
  status text NOT NULL DEFAULT 'pending_security',
  idempotency_key text NOT NULL,
  requested_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  failure_code text,
  provider_reference text
);

-- The repository's original 0001 migration already creates withdrawal_requests,
-- but with the legacy profile_id/amount schema. Later payout migrations use the
-- creator-wallet schema, so upgrade the legacy table in-place for clean replay.
ALTER TABLE public.withdrawal_requests
  ADD COLUMN IF NOT EXISTS creator_id uuid,
  ADD COLUMN IF NOT EXISTS method_id uuid,
  ADD COLUMN IF NOT EXISTS amount_minor bigint,
  ADD COLUMN IF NOT EXISTS requested_at timestamptz,
  ADD COLUMN IF NOT EXISTS processed_at timestamptz,
  ADD COLUMN IF NOT EXISTS failure_code text,
  ADD COLUMN IF NOT EXISTS provider_reference text;

UPDATE public.withdrawal_requests
SET creator_id = COALESCE(creator_id, profile_id),
    amount_minor = COALESCE(amount_minor, GREATEST(1, round(amount * 100))::bigint),
    requested_at = COALESCE(requested_at, created_at)
WHERE creator_id IS NULL
   OR amount_minor IS NULL
   OR requested_at IS NULL;

ALTER TABLE public.withdrawal_requests
  ALTER COLUMN creator_id SET NOT NULL,
  ALTER COLUMN method_id DROP NOT NULL,
  ALTER COLUMN amount_minor SET NOT NULL,
  ALTER COLUMN amount_minor SET DEFAULT 0,
  ALTER COLUMN requested_at SET NOT NULL,
  ALTER COLUMN requested_at SET DEFAULT now();

ALTER TABLE public.withdrawal_requests
  DROP CONSTRAINT IF EXISTS withdrawal_requests_status_check;

ALTER TABLE public.withdrawal_requests
  ADD CONSTRAINT withdrawal_requests_status_check
  CHECK (status IN ('pending_security','queued','processing','paid','failed','cancelled','held'));

ALTER TABLE public.withdrawal_requests
  ADD CONSTRAINT withdrawal_requests_creator_id_fkey
  FOREIGN KEY (creator_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS withdrawal_requests_idempotency_uidx
  ON public.withdrawal_requests(idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.advertisers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_profile_id uuid,
  business_name text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ad_campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  advertiser_id uuid NOT NULL,
  name text NOT NULL,
  status text NOT NULL DEFAULT 'draft',
  objective text NOT NULL,
  budget_minor bigint NOT NULL DEFAULT 0,
  daily_budget_minor bigint NOT NULL DEFAULT 0,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ad_campaigns_advertiser_id_idx
  ON public.ad_campaigns(advertiser_id);

CREATE TABLE IF NOT EXISTS public.media_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id uuid NOT NULL,
  asset_type text NOT NULL,
  storage_path text NOT NULL,
  mime_type text,
  size_bytes bigint,
  sha256 text,
  status text NOT NULL DEFAULT 'uploaded',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.legal_consents (
  user_id uuid NOT NULL,
  policy_type text NOT NULL,
  policy_version text NOT NULL,
  accepted_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, policy_type),
  CHECK (policy_type IN ('terms_of_use','privacy_policy','community_guidelines'))
);

CREATE TABLE IF NOT EXISTS public.content_publish_checks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id uuid NOT NULL,
  check_type text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  score numeric,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  checked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS content_publish_checks_content_idx
  ON public.content_publish_checks(content_id, status);

ALTER TABLE public.legal_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_publish_checks ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.current_profile_id()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = public
AS $function$
  SELECT id FROM public.profiles WHERE id = (SELECT auth.uid()) LIMIT 1
$function$;

CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = public
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = (SELECT auth.uid())
      AND platform_role IN ('owner','admin','moderator')
  )
$function$;

CREATE OR REPLACE FUNCTION public.publish_content_secure(p_content_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_owner uuid;
  v_ok boolean;
BEGIN
  SELECT owner_user_id INTO v_owner
  FROM public.contents
  WHERE id = p_content_id
  FOR UPDATE;

  IF v_owner IS NULL THEN
    RAISE EXCEPTION 'content_not_found';
  END IF;

  IF v_owner <> public.current_profile_id() AND NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  v_ok := public.can_publish_content(p_content_id);

  IF NOT v_ok THEN
    RAISE EXCEPTION 'publish_checks_failed';
  END IF;

  UPDATE public.contents
  SET status = 'published',
      published_at = coalesce(published_at, now()),
      updated_at = now()
  WHERE id = p_content_id;

  RETURN true;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.current_profile_id() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_platform_admin() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.publish_content_secure(uuid) FROM PUBLIC, anon, authenticated;

COMMIT;
