-- 20260926141856_rls_and_fk_performance_hardening_20260926.sql
-- Add covering indexes for all current unindexed foreign keys and optimize
-- auth.uid() evaluation in high-traffic RLS policies.

CREATE INDEX IF NOT EXISTS idx_ad_campaigns_advertiser_id ON public.ad_campaigns (advertiser_id);
CREATE INDEX IF NOT EXISTS idx_advertisers_owner_profile_id ON public.advertisers (owner_profile_id);
CREATE INDEX IF NOT EXISTS idx_content_appeals_action_id ON public.content_appeals (action_id);
CREATE INDEX IF NOT EXISTS idx_content_appeals_content_id ON public.content_appeals (content_id);
CREATE INDEX IF NOT EXISTS idx_content_appeals_reviewer_id ON public.content_appeals (reviewer_id);
CREATE INDEX IF NOT EXISTS idx_content_shares_profile_id ON public.content_shares (profile_id);
CREATE INDEX IF NOT EXISTS idx_content_views_viewer_id ON public.content_views (viewer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON public.conversations (created_by);
CREATE INDEX IF NOT EXISTS idx_creator_content_analytics_daily_content_id ON public.creator_content_analytics_daily (content_id);
CREATE INDEX IF NOT EXISTS idx_creator_distribution_events_content_id ON public.creator_distribution_events (content_id);
CREATE INDEX IF NOT EXISTS idx_creator_feed_transparency_content_id ON public.creator_feed_transparency (content_id);
CREATE INDEX IF NOT EXISTS idx_creator_reach_attribution_content_id ON public.creator_reach_attribution (content_id);
CREATE INDEX IF NOT EXISTS idx_creator_safety_actions_content_id ON public.creator_safety_actions (content_id);
CREATE INDEX IF NOT EXISTS idx_creator_topic_preferences_topic_id ON public.creator_topic_preferences (topic_id);
CREATE INDEX IF NOT EXISTS idx_creator_upload_jobs_draft_id ON public.creator_upload_jobs (draft_id);
CREATE INDEX IF NOT EXISTS idx_creator_vibes_viber_id ON public.creator_vibes (viber_id);
CREATE INDEX IF NOT EXISTS idx_direct_messages_sender_id ON public.direct_messages (sender_id);
CREATE INDEX IF NOT EXISTS idx_discovery_feedback_user_id ON public.discovery_feedback (user_id);
CREATE INDEX IF NOT EXISTS idx_discovery_impressions_content_id ON public.discovery_impressions (content_id);
CREATE INDEX IF NOT EXISTS idx_discovery_impressions_topic_id ON public.discovery_impressions (topic_id);
CREATE INDEX IF NOT EXISTS idx_discovery_impressions_user_id ON public.discovery_impressions (user_id);
CREATE INDEX IF NOT EXISTS idx_earning_adjustments_approved_by ON public.earning_adjustments (approved_by);
CREATE INDEX IF NOT EXISTS idx_earning_adjustments_earning_id ON public.earning_adjustments (earning_id);
CREATE INDEX IF NOT EXISTS idx_earning_eligible_events_content_id ON public.earning_eligible_events (content_id);
CREATE INDEX IF NOT EXISTS idx_engagement_reports_reporter_id ON public.engagement_reports (reporter_id);
CREATE INDEX IF NOT EXISTS idx_fraud_risk_events_viewer_id ON public.fraud_risk_events (viewer_id);
CREATE INDEX IF NOT EXISTS idx_media_playback_sessions_user_id ON public.media_playback_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_message_reports_message_id ON public.message_reports (message_id);
CREATE INDEX IF NOT EXISTS idx_message_reports_reporter_id ON public.message_reports (reporter_id);
CREATE INDEX IF NOT EXISTS idx_profile_reports_reporter_id ON public.profile_reports (reporter_id);
CREATE INDEX IF NOT EXISTS idx_topic_trending_snapshots_topic_id ON public.topic_trending_snapshots (topic_id);
CREATE INDEX IF NOT EXISTS idx_topics_parent_id ON public.topics (parent_id);
CREATE INDEX IF NOT EXISTS idx_trending_snapshots_content_id ON public.trending_snapshots (content_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_actor_id ON public.user_notifications (actor_id);
CREATE INDEX IF NOT EXISTS idx_user_topic_preferences_topic_id ON public.user_topic_preferences (topic_id);

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
