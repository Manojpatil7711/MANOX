# Profile feature

Purpose
- User profile display and editing, public profile access and account settings.

Planned responsibilities
- Profile view, edit profile screen, public profile view, follow/follower lists.

Expected screens/components
- ProfileScreen
- EditProfileScreen
- PublicProfileScreen
- FollowersList / FollowingList

Expected repository/service dependencies
- ProfileRepository
- SupabaseService

Security considerations
- Users may update only their own profiles — enforce on server via RLS/policies.
- Public profile information should be read from a safe view (e.g., public_profiles).
- Do not expose payout / KYC data in public profile endpoints.
