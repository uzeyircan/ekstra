# AI CONTRACT

## Product Boundaries
- EKSTRA tracks overtime entries, summaries, settings, and optional shift metadata.
- First release is fully local using Hive by default.
- Supabase auth/sync is optional and placeholder-only until credentials and schema are provided.

## Business Logic Contract
- `dailyEarning = hours * hourlyRate * multiplier`.
- `OvertimeType.normal`, `weekend`, and `holiday` each carry multiplier support.
- Monthly and yearly totals must be derived from entries, not stored as source of truth.
- Settings defaults: hourly rate `0`, default multiplier `1.5`, currency `TRY`.
- Default multiplier is selected during onboarding. It is not a primary settings UI field. Overtime multiplier is still selectable per entry.
- Guest users keep all data local. Authenticated users will use sync repositories once Supabase is implemented.
- Backup export/import must use the existing domain model serialization.
- Every local overtime mutation must preserve a recoverable snapshot/archive before destructive state can be observed by the user.
- Dashboard differentiation is built around `Ekstra Radar`: projected monthly earnings, active streak, average overtime, and busiest day.

## Architecture Contract
- `domain`: models, repository contracts, calculation services.
- `data`: local repository implementations and future remote placeholders.
- `presentation`: screens, widgets, controllers/providers.
- Any future Supabase implementation must satisfy existing repository interfaces.
- Optional auth must never block daily overtime entry.

## Change Safety
- Do not hardcode one-off hacks into UI.
- Keep destructive data actions explicit and confirmed.
- Update `PROJECT_MAP.md` when adding notable folders or modules.
