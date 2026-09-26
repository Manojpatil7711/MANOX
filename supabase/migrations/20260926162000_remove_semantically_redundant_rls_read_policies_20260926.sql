-- Remove SELECT policies fully covered by an existing ALL policy with the same
-- access predicate. Public/read-owner combinations intentionally remain intact.
drop policy if exists processing_owner_read on public.media_processing_jobs;
drop policy if exists platform_settings_owner_read on public.platform_settings;
