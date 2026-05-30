# PROJECT MAP

## Root
- `AGENTS.md`: project working rules.
- `AI_CONTRACT.md`: product and architecture boundaries for AI-assisted work.
- `ARCHITECTURE.md`: current technical structure.
- `MONETIZATION_PRODUCTION.md`: Pro purchase, rewarded ad, and entitlement release checklist.
- `RELEASE_CHECKLIST.md`: Android/iOS release readiness checklist.
- `SUPABASE_SETUP.md`: future cloud sync schema and conflict plan.
- `.env.example`: future Supabase environment keys.

## Core
- `lib/core/routing/app_router.dart`: GoRouter routes and app shell.
- `lib/core/storage/hive_service.dart`: Hive initialization and boxes.
- `lib/core/theme/app_theme.dart`: premium dark theme.
- `lib/core/config/supabase_config.dart`: placeholder config.
- `lib/core/services/backup_service.dart`: local JSON backup export/import.

## Features
- `auth`: optional account/session boundary. Current default is guest local mode.
- `onboarding`: first-run setup for hourly rate and default multiplier.
- `dashboard`: primary monthly/yearly KPI view, Ekstra Radar insights, quick add chips, empty state, and calendar.
- `overtime`: models, repositories, providers, entry bottom sheet.
- `reports`: monthly daily-density chart and yearly month distribution summaries.
- `reports/domain/report_file_export_service.dart`: shareable PDF and CSV export bridge.
- `monetization`: Pro entitlement, feature gates, rewarded ad unlock flow, and purchase service.
- `notifications`: local notification planning and scheduling.
- `payroll`: salary estimate, payroll check, payroll lock, and work-time balance logic.
- `settings`: hourly rate, theme, shift toggle, account status, backup tools, and reset workflow.
- `shifts`: optional shift metadata infrastructure.

## Shared
- `shared/widgets`: reusable logo, cards, app shell, metric UI.
