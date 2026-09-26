-- Remove exact duplicate RLS policies identified during the 2026-09-26 audit.
-- These policies duplicated existing policy predicates/roles and were redundant.

DROP POLICY IF EXISTS reposts_user_all ON public.content_reposts;
DROP POLICY IF EXISTS payout_reconciliation_admin_manage ON public.payout_reconciliation_events;
DROP POLICY IF EXISTS user_notifications_owner_update ON public.user_notifications;
DROP POLICY IF EXISTS user_topics_owner_all ON public.user_topic_preferences;
