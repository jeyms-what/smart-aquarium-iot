# Flutter mobile telemetry data layer — v0.3.0

## Scope

Version 0.3.0 implements the read-only telemetry path:

`Node.js latest-telemetry endpoint → Flutter API client → telemetry parser → SQLite cache → dashboard/history`

It intentionally does not implement remote actuator commands, user login, notification delivery, sensor configuration, or AI recommendations.

## Key files

| File | Responsibility |
|---|---|
| `mobile/lib/core/config/app_config.dart` | Debug-only build-time API URL, device ID, and local development token |
| `mobile/lib/data/models/telemetry_reading.dart` | Validated API/SQLite telemetry model and display helpers |
| `mobile/lib/data/local/telemetry_store.dart` | SQLite schema, idempotent inserts, latest-record lookup, history, sync metadata |
| `mobile/lib/data/remote/telemetry_api_client.dart` | Authenticated read-only HTTP request and response validation |
| `mobile/lib/data/repositories/aquarium_repository.dart` | Coordinates API retrieval and local persistence |
| `mobile/lib/features/monitoring/monitoring_controller.dart` | Loading, refresh, cache fallback, and UI state |
| `mobile/lib/features/dashboard/dashboard_screen.dart` | Actual/cached/unavailable readings and freshness labels |
| `mobile/lib/features/history/history_screen.dart` | Local telemetry history |

## Local SQLite schema

`telemetry_samples` stores:

- `event_id`, `device_id`, and `sensor_code`
- nullable `measurement_value`
- `measurement_unit` and `is_valid`
- `measured_at` and `received_at`
- `time_quality` and `sequence_number`

`UNIQUE(event_id, sensor_code)` prevents the same telemetry event/sensor pair from being inserted more than once. Invalid sensor records are still stored for diagnosis but are never displayed as valid numeric readings.

`sync_metadata` stores the last successful backend refresh timestamp per device. This is not a device-online heartbeat.

## Remote API contract

`GET /api/v1/devices/{deviceId}/telemetry/latest`

Required response root fields:

- `device_id`
- `readings` array

Each reading must include `event_id`, `device_id`, `sensor_code`, `measurement_value`, `measurement_unit`, `is_valid`, `measured_at`, `received_at`, `time_quality`, and `sequence_number`.

The backend now selects `event_id` and `device_id` and orders latest records by `measured_at DESC, sequence_number DESC` for deterministic selection.

## Data-source states

- **Backend reachable:** API request succeeded. This does not prove that an ESP32 heartbeat is current.
- **Cached:** the app is displaying previously saved SQLite records.
- **Offline:** the API failed and no cached records are available.
- **Not configured:** development API parameters are absent or disabled.

A valid reading older than two minutes is labelled stale. This two-minute threshold is a UI freshness default only; it must not be used as a fish-health or actuator safety threshold. A record with `uptime_only` time quality is not assigned an age because its wall-clock timestamp is unverified.

## Local-only Android connection

The local Node API listens on `127.0.0.1:8080`. With an Android phone connected over USB and ADB enabled:

```powershell
adb reverse tcp:8080 tcp:8080
```

The app calls `http://127.0.0.1:8080`. The temporary development API token is compiled into the debug build only and the API client rejects non-loopback hosts. Never use this mechanism for a public or release build. Implement user authentication, scoped authorization, TLS, refresh/revocation, and server-side session management before remote deployment.

## Verification sequence

1. Run `flutter pub get` and `flutter analyze` in `mobile/`.
2. Run `flutter test` if Windows permits `flutter_tester.exe` to execute.
3. Launch on an Android phone with no API defines; confirm not-configured state and no fabricated readings.
4. Configure the local API debug defines; confirm backend reachability with zero telemetry.
5. After real device telemetry exists, confirm the same event ID appears in PostgreSQL/API and local SQLite.
6. Disable backend access; confirm cached data stays visible and is labelled cached/stale as appropriate.
7. Open History and verify local records are visible.

Any injected fixture used for tests must be identified as test data and must not be represented as a real aquarium measurement.
