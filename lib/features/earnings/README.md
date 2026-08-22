# Earnings feature

Purpose
- Track and present creator earnings and balances.

Planned responsibilities
- Show earnings ledger, available balance, payouts history, and simple reporting.

Expected screens/components
- EarningsOverview
- EarningsHistory / Ledger entries

Expected repository/service dependencies
- EarningsRepository (server-authorized)
- ProfileRepository
- Payout/reconciliation service

Security considerations (CRITICAL)
- Ledger writes must be server-authorized only; clients MUST NOT be able to insert/update/delete ledger entries.
- Use an append-only accounting model where possible and reconcile with server jobs.
- Protect sensitive earnings/payout data; only show aggregated or authorized detail to owners.
