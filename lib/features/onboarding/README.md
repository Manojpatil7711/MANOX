# Onboarding feature

Purpose
- Guide new users through initial setup and product introduction.

Planned responsibilities
- Multi-step onboarding flows, optional tutorials, feature opt-ins.
- Collect minimal profile setup information and preferences.

Expected screens/components
- WelcomeScreen
- ProfileSetupScreen
- PreferencesScreen

Expected repository/service dependencies
- ProfileRepository
- Analytics/telemetry services (opt-in respectful)

Security considerations
- Avoid capturing unnecessary PII during onboarding.
- Defer KYC/payout capture to server-authorized flows.
