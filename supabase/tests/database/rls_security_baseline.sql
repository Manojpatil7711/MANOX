begin;

create extension if not exists pgtap with schema extensions;

select plan(8);

-- Core application tables must keep RLS enabled.
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='profiles'), 'profiles RLS enabled');
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='contents'), 'contents RLS enabled');
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='media_assets'), 'media_assets RLS enabled');
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='saved_contents'), 'saved_contents RLS enabled');
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='withdrawal_requests'), 'withdrawal_requests RLS enabled');

-- Sensitive policies must remain present after consolidation.
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='viewer_content_preferences' and policyname='prefs_owner_all' and cmd='SELECT'), 'viewer preferences owner/admin SELECT policy exists');
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='media_processing_jobs' and policyname='media_jobs_owner_read' and cmd='SELECT'), 'media processing owner read policy exists');
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='platform_settings' and policyname='platform_settings_owner_write' and cmd='ALL'), 'platform settings owner policy exists');

select * from finish();
rollback;
