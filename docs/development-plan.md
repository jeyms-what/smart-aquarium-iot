# Revised implementation plan — one software developer

**Planning window:** 9 November to 1 December 2026  
**Software ownership:** One developer (the user) owns every software module.  
**Support:** Member 2 handles hardware assembly/specification verification; Member 3 handles QA execution, evidence, and documentation.

## 1. Operating strategy

The deadline is aggressive. The goal is a demonstrable integrated MVP, not a claim of production completeness. Build a single vertical slice before expanding horizontally:

`actual sensor → ESP32 → MQTT → Node.js → PostgreSQL → API → Flutter`

Then add one safe control path, offline storage/synchronization, recommendations, notifications, and LTE. Do not spend the first week polishing every screen or building advanced AI before actual device data reaches the phone.

Only the developer changes source code. Support members provide hardware facts, test evidence, reproducible defect reports, and documentation inputs. This reduces merge conflicts and avoids multiple people implementing incompatible APIs.

## 2. Revised ownership

### Sole software developer — user

Owns all code in `mobile/`, `backend/`, `firmware/`, `infra/`, and software-related scripts. Also owns integration decisions, source control, dependency versions, security implementation, and release readiness.

### Member 2 — hardware assembly and bench verification

- Inventory exact ESP32 board, sensors, LTE modem board/revision, antennas, SIM/operator, pump, feeder motor, drivers, supplies, and protection.
- Supply datasheets and photographs.
- Measure/verify safe low-voltage supplies and sensor output ranges using appropriate instruments.
- Assemble low-voltage wiring only after pin/power review.
- Test standalone sensors and actuators under a written procedure.
- Test the modem's SIM registration, signal, data, and SMS capability with a serial terminal where possible; capture exact AT responses.
- Report facts and failures; do not make unverified pinout or electrical assumptions.

### Member 3 — QA, acceptance evidence, and documentation

- Maintain test ID, preconditions, steps, expected result, actual result, status, date/time, tester, and evidence reference.
- Run test builds and procedures supplied by the developer.
- Capture application screenshots, API responses, backend logs, serial monitor output, and test videos where useful.
- Reproduce defects without modifying software source.
- Maintain hardware inventory, wiring record, user guide, project report, and demonstration script.
- Track requirements as Not Started / In Progress / Blocked / Passed / Failed. A test is Passed only with actual evidence.

## 3. Calendar plan and gates

Dates are targets, not guarantees. Hardware availability and unresolved modem/sensor choices may change the sequence. Start hardware and modem verification immediately, even while the developer works on the first software vertical slice.

| Date | Developer focus | Support work | Exit criteria |
|---|---|---|---|
| **Nov 9–11** | Verify Flutter, Node, Docker, and ESP-IDF starter; configure repo; confirm local API and services | M2: inventory every actual component and gather datasheets. M3: prepare test log and evidence folders | Flutter shell, backend, local DB/broker, and correct firmware target are independently buildable or blockers are recorded |
| **Nov 12–16** | Implement first real sensor telemetry path; validate payload; persist to PostgreSQL; expose API; display actual data in Flutter | M2: bench-check first sensor and provide confirmed model/pin/electrical facts. M3: trace event and capture logs/screens | Same actual event ID and measurement traceable from device log through MQTT, DB, API, and phone |
| **Nov 17–20** | Implement one safe target-state actuator path; add expiry, duplicate protection, ACK, feedback state; add SQLite local cache | M2: verify pump/feeder driver and physical feedback. M3: run command success/failure/expired tests | No false success; device state is only marked verified when feedback supports it |
| **Nov 21–24** | Add ESP32 event queue and acknowledged sync; Flutter stale-data labels; first offline species rules and basic history | M2: test controlled link/power interruptions. M3: execute offline/cache/sync scenarios and capture evidence | Local safety continues offline; unsynced events survive restart and sync without duplicates; stale data is labeled |
| **Nov 25–27** | Integrate FCM; integrate LTE data, direct SMS, and Wi-Fi/LTE failover if exact modem is available and compatible | M2: give modem AT/registration/signal/SMS results and confirm power. M3: test push/SMS separately and record delivery limits | Push and SMS outcomes are tracked separately; LTE fallback is demonstrated or a precise blocker is documented |
| **Nov 28–30** | Freeze features; fix critical defects; integration/regression; produce APK and technical docs | M2: stabilize prototype and wiring. M3: execute acceptance matrix, collect screenshots/logs, complete manual and demo script | No known critical safety defect; test report accurately distinguishes Pass/Fail/Blocked/Not Tested |
| **Dec 1** | Support final build and demonstration | M2: operate/monitor prototype. M3: present test evidence and documentation | Demonstrate only the functions that have actually passed acceptance tests |

## 4. Development gates — one subsystem at a time

### Gate 0 — starter environment

Developer tasks:
1. Run `flutter doctor -v`.
2. Run `flutter pub get`, `flutter test`, and `flutter run` on a physical Android phone after Android platform files are generated.
3. Create `backend/.env`; start local Docker PostgreSQL and Mosquitto.
4. Run `npm install`, `npm test`, `npm run dev`, and check `/health`.
5. Build the ESP-IDF bootstrap for the confirmed board target.

Acceptance: each toolchain starts independently. Record missing tools or failing commands; do not skip ahead silently.

