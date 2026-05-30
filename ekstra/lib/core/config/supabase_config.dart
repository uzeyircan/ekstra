class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  static const anonKey = publishableKey;
  static const schema = String.fromEnvironment(
    'SUPABASE_SCHEMA',
    defaultValue: 'public',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
