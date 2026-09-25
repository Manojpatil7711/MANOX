BEGIN;

CREATE OR REPLACE FUNCTION public.can_publish_content(p_content_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.contents c
    WHERE c.id = p_content_id
      AND c.owner_user_id = public.current_profile_id()
      AND c.status IN ('draft','ready')
  )
  AND EXISTS (SELECT 1 FROM public.legal_consents WHERE user_id = public.current_profile_id() AND policy_type = 'terms_of_use' AND policy_version = '2026-08-26')
  AND EXISTS (SELECT 1 FROM public.legal_consents WHERE user_id = public.current_profile_id() AND policy_type = 'privacy_policy' AND policy_version = '2026-08-26')
  AND EXISTS (SELECT 1 FROM public.legal_consents WHERE user_id = public.current_profile_id() AND policy_type = 'community_guidelines' AND policy_version = '2026-08-26')
  AND NOT EXISTS (
    SELECT 1 FROM public.content_publish_checks
    WHERE content_id = p_content_id AND status IN ('failed','blocked','review','pending')
  );
$function$;

CREATE OR REPLACE FUNCTION public.prevent_direct_content_publish()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $function$
BEGIN
  IF NEW.status = 'published' AND COALESCE(OLD.status, '') <> 'published' AND (auth.jwt() ->> 'role') <> 'service_role' THEN
    RAISE EXCEPTION 'published_status_requires_server_publish';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS prevent_direct_content_publish_trg ON public.contents;
CREATE TRIGGER prevent_direct_content_publish_trg
BEFORE INSERT OR UPDATE OF status ON public.contents
FOR EACH ROW EXECUTE FUNCTION public.prevent_direct_content_publish();

DROP POLICY IF EXISTS contents_owner_manage ON public.contents;
CREATE POLICY contents_owner_insert ON public.contents FOR INSERT TO authenticated
WITH CHECK (auth.uid() = owner_user_id AND status IN ('draft','ready'));
CREATE POLICY contents_owner_update ON public.contents FOR UPDATE TO authenticated
USING (auth.uid() = owner_user_id) WITH CHECK (auth.uid() = owner_user_id);
CREATE POLICY contents_owner_delete ON public.contents FOR DELETE TO authenticated
USING (auth.uid() = owner_user_id);

REVOKE EXECUTE ON FUNCTION public.can_publish_content(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.prevent_direct_content_publish() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.publish_content_secure(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.publish_content_secure(uuid) TO authenticated, service_role;

COMMIT;