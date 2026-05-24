# ARCHITECTURE

## Structure
```text
lib/
  core/
    config/
    constants/
    routing/
    services/
    storage/
    theme/
  shared/
    widgets/
  features/
    onboarding/
    dashboard/
    overtime/
    reports/
    settings/
    shifts/
```

## Data Flow
1. UI reads Riverpod providers.
2. Controllers call repository interfaces.
3. Local repositories persist to Hive boxes.
4. Domain services calculate earnings and summaries.

## Local-First Persistence
- Hive boxes:
  - `entries`
  - `settings`
  - `shifts`
- Stored values are JSON-like maps to keep the MVP lightweight.

## Supabase Readiness
- `supabase_config.dart` and repository placeholder classes exist.
- Remote implementations must not change presentation code.

## UI Standards
- Dark navy background, orange and green accents, large readable numbers.
- Reusable cards and shells live in `shared/widgets`.
- Screens should be quick to scan and quick to operate.
