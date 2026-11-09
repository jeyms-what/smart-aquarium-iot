# Smart Aquarium IoT

**Project version:** 0.3.0  
**Target:** Demonstrable integrated MVP by 1 December 2026  
**Development model:** One software developer; two supporting members for hardware and QA/documentation.

This repository is the working Smart Aquarium capstone baseline. Version 0.3.0 adds the mobile telemetry data layer: SQLite persistence, a read-only API client for the existing latest-telemetry endpoint, cached/offline presentation, measurement freshness labels, and a local history view. It is not a completed or hardware-verified system.

## 1. Responsibilities

- **You — sole software developer:** Flutter/Dart, Node.js, MQTT, PostgreSQL, ESP-IDF, FCM/SMS, AI rules, integration, execute test cases, collect evidence, reproduce defects, maintain wiring/test documentation, and track requirements and releases. 

## 2. Version 0.3.0 implementation

### Mobile app

- SQLite database file `smart_aquarium.db` stores actual telemetry records and the last successful synchronization timestamp.
- A read-only HTTP API client requests `GET /api/v1/devices/{deviceId}/telemetry/latest`.
- The dashboard labels data source as backend, cached, offline, or not configured.
- Each measurement shows its recorded age. Readings older than two minutes are labelled stale; this is a display threshold, not a water-quality safety threshold.
- The history page reads locally persisted records.
- Controls remain locked until authentication, command acknowledgments, local safety checks, and physical state feedback are implemented.

### Backend

The latest telemetry response now includes `event_id` and `device_id`, which the mobile SQLite store needs for idempotent local persistence.

## 3. Install mobile dependencies

Use the Flutter/Dart installation already verified on your Windows PC. Your reported Dart version is 3.13.7; `sqflite 2.4.5` requires Dart 3.12 or newer.

In VS Code PowerShell:

```powershell
cd mobile
flutter pub get
flutter analyze
```

The application uses the `sqflite` plugin on Android/iOS and the `path` package to build the database path. The widget tests use the no-repository preview mode and do not open the native SQLite plugin. The archive intentionally does not contain a generated Android Gradle project; run `flutter create --platforms=android .` first so Flutter creates the platform files for your installed SDK.

## 4. Run without a backend first

Once an Android phone appears in `flutter devices`:

```powershell
cd mobile
flutter run
```

Without API configuration, the app must display an explicit not-configured state and no fabricated sensor readings. The local SQLite database is still initialized.

## 5. Connect to the local backend from a physical Android phone

The starter backend binds to `127.0.0.1` and should remain local-only. For a USB-connected Android phone, use ADB reverse rather than opening the API to the LAN:

```powershell
adb reverse tcp:8080 tcp:8080
```

For local development only, add a temporary backend `.env` file from `.env.example`, set a random `API_BEARER_TOKEN` of at least 32 characters, and start the backend. Do not commit `.env`.

Run the debug app with these build-time values:

```powershell
flutter run `
  --dart-define=AQUARIUM_API_BASE_URL=http://127.0.0.1:8080 `
  --dart-define=AQUARIUM_API_DEV_TOKEN=PASTE_YOUR_LOCAL_DEV_TOKEN `
  --dart-define=AQUARIUM_DEVICE_ID=aquarium_001
```

Replace the token placeholder locally. Do not paste your token into chat, screenshots, GitHub, or documentation.

After `flutter create --platforms=android .`, run these commands from the repository root:

```powershell
New-Item -ItemType Directory -Force mobile/android/app/src/debug | Out-Null
Copy-Item docs/templates/android-debug-AndroidManifest.xml mobile/android/app/src/debug/AndroidManifest.xml
```

This debug-only Android manifest permits HTTP to localhost for the ADB-reverse workflow. Release builds do not receive this override. The development bearer token is compiled into the debug app, so it must never be used in a release APK or on an internet-exposed server. A proper user login/session-token system with per-aquarium authorization is required before remote/public deployment.

A successful API call proves the backend endpoint was reachable. It does not prove the ESP32 is online. The dashboard therefore says “Backend reachable” rather than “Device connected.”

## 6. Testing

```powershell
cd mobile
flutter analyze
flutter test
```

The repository includes tests for valid telemetry parsing, invalid/null sensor values, required fields, and initial empty states. The earlier `flutter test` attempt on your PC was blocked by Windows Application Control when Windows tried to execute `flutter_tester.exe`. That is an operating-system policy issue, not a failed test assertion. Do not disable Windows security. Ask your administrator/IT support to review the matching Code Integrity or AppLocker event, or continue with Android builds while that is investigated.

Manual Android verification:

1. Launch the application with no API values; confirm the not-configured state.
2. Configure local API values; confirm the app reaches `/health`-independent telemetry endpoint only when refreshed.
3. With no telemetry stored on the backend, confirm no measurements are displayed.
4. Publish one test telemetry record through the backend only after clearly labelling it as test data; verify it appears and is cached.
5. Disable backend connectivity and refresh; confirm the last stored measurement remains labelled cached and its original measurement time is preserved.
6. Open History; confirm stored records are shown from SQLite.

Never use artificial test values as actual aquarium readings or present them as physical prototype evidence.

## 7. API response contract

The latest endpoint must return `event_id`, `device_id`, `sensor_code`, `measurement_value`, `measurement_unit`, `is_valid`, `measured_at`, `received_at`, `time_quality`, and `sequence_number` for each sensor record. The application rejects malformed records rather than silently inventing defaults.

## 8. Still unimplemented

- ESP32 sensor drivers and physical telemetry publication.
- Device heartbeat and definitive online/offline state.
- Command execution and physical feedback.
- User authentication suitable for release/public remote access.
- FCM and direct SMS.
- Wi-Fi/LTE failover and modem integration.
- Full offline event queue and bidirectional synchronization.
- Species profiles and offline recommendation rules.
- CSV export, analytics, and production hardening.

See `docs/development-status.md`, `docs/development-plan.md`, and `docs/mqtt-contract.md` for the project baseline and next milestones.
