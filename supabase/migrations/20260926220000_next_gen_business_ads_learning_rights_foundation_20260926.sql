-- MANOX next-generation business advertising, learning subscriptions, and media-rights foundations.
-- Data contracts are created before billing/serving/provider integrations so later features
-- can be added without reshaping the production schema.

create table if not exists public.business_ad_plans (
  code text primary key, name text not null, monthly_price_minor bigint not null default 0 check (monthly_price_minor >= 0),
  max_active_campaigns integer not null default 1 check (max_active_campaigns > 0),
  max_locations_per_campaign integer not null default 1 check (max_locations_per_campaign > 0),
  created_at timestamptz not null default now()
);
create table if not exists public.business_ad_subscriptions (
  id uuid primary key default gen_random_uuid(), advertiser_id uuid not null references public.advertisers(id) on delete cascade,
  plan_code text not null references public.business_ad_plans(code),
  status text not null default 'trial' check (status in ('trial','active','past_due','paused','cancelled','expired')),
  current_period_start timestamptz not null default now(), current_period_end timestamptz,
  provider_customer_id text, provider_subscription_id text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists business_ad_subscriptions_provider_subscription_uidx on public.business_ad_subscriptions(provider_subscription_id) where provider_subscription_id is not null;
create index if not exists business_ad_subscriptions_advertiser_idx on public.business_ad_subscriptions(advertiser_id, status);
alter table public.ad_campaigns add column if not exists subscription_id uuid references public.business_ad_subscriptions(id);
create index if not exists ad_campaigns_subscription_idx on public.ad_campaigns(subscription_id);
create table if not exists public.ad_campaign_targets (
  id uuid primary key default gen_random_uuid(), campaign_id uuid not null references public.ad_campaigns(id) on delete cascade,
  target_type text not null check (target_type in ('country','region','city','postal_code','radius')),
  country_code text, region_code text, city_name text, postal_code text, latitude double precision, longitude double precision, radius_km numeric(8,2),
  include boolean not null default true, created_at timestamptz not null default now(),
  constraint ad_campaign_targets_geo_check check (
    (target_type = 'country' and country_code is not null and region_code is null and city_name is null and postal_code is null and latitude is null and longitude is null and radius_km is null)
    or (target_type = 'region' and country_code is not null and region_code is not null and city_name is null and postal_code is null and latitude is null and longitude is null and radius_km is null)
    or (target_type = 'city' and country_code is not null and city_name is not null and latitude is null and longitude is null and radius_km is null)
    or (target_type = 'postal_code' and country_code is not null and postal_code is not null and latitude is null and longitude is null and radius_km is null)
    or (target_type = 'radius' and latitude is not null and longitude is not null and radius_km is not null and radius_km > 0)
  )
);
create index if not exists ad_campaign_targets_campaign_idx on public.ad_campaign_targets(campaign_id);
create index if not exists ad_campaign_targets_city_idx on public.ad_campaign_targets(country_code, city_name) where target_type = 'city';
create index if not exists ad_campaign_targets_region_idx on public.ad_campaign_targets(country_code, region_code) where target_type = 'region';

create table if not exists public.teacher_learning_plans (
  code text primary key, name text not null, monthly_price_minor bigint not null default 0 check (monthly_price_minor >= 0),
  max_active_courses integer not null default 1 check (max_active_courses > 0), created_at timestamptz not null default now()
);
create table if not exists public.teacher_learning_subscriptions (
  id uuid primary key default gen_random_uuid(), teacher_profile_id uuid not null references public.profiles(id) on delete cascade,
  plan_code text not null references public.teacher_learning_plans(code),
  status text not null default 'trial' check (status in ('trial','active','past_due','paused','cancelled','expired')),
  current_period_start timestamptz not null default now(), current_period_end timestamptz,
  provider_customer_id text, provider_subscription_id text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists teacher_learning_subscriptions_provider_uidx on public.teacher_learning_subscriptions(provider_subscription_id) where provider_subscription_id is not null;
create index if not exists teacher_learning_subscriptions_teacher_idx on public.teacher_learning_subscriptions(teacher_profile_id, status);

create table if not exists public.media_audio_analysis (
  media_asset_id uuid primary key references public.media_assets(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','processing','passed','needs_review','failed')),
  loudness_lufs numeric(7,3), true_peak_db numeric(7,3), clipping_ratio numeric(10,8) check (clipping_ratio is null or clipping_ratio between 0 and 1),
  sample_rate_hz integer check (sample_rate_hz is null or sample_rate_hz > 0), channels smallint check (channels is null or channels > 0),
  clarity_score numeric(5,2) check (clarity_score is null or clarity_score between 0 and 100), analyzer_version text, analyzed_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.media_rights_checks (
  id uuid primary key default gen_random_uuid(), media_asset_id uuid not null references public.media_assets(id) on delete cascade,
  check_type text not null check (check_type in ('music_copyright','audio_fingerprint','visual_rights','duplicate_content')),
  status text not null default 'pending' check (status in ('pending','processing','clear','claim','blocked','needs_review','error')),
  provider text, provider_reference text, matched_asset_reference text, confidence numeric(5,2) check (confidence is null or confidence between 0 and 100),
  claim_type text, action text check (action is null or action in ('none','monetize','mute','restrict','block','review')),
  details jsonb not null default '{}'::jsonb, checked_at timestamptz, created_at timestamptz not null default now()
);
create index if not exists media_rights_checks_asset_idx on public.media_rights_checks(media_asset_id, check_type, created_at desc);

insert into public.business_ad_plans(code,name,monthly_price_minor,max_active_campaigns,max_locations_per_campaign)
values ('business_starter','Business Starter',99900,1,3),('business_growth','Business Growth',249900,5,15),('business_pro','Business Pro',499900,20,50)
on conflict (code) do nothing;
insert into public.teacher_learning_plans(code,name,monthly_price_minor,max_active_courses)
values ('teacher_starter','Teacher Starter',49900,1),('teacher_growth','Teacher Growth',99900,5),('teacher_pro','Teacher Pro',199900,20)
on conflict (code) do nothing;

alter table public.business_ad_plans enable row level security;
alter table public.business_ad_subscriptions enable row level security;
alter table public.ad_campaign_targets enable row level security;
alter table public.teacher_learning_plans enable row level security;
alter table public.teacher_learning_subscriptions enable row level security;
alter table public.media_audio_analysis enable row level security;
alter table public.media_rights_checks enable row level security;

drop policy if exists business_ad_plans_read on public.business_ad_plans;
create policy business_ad_plans_read on public.business_ad_plans for select to authenticated using (true);
drop policy if exists teacher_learning_plans_read on public.teacher_learning_plans;
create policy teacher_learning_plans_read on public.teacher_learning_plans for select to authenticated using (true);
drop policy if exists business_ad_subscriptions_owner_all on public.business_ad_subscriptions;
create policy business_ad_subscriptions_owner_all on public.business_ad_subscriptions for all to authenticated
using (exists (select 1 from public.advertisers a where a.id = business_ad_subscriptions.advertiser_id and a.owner_profile_id = (select auth.uid())))
with check (exists (select 1 from public.advertisers a where a.id = business_ad_subscriptions.advertiser_id and a.owner_profile_id = (select auth.uid())));
drop policy if exists ad_campaign_targets_owner_all on public.ad_campaign_targets;
create policy ad_campaign_targets_owner_all on public.ad_campaign_targets for all to authenticated
using (exists (select 1 from public.ad_campaigns c join public.advertisers a on a.id = c.advertiser_id where c.id = ad_campaign_targets.campaign_id and a.owner_profile_id = (select auth.uid())))
with check (exists (select 1 from public.ad_campaigns c join public.advertisers a on a.id = c.advertiser_id where c.id = ad_campaign_targets.campaign_id and a.owner_profile_id = (select auth.uid())));
drop policy if exists teacher_learning_subscriptions_owner_all on public.teacher_learning_subscriptions;
create policy teacher_learning_subscriptions_owner_all on public.teacher_learning_subscriptions for all to authenticated
using (teacher_profile_id = (select auth.uid())) with check (teacher_profile_id = (select auth.uid()));
drop policy if exists media_audio_analysis_owner_read on public.media_audio_analysis;
create policy media_audio_analysis_owner_read on public.media_audio_analysis for select to authenticated
using (exists (select 1 from public.media_assets ma join public.contents c on c.id = ma.content_id where ma.id = media_audio_analysis.media_asset_id and c.owner_user_id = (select auth.uid())));
drop policy if exists media_rights_checks_owner_read on public.media_rights_checks;
create policy media_rights_checks_owner_read on public.media_rights_checks for select to authenticated
using (exists (select 1 from public.media_assets ma join public.contents c on c.id = ma.content_id where ma.id = media_rights_checks.media_asset_id and c.owner_user_id = (select auth.uid())));

revoke all on table public.business_ad_plans from anon;
revoke all on table public.business_ad_subscriptions from anon;
revoke all on table public.ad_campaign_targets from anon;
revoke all on table public.teacher_learning_plans from anon;
revoke all on table public.teacher_learning_subscriptions from anon;
revoke all on table public.media_audio_analysis from anon;
revoke all on table public.media_rights_checks from anon;
