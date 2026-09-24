-- Lock safety notification dispatcher to service-role execution only.
REVOKE EXECUTE ON FUNCTION public.dispatch_safety_alert_notifications() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.dispatch_safety_alert_notifications() TO service_role;
