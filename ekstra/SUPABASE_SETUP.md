# Supabase Setup Plan

Supabase remains optional. The app must continue to work fully local-first when Supabase is not configured.

## Required Environment
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SCHEMA`
- `SUPABASE_AUTH_REDIRECT_URL`

## Planned Tables
- `profiles`: user id, email, created_at.
- `overtime_entries`: user id, date, hours, type, multiplier, note, timestamps.
- `user_settings`: user id, hourly rate, salary settings, notification settings.
- `shift_templates`: user id, shift template data.
- `shift_assignments`: user id, assigned date/template data.
- `entitlements`: user id, product id, validation status, updated_at.

## Repository Rule
Remote repositories must implement the existing repository interfaces and keep UI code unchanged.

## Conflict Rule
Local data remains source of truth until the user explicitly signs in and chooses sync. First sync should offer:
- keep local data,
- replace local data with cloud data,
- merge local and cloud data.
