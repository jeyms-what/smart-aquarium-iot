# MVP acceptance test matrix

**Execution status at repository revision 0.2.0:** Not run by the user yet.  
**Rule:** Record actual date/time, tester, software commit, exact hardware revision, actual result, and evidence for every executed test. Do not mark PASS from code inspection alone.

Status values: `PASS`, `FAIL`, `BLOCKED`, `NOT RUN`.

| ID | Priority | Test | Preconditions | Expected result | Current status |
|---|---|---|---|---|---|
| ENV-001 | P0 | Run `flutter doctor -v` on Windows | Flutter installed | Flutter and Android toolchain issues are identified | NOT RUN |
| ENV-002 | P0 | Run `flutter pub get` and `flutter test` | Flutter project dependencies available | Dependencies resolve and widget tests pass | NOT RUN |
| MOB-001 | P0 | Launch app on physical Android phone | Android platform files generated; USB debugging enabled | App opens without crash | NOT RUN |
| MOB-002 | P0 | Dashboard with no device | No ESP32 is paired | No fake values; status says not connected and readings unavailable | NOT RUN |
| API-001 | P0 | GET `/health` | Backend `.env`, DB, and broker configured | API reports actual database and MQTT connection status | NOT RUN |
| DB-001 | P0 | Initialize PostgreSQL schema | Docker DB available | Required tables and indexes exist | NOT RUN |
| MQTT-001 | P0 | Backend connects to local broker | Mosquitto password and ACL configured | MQTT connection is established and reported by health endpoint | NOT RUN |
| MQTT-002 | P0 | Submit invalid telemetry | Broker/backend running | Invalid payload is rejected; no invalid telemetry row is stored | NOT RUN |
| TEL-001 | P0 | Publish one actual sensor event from ESP32 | Exact sensor and wiring confirmed | Event contains event ID, sequence, unit, validity, timestamp, and time quality | BLOCKED — hardware details pending |
| TEL-002 | P0 | Trace event to Flutter | TEL-001 passed; backend API available | Same actual event/value appears in serial log, MQTT, DB, API, and phone | BLOCKED — TEL-001 pending |
| CMD-001 | P0 | Publish target-state command | Device authenticated; command handler implemented | Backend records command as unconfirmed until device ACK | NOT RUN |
| CMD-002 | P0 | Send expired command | Firmware command validation implemented | Device rejects command and does not actuate | BLOCKED — firmware command service pending |
| CMD-003 | P0 | Send duplicate command ID | Firmware deduplication implemented | Duplicate command is rejected or safely treated idempotently | BLOCKED — firmware command service pending |
| CMD-004 | P0 | Verify pump feedback | Pump driver and suitable flow/current feedback installed | UI marks physical state verified only after feedback | BLOCKED — hardware not confirmed |
| OFF-001 | P0 | Disconnect internet | Local automation and event queue implemented | ESP32 continues local safety/monitoring and stores events | BLOCKED — firmware offline logic pending |
| OFF-002 | P0 | Restore internet and synchronize | Offline events stored | Server receives queued records without data loss or duplicate rows | BLOCKED — sync not implemented |
| AI-001 | P1 | Evaluate valid species-specific condition | Verified profile and test fixture/unit test available | Recommendation shows actual input, rule/source, severity, explanation, and limitation | NOT RUN |
| AI-002 | P1 | Evaluate missing/stale/invalid input | Recommendation engine implemented | Engine does not declare aquarium safe; stale or invalid data is identified | NOT RUN |
| NOT-001 | P1 | Submit FCM notification | Firebase project, app registration, permission, backend credentials configured | Backend records submission outcome; handset receipt is checked separately | NOT RUN |
| SMS-001 | P1 | Submit direct LTE SMS | Compatible modem/SIM, antenna, signal, and SMS service | Modem submission result is recorded; delivery is verified separately where possible | BLOCKED — modem/SIM pending |
| LTE-001 | P1 | Establish LTE data session | Compatible modem/SIM and supply available | Modem registers and establishes data connectivity | BLOCKED — modem/SIM pending |
| NET-001 | P1 | Wi-Fi to LTE failover | Wi-Fi and LTE paths available; failover implemented | Failed Wi-Fi backend path leads to new LTE route and MQTT session | BLOCKED — LTE integration pending |
| NET-002 | P1 | LTE to Wi-Fi recovery | Both paths available; stability timer implemented | Stable Wi-Fi returns as preferred uplink without rapid route flapping | BLOCKED — LTE integration pending |
| QA-001 | P0 | Cold restart and regression | Integrated MVP available | Device/app/backend restart behavior is documented; no critical regression | NOT RUN |
| REL-001 | P0 | Generate Android APK | Flutter Android build environment configured | APK builds and installs on target Android phone | NOT RUN |

## Execution record

Append one record per execution. Keep previous failures; do not overwrite history when a retest passes.

| Date/time | Test ID | Tester | Commit/build | Hardware revision | Actual result | Status | Evidence path/link | Defect ID |
|---|---|---|---|---|---|---|---|---|
| | | | | | | NOT RUN | | |

## Mobile telemetry persistence — version 0.3.0

| Test ID | Scenario | Expected result |
|---|---|---|
| MOB-DATA-001 | Launch without API build definitions | App shows API not configured; no fabricated sensor data |
| MOB-DATA-002 | Backend returns no readings | App reports backend reachability and no telemetry; measurement cards remain empty |
| MOB-DATA-003 | Backend returns valid telemetry | Validated values appear with their original unit and measurement timestamp |
| MOB-DATA-004 | Backend returns `is_valid=false` or null measurement | Reading is shown unavailable, never as a numeric value |
| MOB-DATA-005 | Reading timestamp older than two minutes | Reading is labelled stale; the threshold is only a UI freshness indicator |
| MOB-DATA-006 | Successful API refresh | Records and last successful sync timestamp are persisted in SQLite |
| MOB-DATA-007 | Backend unavailable after a successful sync | Cached records remain visible and are labelled as cached |
| MOB-DATA-008 | Open history while offline | Previously cached records are visible from SQLite |
| MOB-DATA-009 | Duplicate event/sensor record returned | SQLite unique key prevents duplicate rows for that event and sensor |
| MOB-DATA-010 | Malformed API telemetry record | Client rejects malformed record instead of fabricating defaults |

For any manual test using injected sample messages, label them as test data and never present them as actual aquarium sensor measurements.
