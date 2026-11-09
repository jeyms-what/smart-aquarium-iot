# MQTT and HTTP contract — v1 draft

This is the shared interface contract. It is a draft for the first integration sprint; agree on changes before implementing the same field differently in firmware and backend.

## Topic names

Device ID is restricted to letters, digits, underscore, and hyphen.

| Topic | Publisher | Subscriber | Purpose |
|---|---|---|---|
| `aquarium/{deviceId}/telemetry` | Device | Backend | Sensor readings |
| `aquarium/{deviceId}/state` | Device | Backend | Actuator/controller state |
| `aquarium/{deviceId}/alerts` | Device | Backend | Alert events |
| `aquarium/{deviceId}/network` | Device | Backend | Wi-Fi/LTE health and selected uplink |
| `aquarium/{deviceId}/availability` | Device/LWT | Backend | Online/offline state |
| `aquarium/{deviceId}/cmd/request` | Backend | Device | Target-state command |
| `aquarium/{deviceId}/cmd/ack` | Device | Backend | Command result and feedback |

Use QoS 1 for alert/command/ack messages. Telemetry QoS may be selected based on sampling and bandwidth behavior. Retain only latest state/availability where appropriate; do not retain commands.

## Telemetry payload

```json
{
  "schema_version": 1,
  "device_id": "aquarium_001",
  "event_id": "b9b8b10d-2f15-47ca-a3e4-d15e5e58e6f2",
  "sequence": 1025,
  "measured_at": "2026-11-09T01:00:00.000Z",
  "time_quality": "rtc_synced",
  "readings": {
    "water_temperature": { "value": 25.4, "unit": "degC", "valid": true },
    "water_level": { "value": 12.1, "unit": "cm", "valid": true },
    "turbidity": { "value": 0.0, "unit": "raw_adc", "valid": false }
  }
}
```

The values above are **illustrative contract examples only**, not prototype measurements. A device must transmit only actual readings. If a sensor is unavailable or invalid, send `value: null` and `valid: false`. Do not interpret raw ADC as calibrated NTU.

## Command payload

```json
{
  "command_id": "b9b8b10d-2f15-47ca-a3e4-d15e5e58e6f2",
  "device_id": "aquarium_001",
  "command": "SET_PUMP",
  "requested_state": "OFF",
  "issued_at": "2026-11-09T01:00:00.000Z",
  "expires_at": "2026-11-09T01:00:30.000Z"
}
```

Illustrative example only. Device must validate ID, target, allowlist, expiration, and local safety interlocks. Reject expired commands; never replay stale commands after connectivity returns.

## Command acknowledgment

```json
{
  "command_id": "b9b8b10d-2f15-47ca-a3e4-d15e5e58e6f2",
  "device_id": "aquarium_001",
  "status": "executed",
  "state_verified": false,
  "resulting_state": { "pump": "unknown" },
  "occurred_at": "2026-11-09T01:00:02.000Z"
}
```

Illustrative example only. Until an independent physical feedback mechanism exists, `state_verified` must remain false and UI must not claim the equipment is confirmed ON/OFF.

## Initial REST endpoints

- `GET /health` — unprotected service health, no secrets returned.
- `GET /api/v1/devices/{id}/telemetry/latest` — latest persisted measurement per sensor (Bearer token required).
- `GET /api/v1/devices/{id}/commands/{commandId}` — command status (Bearer token required).
- `POST /api/v1/devices/{id}/commands` — request `SET_PUMP` or `FEED_NOW` (Bearer token required).

The starter uses one development API bearer token. Replace it with user authentication and aquarium-level authorization before production or internet exposure.

## Latest telemetry response fields (mobile integration, v0.3.0)

Each item in `readings` includes:

- `event_id`
- `device_id`
- `sensor_code`
- `measurement_value`
- `measurement_unit`
- `is_valid`
- `measured_at`
- `received_at`
- `time_quality`
- `sequence_number`

The mobile client uses `event_id` + `sensor_code` as the local SQLite uniqueness key. It uses `measured_at` for measurement freshness; `received_at` is when the backend persisted the record. A successful HTTP response does not itself prove that the ESP32 is currently online.
