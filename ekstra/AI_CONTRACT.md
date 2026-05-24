# AI CONTRACT

## Product Boundaries
- EKSTRA tracks overtime entries, summaries, settings, and optional shift metadata.
- First release is fully local using Hive.
- Supabase is placeholder-only until explicitly implemented.

## Business Logic Contract
- `dailyEarning = hours * hourlyRate * multiplier`.
- `OvertimeType.normal`, `weekend`, and `holiday` each carry multiplier support.
- Monthly and yearly totals must be derived from entries, not stored as source of truth.
- Settings defaults: hourly rate `0`, default multiplier `1.5`, currency `TRY`.

## Architecture Contract
- `domain`: models, repository contracts, calculation services.
- `data`: local repository implementations and future remote placeholders.
- `presentation`: screens, widgets, controllers/providers.
- Any future Supabase implementation must satisfy existing repository interfaces.

## Change Safety
- Do not hardcode one-off hacks into UI.
- Keep destructive data actions explicit and confirmed.
- Update `PROJECT_MAP.md` when adding notable folders or modules.
