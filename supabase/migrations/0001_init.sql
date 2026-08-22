-- 0001_init.sql — Initial MANOX schema with RLS, constraints, and policies (atomic)
-- This migration is written to be executed as a single transaction so that
-- table creation and RLS/policy enabling occur together.

BEGIN;

-- Enable uuid extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Utility: update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PROFILES: internal profile id + mapping to auth.users(id)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL UNIQUE,
  username text UNIQUE,
  display_name text,
  avatar_url text,
  bio text,
  is_creator boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Attempt to add FK to auth.users(id). This may require elevated privileges on some hosts.
-- If this ALTER TABLE fails in your environment, add a follow-up migration run by an admin
-- with the statement below uncommented.
ALTER TABLE profiles
  ADD CONSTRAINT fk_profiles_user_id FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles (username);
CREATE TRIGGER profiles_updated_at_trg
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- PUBLIC PROFILE VIEW (only safe public fields)
CREATE OR REPLACE VIEW public_profiles AS
SELECT
  id,
  username,
  display_name,
  avatar_url,
  is_creator,
  created_at
FROM profiles;

-- PROFILE_PAYOUTS: sensitive payout/KYC data, server-only access
CREATE TABLE IF NOT EXISTS profile_payouts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  legal_name text,
  kyc_status text DEFAULT 'unverified',
  payout_metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_profile_payouts_profile ON profile_payouts (profile_id);
CREATE TRIGGER profile_payouts_updated_at_trg
BEFORE UPDATE ON profile_payouts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- POSTS
CREATE TABLE IF NOT EXISTS posts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content text,
  media jsonb,
  visibility text NOT NULL DEFAULT 'public',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (visibility IN ('public','private','unlisted'))
);
CREATE INDEX IF NOT EXISTS idx_posts_author ON posts (author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts (created_at);
CREATE TRIGGER posts_updated_at_trg
BEFORE UPDATE ON posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- FOLLOWS
CREATE TABLE IF NOT EXISTS follows (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  followee_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (follower_id, followee_id),
  CHECK (follower_id <> followee_id)
);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows (follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_followee ON follows (followee_id);

-- LIKES
CREATE TABLE IF NOT EXISTS likes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (post_id, profile_id)
);
CREATE INDEX IF NOT EXISTS idx_likes_post ON likes (post_id);
CREATE INDEX IF NOT EXISTS idx_likes_profile ON likes (profile_id);

-- NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  target_profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type text NOT NULL,
  payload jsonb,
  is_read boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notifications_target ON notifications (target_profile_id);

-- EARNINGS LEDGER (append-only for clients; server-authorized writes only)
CREATE TABLE IF NOT EXISTS earnings_ledger (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount numeric(12,2) NOT NULL CHECK (amount >= 0),
  currency char(3) NOT NULL DEFAULT 'USD' CHECK (char_length(currency) = 3),
  entry_type text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (status IN ('pending','available','paid','reversed'))
);
CREATE INDEX IF NOT EXISTS idx_earnings_profile ON earnings_ledger (profile_id);
CREATE INDEX IF NOT EXISTS idx_earnings_created_at ON earnings_ledger (created_at);
CREATE TRIGGER earnings_updated_at_trg
BEFORE UPDATE ON earnings_ledger
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- WITHDRAWAL REQUESTS
CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount numeric(12,2) NOT NULL CHECK (amount >= 0),
  currency char(3) NOT NULL DEFAULT 'USD' CHECK (char_length(currency) = 3),
  status text NOT NULL DEFAULT 'requested',
  idempotency_key text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (status IN ('requested','processing','paid','rejected'))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_withdrawals_idempotency_key ON withdrawal_requests (idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_withdrawals_profile ON withdrawal_requests (profile_id);
CREATE TRIGGER withdrawal_requests_updated_at_trg
BEFORE UPDATE ON withdrawal_requests
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ENABLE RLS AND ADD POLICIES (strict, explicit, server-authorized writes only where required)

-- Enable RLS on tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE earnings_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_payouts ENABLE ROW LEVEL SECURITY;

-- Profiles: owners may select/update their own profile rows; creation is server-handled
CREATE POLICY profiles_owner_select ON profiles FOR SELECT USING (user_id = auth.uid());
CREATE POLICY profiles_owner_update ON profiles FOR UPDATE USING (user_id = auth.uid());

-- Public profiles should be read via public_profiles view; keep profiles table protected.

-- Posts: allow public selects for public posts and owner modifications
CREATE POLICY posts_select_owner_or_public ON posts FOR SELECT USING (
  visibility = 'public' OR author_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);
CREATE POLICY posts_insert_authenticated_profile ON posts FOR INSERT WITH CHECK (
  author_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);
CREATE POLICY posts_update_owner ON posts FOR UPDATE USING (
  author_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
) WITH CHECK (
  author_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);
CREATE POLICY posts_delete_owner ON posts FOR DELETE USING (
  author_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);

-- Follows
CREATE POLICY follows_insert_owner ON follows FOR INSERT WITH CHECK (
  follower_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);
CREATE POLICY follows_delete_owner ON follows FOR DELETE USING (
  follower_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);

-- Likes
CREATE POLICY likes_insert_owner ON likes FOR INSERT WITH CHECK (
  profile_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);
CREATE POLICY likes_delete_owner ON likes FOR DELETE USING (
  profile_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);

-- Notifications: select only for the target profile
CREATE POLICY notifications_select_owner ON notifications FOR SELECT USING (
  target_profile_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);

-- Earnings: SELECT allowed for owner only; no client-side INSERT/UPDATE/DELETE policies
CREATE POLICY earnings_select_owner ON earnings_ledger FOR SELECT USING (
  profile_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);

-- Withdrawal requests: allow insert by authenticated owner; updates/deletes server-only
CREATE POLICY withdrawals_insert_owner ON withdrawal_requests FOR INSERT WITH CHECK (
  profile_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);
CREATE POLICY withdrawals_select_owner ON withdrawal_requests FOR SELECT USING (
  profile_id = (SELECT id FROM profiles WHERE user_id = auth.uid())
);

-- profile_payouts: no client policies -- server/admin only

COMMIT;
