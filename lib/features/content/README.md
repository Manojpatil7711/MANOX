# Content feature

Purpose
- Content creation, editing, and rendering (posts, media, rich text).

Planned responsibilities
- Content editor, attachments upload, content moderation hooks.

Expected screens/components
- ContentEditor
- ContentDetailScreen
- MediaPicker / Upload components

Expected repository/service dependencies
- PostRepository
- Media upload service
- Moderation service

Security considerations
- Sanitize user-supplied content before rendering.
- Client should not make moderation or policy decisions—server must enforce moderation rules and audit logs.
