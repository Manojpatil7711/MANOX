# Environment and Development

Local run with Supabase (client-only, anon key)

- Install Flutter SDK matching pubspec.yaml.
- Start app using:

  flutter run --dart-define=SUPABASE_URL=https://<project>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon_key>

Important security notes

- Never store admin/service_role keys in client or repository.
- Earnings and withdrawal transitions are server-side only. Do not allow client-submitted balances to be trusted.
- If you want integration tests that call Supabase in CI, add SUPABASE_URL and SUPABASE_ANON_KEY as repository secrets and create CI steps accordingly. (CI/workflow creation is currently blocked and is an external blocker.)
