# Creator feature

Purpose
- Tools and pages for creators to publish content, manage their audience and monetization settings.

Planned responsibilities
- Creator dashboard, content analytics, monetization settings.

Expected screens/components
- CreatorDashboard
- ContentManagementScreen
- MonetizationSettings

Expected repository/service dependencies
- PostRepository
- EarningsRepository
- ProfileRepository

Security considerations
- Monetization and payout configuration is sensitive — actions that change payout state must be server-authorized.
- Creator-specific endpoints must be protected by ownership RLS/policies.
