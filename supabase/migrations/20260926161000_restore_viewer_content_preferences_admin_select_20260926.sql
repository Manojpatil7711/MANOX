-- Restore intended platform-admin SELECT access on viewer_content_preferences.
-- The prior RLS consolidation removed this policy even though it was the
-- only SELECT path for platform admins. Owner access remains unchanged.
create policy prefs_owner_all
on public.viewer_content_preferences
as permissive
for select
to authenticated
using (
  (profile_id = (select current_profile_id()))
  or (select is_platform_admin())
);
