# MANOX Settings Navigation Implementation

The Settings screen must provide real navigation/actions instead of tap-only placeholders.

Required destinations/actions:
- Email & Account
- Password & Security
- Block Account
- Report Problem
- Community Guidelines
- Privacy Policy
- Add
- Monetiz Wallet
- Date & Time
- Chat
- Log out

Edit Profile remains the existing working destination.

Profile SAVE is tracked separately: the Flutter repository updates `profiles` (`display_name`, `username`, `bio`, optional `avatar_url`), so its database/RLS issue must be diagnosed independently from `profile_privacy` messaging columns.

DOB/Kids requirement to implement at the appropriate auth stage: collect real DOB during account creation; 7–15 routes to MANOX Kids; 16+ routes to main MANOX; DOB correction requires verification.
