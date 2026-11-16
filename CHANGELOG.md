# Changelog

## 0.4.0 — Unreleased

- Added a dedicated Fish Care tab with Betta, Neon Tetra, Goldfish, and Guppy starter profiles.
- Added local SQLite persistence for the selected fish species without migrating the telemetry database.
- Added conservative comparison of valid, fresh temperature and pH telemetry against sourced care-guide ranges.
- Added habitat, social behavior, feeding, and water-quality guidance with source links and explicit scope limitations.
- Added dashboard navigation into Fish Care and automated assessment/widget tests; CI and physical-device verification are pending.
- Kept pump and feeder commands locked pending device firmware, safety interlocks, authorization, and physical feedback.

## 0.3.0 — 2026-11-09

- Added SQLite telemetry persistence for Android/iOS.
- Added a validated telemetry model that preserves measurement validity, measurement time, receipt time, sequence, event ID, and time-quality metadata.
- Added a read-only HTTP client for the backend's latest telemetry endpoint.
- Added debug-only build-time local API configuration; release builds refuse this development token path.
- Added cached/offline/not-configured/backend-reachable UI states.
- Added two-minute display staleness labelling; this is not an aquarium safety threshold.
- Connected dashboard refresh and local history view to the telemetry repository.
- Updated backend latest telemetry response to include event and device identity.
- Kept pump and feeder controls locked pending physical feedback and secure user authorization.
- Added telemetry parsing tests and updated application setup instructions.

## 0.2.0 — 2026-11-09

- Reframed the repository around one software developer and two supporting members.
- Added single-developer roadmap, milestone gates, QA evidence process, and documentation templates.
- Kept hardware-dependent firmware functions unimplemented until exact components are confirmed.
