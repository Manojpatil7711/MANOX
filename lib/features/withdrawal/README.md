# Withdrawal feature

Purpose
- Allow creators to request payouts and track withdrawal statuses.

Planned responsibilities
- Withdrawal request UI, status tracking, request history.

Expected screens/components
- WithdrawalRequestScreen
- WithdrawalHistory

Expected repository/service dependencies
- WithdrawalRepository (server-authorized)
- ProfilePayoutsRepository
- Payments integration (server-side)

Security considerations (CRITICAL)
- Use idempotency for withdrawal requests to avoid duplicate payouts (idempotency_key).
- All status transitions (requested -> processing -> paid/rejected) must be enforced server-side.
- KYC/legal identity verification and payout credential handling must be server-side; never expose sensitive payout info in public endpoints.
- Do not perform balance adjustments client-side — server must validate and record ledger entries.
