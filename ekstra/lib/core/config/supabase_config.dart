class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const schema = String.fromEnvironment(
    'SUPABASE_SCHEMA',
    defaultValue: 'public',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
