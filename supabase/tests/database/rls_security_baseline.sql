begin;

create extension if not exists pgtap with schema extensions;

select plan(17);

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

-- The app creates profiles directly with id = auth.uid(); guard this path.
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='profiles' and policyname='profiles_owner_insert' and cmd='INSERT'), 'authenticated profile creation policy exists');
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='profiles' and policyname='profiles_owner_insert' and cmd='INSERT' and with_check LIKE '%auth.uid%' and with_check LIKE '%id%'), 'profile insert policy binds created row to authenticated identity');
select ok(
  NOT EXISTS (select 1 from information_schema.columns where table_schema='public' and table_name='profiles' and column_name='user_id')
  OR EXISTS (select 1 from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='profiles' and t.tgname='manox_sync_profile_auth_identity_trg' and NOT t.tgisinternal),
  'legacy user_id schema has auth identity sync trigger'
);

-- Signup must not regress to random profile UUIDs on a clean migration replay.
select ok(
  position('INSERT INTO public.profiles (id, user_id, username, display_name)' in pg_get_functiondef('private.handle_new_user()'::regprocedure)) > 0
  AND position('INSERT INTO public.profiles (id, username, display_name)' in pg_get_functiondef('private.handle_new_user()'::regprocedure)) > 0,
  'auth signup creates profiles with auth UUID as profile id across both schema variants'
);


-- Feed comments must be usable by signed-in users without opening write access to others.
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='content_comments'), 'content_comments RLS enabled');
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='content_comments' and policyname='content_comments_visible_read' and cmd='SELECT'), 'visible comments SELECT policy exists');
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='content_comments' and policyname='content_comments_insert_own' and cmd='INSERT' and with_check LIKE '%auth.uid%'), 'comment insert is bound to authenticated author');
select ok(exists (select 1 from pg_policies where schemaname='public' and tablename='content_comments' and policyname='content_comments_delete_own' and cmd='DELETE' and qual LIKE '%auth.uid%'), 'comment deletion is limited to its author');
select ok(has_table_privilege('authenticated', 'public.content_comments', 'INSERT') and has_table_privilege('authenticated', 'public.content_comments', 'SELECT'), 'authenticated role has required comment table privileges');

select * from finish();
rollback;
