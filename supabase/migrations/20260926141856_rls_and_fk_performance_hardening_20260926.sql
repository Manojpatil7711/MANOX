-- 20260926141856_rls_and_fk_performance_hardening_20260926.sql
-- Add covering indexes for all current unindexed foreign keys and optimize
-- auth.uid() evaluation in high-traffic RLS policies.


DROP POLICY IF EXISTS safety_presence_owner ON public.safety_presence;
CREATE POLICY safety_presence_owner ON public.safety_presence FOR ALL TO authenticated
USING (profile_id = (select auth.uid()))
WITH CHECK (profile_id = (select auth.uid()));

DROP POLICY IF EXISTS safety_alert_insert_female ON public.safety_alerts;
CREATE POLICY safety_alert_insert_female ON public.safety_alerts FOR INSERT TO authenticated
WITH CHECK (
  source_profile_id = (select auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = source_profile_id
      AND lower(coalesce(p.gender,'')) = 'female'
  )
);

DROP POLICY IF EXISTS safety_alert_select_owner ON public.safety_alerts;
CREATE POLICY safety_alert_select_owner ON public.safety_alerts FOR SELECT TO authenticated
USING (
  source_profile_id = (select auth.uid())
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = (select auth.uid())
      AND lower(coalesce(p.safety_role,'')) IN ('police','social_worker')
      AND p.safety_role_verified = true
  )
);

DROP POLICY IF EXISTS contents_owner_insert ON public.contents;
CREATE POLICY contents_owner_insert ON public.contents FOR INSERT TO authenticated
WITH CHECK ((select auth.uid()) = owner_user_id AND status IN ('draft','ready'));

DROP POLICY IF EXISTS contents_owner_update ON public.contents;
CREATE POLICY contents_owner_update ON public.contents FOR UPDATE TO authenticated
USING ((select auth.uid()) = owner_user_id)
WITH CHECK ((select auth.uid()) = owner_user_id);

DROP POLICY IF EXISTS contents_owner_delete ON public.contents;
CREATE POLICY contents_owner_delete ON public.contents FOR DELETE TO authenticated
USING ((select auth.uid()) = owner_user_id);
