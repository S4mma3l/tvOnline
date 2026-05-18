// Values injected at build time via --dart-define-from-file=env.json
// Never hardcode credentials here. See env.example.json for the required keys.
class SupabaseConfig {
  static const String url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static const String anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const String proofsBucket = 'payment-proofs';
  static const String adminEmail = 'azazelvatercr@gmail.com';
}
