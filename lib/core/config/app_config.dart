class AppConfig {
  // Supabase publishable credentials are intended for client apps.
  // Row Level Security remains the authorization boundary.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kdkbefdxpiuwguejcpgy.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_A-aPiPNfTanCGpOD5gb2XQ_tpKsGCcK',
  );

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
