-- Tighten Data API grants on internal processing/payout tables.
REVOKE ALL ON TABLE public.payout_webhook_events FROM anon, authenticated;
REVOKE ALL ON TABLE public.media_processing_jobs FROM anon;
REVOKE ALL ON TABLE public.payout_jobs FROM anon;
REVOKE ALL ON TABLE public.media_assets FROM anon;