### Gate 1 — first real telemetry vertical slice

1. M2 supplies exact sensor model, datasheet, voltage/output range, interface, and tested wiring proposal.
2. Developer adds one sensor driver and validation/calibration metadata.
3. ESP32 publishes the agreed telemetry schema with unique event ID, sequence, unit, validity, measurement time, and time quality.
4. Backend validates and stores the event.
5. API exposes the latest valid measurement plus `measured_at` and `received_at`.
6. Flutter displays the actual value, unit, device state, and freshness.

Acceptance: same event ID/value appears in serial log, MQTT message, DB row, API response, and app. A test fixture may be used for software tests only and must be explicitly labeled as test data; it must never masquerade as a physical reading.

### Gate 2 — safe actuator vertical slice

1. Verify actuator voltage/current and rated driver.
2. Define a safe boot state and local interlocks.
3. Send a target-state command, not a toggle.
4. Include unique command ID and short expiration.
5. Validate authorization, expiry, command allow-list, duplicate ID, and local safety on device.
6. Return an ACK with result.
7. Verify physical state using a suitable feedback sensor before marking it verified.

Acceptance: expired/duplicate/unsafe commands are rejected; network loss does not cause stale commands to execute later; app distinguishes requested, published-unconfirmed, executed, verified, rejected, and failed states.

### Gate 3 — offline storage and synchronization

- ESP32 configuration: NVS.
- ESP32 event queue: LittleFS or MicroSD once storage choice is confirmed.
- Mobile cache: SQLite.
- Server history: PostgreSQL.
- Every event has stable ID and sequence.
- Server confirms persistence before ESP32 marks event synchronized.
- Partial batches retry safely; original measurement timestamps are preserved.

Acceptance: create events during a controlled outage, reboot if safe to do so, restore connectivity, synchronize, and prove that records are neither lost nor duplicated.

### Gate 4 — first offline recommendation rules

Start with explainable deterministic rules, not an LLM or complex ML model. Use only validated readings, configured species profile, source/versioned thresholds, and freshness checks. Include measured value, severity, explanation, suggested action, timestamp, and limitations. If data is stale, invalid, or missing, say so and do not declare the aquarium safe.

Acceptance: tests cover normal, out-of-range, invalid, missing, stale, and species-profile-mismatch inputs.

### Gate 5 — notifications and LTE

- FCM request is sent by the backend; service-account secrets stay server-side.
- SMS is submitted directly through the LTE modem to an allow-listed destination.
- FCM submission and SMS submission are separate notification delivery records.
- Do not claim handset display or SMS delivery merely because a provider/modem accepted a submission.
- Validate the precise modem board, band variant, supply, logic level, operator coverage, SIM data/SMS plan, and CMUX behavior.
- Test LTE data and SMS separately. Do not assume they work simultaneously.
- Wi-Fi failover requires end-to-end backend health checks, new LTE route/session, and MQTT reconnection. Wi-Fi recovery needs stability time/hysteresis.

Acceptance: demonstrate Wi-Fi primary, LTE backup, local-only mode, and restored Wi-Fi where hardware/network conditions allow. Otherwise document exact blocked criteria and evidence.

## 5. Daily workflow for the solo developer

1. Pick one issue only as the active implementation task.
2. Check hardware prerequisites and the message contract before coding.
3. Make the smallest complete change.
4. Run the relevant test and capture output.
5. Ask Member 3 to execute the acceptance steps and attach evidence.
6. Commit the verified change to Git.
7. Update `development-status.md` and move to the next issue.

Suggested daily allocation: roughly 70% implementation/integration, 20% verification/debugging, and 10% documentation/commit. Use the ratio flexibly when hardware blockers occur.

Do not keep several half-integrated features open. Prefer a working sensor-to-app vertical slice over separate unfinished AI, LTE, notification, and analytics modules.

## 6. MVP scope control

### Required for a credible MVP

- Actual sensor monitoring from the physical prototype.
- Flutter Android dashboard with honest connection/data freshness states.
- At least one safe actuator control path with acknowledgment and feedback.
- Local ESP32 operation and event recording during internet loss.
- Remote telemetry/control over an authenticated backend when internet is available.
- Basic historical storage and retrieval.
- Basic explainable offline recommendations using configured species data.
- QA evidence and a documented demonstration.

### High priority but hardware/service dependent

- LTE data fallback and direct SMS.
- FCM push delivery.
- Synchronization after network recovery.

Begin compatibility checks immediately. If they cannot be demonstrated by the deadline, report them accurately as blocked/not tested rather than simulating success.

### Defer unless all MVP gates pass early

- SMS remote hardware commands.
- Native iOS release.
- Advanced ML or on-device LLM.
- Complex multi-user administration.
- Elaborate analytics and custom charting beyond useful historical views.
- Production-grade public deployment, multi-region resilience, and enterprise operations.

## 7. Definition of Done

A feature is Done only when:

- The source is integrated into the main repository.
- Relevant unit/integration tests pass.
- The feature runs on its intended platform or hardware.
- Invalid, missing, stale, and failure cases have been considered.
- No actual result is fabricated.
- QA evidence is recorded.
- Known limitations are documented.

A compile success alone is not an integration pass. A backend publish acknowledgment is not physical actuation success. An FCM submission is not proof of notification display. An SMS submission is not proof of delivery.
