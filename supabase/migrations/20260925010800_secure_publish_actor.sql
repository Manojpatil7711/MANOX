-- Preserve end-user authorization across the service-role publish Edge Function.
CREATE OR REPLACE FUNCTION public.publish_content_secure_as_user(p_content_id uuid, p_actor_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare v_owner uuid; v_ok boolean;
begin
 if p_actor_user_id is null then raise exception 'actor_required'; end if;
 select owner_user_id into v_owner from public.contents where id=p_content_id for update;
 if v_owner is null then raise exception 'content_not_found'; end if;
 if v_owner <> p_actor_user_id then raise exception 'not_authorized'; end if;
 v_ok := EXISTS (SELECT 1 FROM public.contents c WHERE c.id=p_content_id AND c.owner_user_id=p_actor_user_id AND c.status IN ('draft','ready'))
   AND EXISTS (SELECT 1 FROM public.legal_consents lc WHERE lc.user_id=p_actor_user_id AND lc.policy_type='terms_of_use' AND lc.policy_version='2026-08-26')
   AND EXISTS (SELECT 1 FROM public.legal_consents lc WHERE lc.user_id=p_actor_user_id AND lc.policy_type='privacy_policy' AND lc.policy_version='2026-08-26')
   AND EXISTS (SELECT 1 FROM public.legal_consents lc WHERE lc.user_id=p_actor_user_id AND lc.policy_type='community_guidelines' AND lc.policy_version='2026-08-26')
   AND NOT EXISTS (SELECT 1 FROM public.content_publish_checks pc WHERE pc.content_id=p_content_id AND pc.status IN ('failed','blocked','review','pending'));
 if not v_ok then raise exception 'publish_checks_failed'; end if;
 update public.contents set status='published', published_at=coalesce(published_at,now()), updated_at=now() where id=p_content_id;
 return true;
end;
$function$;
REVOKE ALL ON FUNCTION public.publish_content_secure_as_user(uuid,uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.publish_content_secure_as_user(uuid,uuid) TO service_role;