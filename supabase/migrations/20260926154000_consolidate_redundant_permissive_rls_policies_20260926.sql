-- Consolidate policies whose access was already fully covered by a broader
-- policy on the same table/operation. No intended access is removed.
-- Verified against pg_policies on 2026-09-26.

DROP POLICY IF EXISTS media_assets_owner_read ON public.media_assets;
DROP POLICY IF EXISTS notifications_owner_read ON public.user_notifications;
DROP POLICY IF EXISTS prefs_owner_all ON public.viewer_content_preferences;
DROP POLICY IF EXISTS viewer_preferences_owner_all ON public.viewer_content_preferences;
