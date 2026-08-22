# Home feature

Purpose
- Provide the primary feed/dashboard and entry point for the app.

Planned responsibilities
- Render feed of posts/content, navigation to detail screens, and core actions (like, follow).

Expected screens/components
- HomeFeedScreen
- PostList / PostCard components
- Quick actions and composer placeholder

Expected repository/service dependencies
- PostRepository
- ProfileRepository
- Media service (if required)

Security considerations
- Respect visibility settings; only surface posts allowed by RLS/policies.
- Do not assume client-side visibility decisions—fetch permissioned content from repositories.
