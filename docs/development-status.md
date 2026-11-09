# Development status — version 0.3.0

Last updated: 9 November 2026.

## Completed in the repository

- Single-software-developer work model and supporting hardware/QA responsibilities documented.
- Flutter shell with dashboard, controls, history, and settings sections.
- SQLite telemetry store schema and persistence implementation.
- Telemetry model preserving validity, event/device identity, measurement/receipt timestamps, time quality, and sequence number.
- Read-only API client for `GET /api/v1/devices/{deviceId}/telemetry/latest`.
- Dashboard refresh flow and backend/cached/offline/not-configured states.
- Per-reading age display; records older than two minutes are visibly labelled stale.
- History view backed by local SQLite records.
- Development bearer token accepted only by debug builds; production user authentication remains required.
- Backend latest-telemetry response extended with `event_id` and `device_id` and deterministic ordering.
- Controls remain disabled until secure user authorization, device acknowledgments, and physical feedback are available.

## Evidence reported from the user's PC

- Flutter 3.47.9 stable and Dart 3.13.7 detected by `flutter doctor -v`.
- Windows 11 and Android SDK 36.0.0 detected.
- Android SDK licenses accepted.
- `flutter pub get` resolved the initial starter dependencies.
- `flutter analyze` reported two informational `prefer_const_constructors` suggestions, which were addressed in this source version.
- `flutter test` could not start because Windows reported that Application Control policy blocked execution of `flutter_tester.exe`. This is not a failed test assertion.
- The user's VS Code status bar showed `No Device`; no Android phone was confirmed connected at the time of the screenshot.

These are user-provided observations from screenshots, not tests executed in this development container.

## Not yet verified

- Version 0.3.0 Flutter dependency resolution on the user's PC.
- `flutter analyze` on version 0.3.0.
- Widget and model tests (Windows test runner previously blocked by policy).
- Android debug build and physical-phone launch.
- SQLite read/write on Android.
- Local API reachability from Android through ADB reverse.
- Backend database and MQTT runtime.
- Actual ESP32 telemetry or any physical sensor readings.
- Pump/feeder actuation or feedback.
- LTE, FCM, SMS, failover, offline synchronization, AI recommendations, or production authentication.

## Current next gate

1. Replace the local repository with version 0.3.0 or merge its files exactly as documented.
2. Run `flutter pub get` in `mobile/`.
3. Run `flutter analyze` and record output.
4. Run `flutter devices`; connect a phone if no Android device is listed.
5. Attempt `flutter run` on Android.
6. Separately investigate the Code Integrity/AppLocker event blocking `flutter_tester.exe`; do not disable Windows security.
7. Once the app runs, verify empty-state UI and SQLite initialization before backend integration.
