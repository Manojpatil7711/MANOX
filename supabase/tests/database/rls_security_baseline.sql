begin;

create extension if not exists pgtap with schema extensions;

select plan(8);

-- Core application tables must keep RLS enabled.
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='profiles'), 'profiles RLS enabled');
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='posts'), 'posts RLS enabled');
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='follows'), 'follows RLS enabled');
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='likes'), 'likes RLS enabled');
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='withdrawal_requests'), 'withdrawal_requests RLS enabled');

-- Baseline policies must remain present on the actual schema.
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='profiles' and policyname='profiles_owner_select' and cmd='SELECT'), 'profiles owner SELECT policy exists');
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='posts' and policyname='posts_select_owner_or_public' and cmd='SELECT'), 'posts owner/public SELECT policy exists');
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='notifications' and policyname='notifications_select_owner' and cmd='SELECT'), 'notifications owner SELECT policy exists');

select * from finish();
rollback;
