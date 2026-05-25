# PROJECT MAP

## Root
- `AGENTS.md`: project working rules.
- `AI_CONTRACT.md`: product and architecture boundaries for AI-assisted work.
- `ARCHITECTURE.md`: current technical structure.
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
- `settings`: hourly rate, theme, shift toggle, account status, backup tools, and reset workflow.
- `shifts`: optional shift metadata infrastructure.

## Shared
- `shared/widgets`: reusable logo, cards, app shell, metric UI.
