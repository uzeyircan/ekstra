# Release Checklist

## Flutter
- Run `flutter analyze`.
- Run `flutter test`.
- Build Android release with `flutter build appbundle --release`.
- Build iOS release on macOS with `flutter build ipa --release`.

## Android
- Confirm `applicationId`, version code, version name, and signing config.
- Confirm AdMob app id is production id before store upload.
- Confirm notification permission text and behavior on Android 13+.
- Test purchase restore and rewarded ads on an internal test track.

## iOS
- Confirm bundle identifier, display name, version, and build number.
- Confirm AdMob app id is production id before TestFlight.
- Confirm notification permission prompt and background behavior.
- Test purchases with Sandbox Apple ID.

## Privacy
- Publish privacy policy URL.
- Publish terms of use URL.
- Disclose local storage, optional account sync, ads, purchases, and notifications.

## Data Safety
- Verify local backup export/import.
- Verify overtime delete/restore history.
- Verify report export for monthly and yearly reports.
- Verify no onboarding loop and no data loss after hot restart.
