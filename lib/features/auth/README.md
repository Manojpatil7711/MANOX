# Auth feature

Purpose
- Handle user authentication flows (sign in, sign up, magic links, social login) and onboarding hooks.

Planned responsibilities
- UI screens for login/signup, input validation, and integration with Supabase auth.
- Coordinate with repositories to fetch/create profiles after auth.
- Expose services for sign-in, sign-out, and session checks.

Expected screens/components
- LoginScreen
- SignupScreen
- PasswordResetScreen
- OAuth callback handlers

Expected repository/service dependencies
- ProfileRepository
- SupabaseService

Security considerations
- Never store raw credentials in source or logs.
- All sensitive auth decisions are server-side; client only initiates flows and handles tokens via secure storage.
