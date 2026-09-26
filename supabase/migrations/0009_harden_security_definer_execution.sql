-- Harden SECURITY DEFINER RPC execution grants.
REVOKE EXECUTE ON FUNCTION public.can_publish_content(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.claim_media_jobs(integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.enqueue_published_content(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.publish_content_secure(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.record_ranking_event(uuid,text,numeric) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.request_creator_withdrawal(bigint,uuid,text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.request_creator_withdrawal_internal(uuid,bigint,uuid,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.can_publish_content(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.claim_media_jobs(integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.enqueue_published_content(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;
GRANT EXECUTE ON FUNCTION public.publish_content_secure(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.record_ranking_event(uuid,text,numeric) TO service_role;
GRANT EXECUTE ON FUNCTION public.request_creator_withdrawal(bigint,uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.request_creator_withdrawal_internal(uuid,bigint,uuid,text) TO service_role;
