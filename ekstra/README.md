# EKSTRA

Local-first Flutter overtime, shift, salary and extra income tracker.

## Run

```powershell
flutter.bat pub get
flutter.bat run -d chrome --web-port 5173 --dart-define-from-file=.env
```

Using a fixed web port matters while testing in Chrome. Hive web storage is
scoped to the browser origin, including the port. If Flutter opens a new random
port, previous local data may look empty even though it belongs to another
`localhost` origin.

For Android:

```powershell
flutter.bat devices
flutter.bat run -d <device_id> --dart-define-from-file=.env
```

## Supabase Auth

Supabase is enabled when both values are provided at build/run time:

```bash
flutter run \
  --dart-define-from-file=.env
```

The local `.env` file should include:

```text
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
SUPABASE_SCHEMA=public
```

Without these values, EKSTRA falls back to local-only account mode. Local
overtime, shift and settings data are not deleted when switching between
guest, local account, or Supabase account modes.

Before enabling cloud backup, run this SQL in the Supabase SQL editor:

```text
supabase/sql/001_user_cloud_backups.sql
```

The table uses Row Level Security so each authenticated user can read and write
only their own cloud backup.

## Verify

```powershell
flutter.bat analyze --no-pub
flutter.bat test --no-pub
```

## Persistence

- Guest mode stores data locally with Hive.
- Account mode preserves existing local data. Cloud backup is triggered manually
  from Settings.
- Mesai reset requires explicit confirmation in settings.
- Settings includes JSON backup export/import through the clipboard.
- Overtime entries are protected with local snapshots and delete archives.
- Settings can restore the latest non-empty mesai backup if local data is accidentally cleared.

## Differentiation

Dashboard includes `Ekstra Radar`, a local insight layer that shows projected
monthly earnings, active overtime streak, average overtime per entry, and the
busiest day. This keeps the product focused on income rhythm rather than only
raw hour entry.

## Android Icon

Android launcher icons are generated from:

```text
assets/logo/ekstra_app_icon.png
```

Generated files live under:

```text
android/app/src/main/res/mipmap-*/ic_launcher.png
```
