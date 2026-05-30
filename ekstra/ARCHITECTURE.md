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
    auth/
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
  - `auth`
  - `entries`
  - `entry_snapshots`
  - `entry_archive`
  - `integrity`
  - `settings`
  - `shifts`
- Stored values are JSON-like maps to keep the MVP lightweight.
- Overtime writes maintain snapshots, archives, audit events, and a local digest check.
- Entitlements are signed locally to catch accidental or simple local tampering. Production still needs server-side receipt validation.

## Supabase Readiness
- `supabase_config.dart` and repository placeholder classes exist.
- Remote implementations must not change presentation code.
- Auth is modeled through `AuthRepository`; current implementation keeps users in guest/local mode until Supabase is wired.
- Overtime persistence uses write-through snapshots and delete archives. Empty primary storage can self-heal from the latest valid snapshot unless the latest snapshot represents an intentional empty state.

## Monetization
- Feature access is centralized in `FeatureGate`.
- Rewarded ads are always user-initiated and never shown automatically.
- `PurchaseService` owns store purchase and restore calls.
- `EntitlementService` owns Pro state mutations.

## Report Export
- Report text/CSV composition lives in `ReportExportService`.
- Shareable PDF/CSV file generation lives in `ReportFileExportService`.
- UI screens only request export after the Pro/rewarded gate passes.

## UI Standards
- Dark navy background, orange and green accents, large readable numbers.
- Reusable cards and shells live in `shared/widgets`.
- Screens should be quick to scan and quick to operate.
