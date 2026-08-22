# Services

Purpose
- Thin wrappers for external services (SupabaseService, media upload, payments client).

Responsibilities
- Initialize and expose clients.
- Provide safe helpers used by repositories and features.

Security considerations
- Do not embed secrets in code. Use environment variables and server-side secure storage.
