// Supabase project configuration — tvonline-backend
class SupabaseConfig {
  static const String url = 'https://mltdegusepgyvniqsock.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1sdGRlZ3VzZXBneXZuaXFzb2NrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxMTYzMDEsImV4cCI6MjA5NDY5MjMwMX0'
      '.heW56vD_EXWdnYyQXNIZdgaUiB4vGjER4usocOT4eJM';

  // Storage bucket for payment proofs
  static const String proofsBucket = 'payment-proofs';

  // Admin email — receives notifications
  static const String adminEmail = 'azazelvatercr@gmail.com';
}
