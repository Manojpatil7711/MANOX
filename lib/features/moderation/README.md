# Moderation feature

Purpose
- Tools for content and user moderation, handling reports, takedowns and appeals.

Planned responsibilities
- Moderator UI, report queues, action audit trails.

Expected screens/components
- ModerationQueue
- ReportDetail
- ActionAuditLog

Expected repository/service dependencies
- ModerationRepository (server-enforced actions)
- NotificationRepository (for user alerts)

Security considerations (CRITICAL)
- Moderation actions require strict authorization and robust auditability.
- All enforcement must be performed server-side and be logged for audit.
- Avoid exposing sensitive moderator tooling to unauthorized users.
