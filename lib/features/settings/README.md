# Settings feature

Purpose
- Application and account settings, privacy controls, and user preferences.

Planned responsibilities
- Settings screen, notification preferences, account management and privacy toggles.

Expected screens/components
- SettingsScreen
- AccountManagement / PrivacySettings

Expected repository/service dependencies
- ProfileRepository
- NotificationRepository

Security considerations
- Account changes that affect security (email, 2FA, password) must be validated server-side.
- Do not expose admin-only options to regular users.
