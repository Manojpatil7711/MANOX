# Notifications feature

Purpose
- Deliver and surface events (likes, follows, comments, system messages) to users.

Planned responsibilities
- Notification center, realtime subscriptions, read markers.

Expected screens/components
- NotificationsScreen
- NotificationItem component
- In-app badges and push integration hooks

Expected repository/service dependencies
- NotificationRepository
- Supabase real-time / subscriptions

Security considerations
- Notifications are user-targeted; only surface notifications for the recipient.
- Avoid leaking other users' activity beyond intended content.
