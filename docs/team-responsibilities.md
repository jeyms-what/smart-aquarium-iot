# Team responsibilities — one software developer

## Role 1: Software developer (user)

The sole software developer owns all source changes and integration:

- `mobile/` — Flutter/Dart application.
- `backend/` — Node.js API, data validation, command service, notification service.
- `firmware/` — ESP-IDF firmware, sensor/actuator/network/modem drivers, local safety and storage.
- `infra/` — local services and deployment configuration.
- `scripts/` — developer setup and maintenance scripts.
- `docs/mqtt-contract.md` — canonical interface contract, updated with code changes.

The developer chooses dependency versions, approves wiring/pin assignments before firmware implementation, runs integration tests, and creates releases.

## Role 2: Hardware assembly and verification support

This member supports the developer but does not write software modules. Required outputs:

1. Hardware inventory with exact product/model/revision and source datasheet.
2. Electrical specification sheet: supply range, peak/normal current, output/logic levels, interface, connector, and protection.
3. Photographs of board markings and assembled low-voltage connections.
4. Proposed pinout based on actual board documentation for developer review.
5. Standalone sensor validation observations and reference-instrument comparison where practical.
6. Actuator driver and feedback verification.
7. LTE modem/SIM test report: module suffix, operator, registration state, signal indication, data attach, SMS AT-command result, and any observed limitations.

No mains-voltage assembly without suitable qualified supervision, isolation, enclosure, and protective devices. Do not connect unknown-voltage signals to ESP32 pins.

## Role 3: QA, test evidence, and documentation support

This member does not write application, backend, or firmware source. Required outputs:

1. Test case execution log.
2. Screenshots, serial logs, API responses, MQTT captures, and test videos where useful.
3. Defect reports with build/version, preconditions, exact steps, expected/actual result, timestamp, and evidence.
4. Requirements traceability matrix.
5. Updated wiring and installation guide based on developer-approved information.
6. User guide, maintenance guide, and demonstration script.
7. Test summary separating Pass, Fail, Blocked, and Not Tested.

## Collaboration rules

- The developer is the single source-code owner; avoid parallel edits to the same codebase.
- Hardware facts must come from labels, datasheets, or measurements, not guesses.
- QA reports findings but does not silently fix source code.
- Any interface change is first documented in `mqtt-contract.md` and then tested end-to-end.
- No one reports a feature as working without evidence from the actual target environment.
