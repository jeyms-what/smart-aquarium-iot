# Smart Aquarium IoT

[![Smart Aquarium CI](https://github.com/jeyms-what/smart-aquarium-iot/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/jeyms-what/smart-aquarium-iot/actions/workflows/ci.yml)

An IoT aquarium monitoring and control capstone project built around an ESP32, a Flutter Android application, a Node.js API, MQTT, and PostgreSQL.

> **Project status: In development.** The current `main` branch is a software baseline, not a finished or hardware-verified aquarium system. The target is a demonstrable integrated MVP by **1 December 2026**.

## Table of contents

- [Project overview](#project-overview)
- [Current implementation status](#current-implementation-status)
- [System architecture](#system-architecture)
- [Repository structure](#repository-structure)
- [Technology stack](#technology-stack)
- [Development prerequisites](#development-prerequisites)
- [Clone the repository](#clone-the-repository)
- [Run the Flutter application](#run-the-flutter-application)
- [Run the local backend and infrastructure](#run-the-local-backend-and-infrastructure)
- [Connect the Android app to the local backend](#connect-the-android-app-to-the-local-backend)
- [Build the ESP32 firmware](#build-the-esp32-firmware)
- [Testing and continuous integration](#testing-and-continuous-integration)
- [Team collaboration workflow](#team-collaboration-workflow)
- [Security and hardware safety](#security-and-hardware-safety)
- [Documentation](#documentation)
- [Roadmap](#roadmap)

## Project overview

The project is intended to monitor aquarium conditions, provide useful care information, and support safe equipment control.

Planned hardware includes:

- Water-temperature sensor.
- Water-level sensor.
- Turbidity sensor.
- Automatic feeder.
- Water pump and its driver circuit.
- ESP32 controller.
- Optional LTE modem for cellular data and direct SMS notifications.

The software is divided into a Flutter mobile app, a Node.js backend, ESP32 firmware, local infrastructure, and shared documentation.

The system must distinguish actual readings from missing, invalid, stale, cached, or test data. It must never claim that an actuator operated merely because a command was sent.

## Current implementation status

The following describes the code currently merged into `main`.

| Area | Current state |
|---|---|
| Flutter application shell | Implemented: dashboard, control, history, and settings sections |
| Dashboard | Displays explicit not-configured, backend, cached, and offline states |
| Telemetry model | Implemented: measurement value, unit, validity, timestamps, event/device IDs, sequence, and time quality |
| Local mobile storage | SQLite telemetry cache and synchronization timestamp storage implemented |
| Backend telemetry API client | Read-only latest-telemetry retrieval implemented |
| History | Reads locally stored telemetry records |
| Node.js API | Express server, health endpoint, bearer-token middleware, telemetry endpoint, and command API foundation |
| MQTT | Backend subscriptions, telemetry validation/ingestion, event handling, command publishing, and command acknowledgments |
| PostgreSQL | Initial schema for devices, telemetry samples, device events, and commands |
| ESP32 firmware | Bootstrap only; initializes NVS and reports that hardware integration is pending |
| Physical sensors and actuators | Not integrated or verified |
| Mobile pump/feeder control | Kept locked in `main` until firmware execution and physical feedback are ready |
| LTE, FCM, and direct SMS | Not integrated |
| Offline event queue and bidirectional synchronization | Not complete |
| Species-specific recommendations | Not implemented |
| Production authentication and public deployment | Not implemented |

**Important:** A successful backend health check means the backend can reach its configured database and MQTT broker. It does not prove that an ESP32 is online. Likewise, an MQTT publish is not proof of physical pump or feeder operation.

## System architecture

The intended end-to-end data path is:

```text
Aquarium sensors
      |
      v
    ESP32  <----> Local safety logic and event storage
      |
      | Wi-Fi primary / LTE fallback (planned)
      v
   MQTT broker
      |
      v
 Node.js backend
      |
      +----> PostgreSQL
      |
      +----> REST API
                |
                v
         Flutter Android app
                |
                v
          Local SQLite cache
```

The ESP32 must remain responsible for time-critical sensing and local safety behavior. The phone and remote backend must not be the only safety controller.

See [docs/architecture.md](docs/architecture.md) and [docs/mqtt-contract.md](docs/mqtt-contract.md) for the architecture and draft message contract.

## Repository structure

```text
smart-aquarium-iot/
├── .github/
│   └── workflows/
│       └── ci.yml                 # Flutter and backend CI
├── backend/
│   ├── migrations/                # PostgreSQL schema
│   ├── src/                       # Express API, MQTT, DB, auth, validation
│   ├── test/                      # Node.js tests
│   ├── .env.example               # Safe configuration template
│   └── package.json
├── docs/
│   ├── architecture.md
│   ├── acceptance-tests.md
│   ├── development-plan.md
│   ├── development-status.md
│   ├── mobile-data-layer.md
│   ├── mqtt-contract.md
│   ├── team-responsibilities.md
│   └── templates/
├── firmware/
│   ├── main/
│   │   └── main.c                 # Safe ESP-IDF bootstrap
│   └── README.md
├── infra/
│   ├── docker-compose.yml         # Local PostgreSQL and Mosquitto
│   └── mosquitto/                 # Local broker config and ACL
├── mobile/
│   ├── android/                   # Android platform project
│   ├── lib/
│   │   ├── core/
│   │   ├── data/
│   │   ├── features/
│   │   └── theme/
│   ├── test/
│   └── pubspec.yaml
├── scripts/
│   ├── setup-local-mqtt.ps1
│   ├── start-local-stack.ps1
│   └── stop-local-stack.ps1
├── CHANGELOG.md
├── README.md
└── .gitignore
```

## Technology stack

| Component | Technology |
|---|---|
| Mobile application | Flutter and Dart |
| Android development | Android SDK, ADB, Android Emulator or physical Android phone |
| Backend API | Node.js 22+ and Express |
| Request validation | Zod |
| Device messaging | MQTT with Mosquitto |
| Server database | PostgreSQL |
| Mobile local database | SQLite through `sqflite` |
| Embedded firmware | ESP-IDF and FreeRTOS |
| Local development infrastructure | Docker Compose |
| Source control and CI | Git, GitHub, GitHub Actions |

## Development prerequisites

Install the following tools on your development computer:

1. **Git** — for cloning, branching, committing, and pulling changes.
2. **Visual Studio Code** — the primary editor for this project.
3. **Flutter SDK (stable channel)** — the CI workflow currently uses Flutter 3.47.9. The app's Dart SDK constraint is `>=3.12.0 <4.0.0`.
4. **Android SDK and Platform Tools** — for building and deploying the Android app.
5. **Android Studio (optional UI requirement)** — install it if you want to manage Android Virtual Devices; VS Code remains the primary IDE.
6. **Node.js 22 or newer** — required by the backend.
7. **Docker Desktop with Docker Compose** — required for the local PostgreSQL and Mosquitto services.
8. **ESP-IDF** — required to build and flash the ESP32 firmware after the exact board model has been confirmed.

Verify the Flutter and Android environment:

```powershell
flutter doctor -v
flutter --version
adb version
```

Verify Node.js and Docker:

```powershell
node --version
npm --version
docker --version
docker compose version
```

## Clone the repository

Open PowerShell or the VS Code terminal:

```powershell
git clone https://github.com/jeyms-what/smart-aquarium-iot.git
cd smart-aquarium-iot
code .
```

To update an existing checkout:

```powershell
git switch main
git pull origin main
```

Before switching branches, commit or safely back up any uncommitted work.

## Run the Flutter application

The Android platform directory is already included in this repository.

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
```

Connect a physical Android phone with USB debugging enabled, or start an Android Virtual Device.

Check available targets:

```powershell
flutter emulators
flutter devices
```

Run the app:

```powershell
flutter run
```

When both an emulator and a physical phone are connected, select the intended device from the VS Code device selector or use:

```powershell
flutter run -d YOUR_DEVICE_ID
```

The app can be opened without a configured backend. In that state it should show that the API is not configured and should not invent sensor measurements.

## Run the local backend and infrastructure

The local development stack consists of PostgreSQL and Mosquitto. Docker Desktop must be running.

### 1. Create local MQTT credentials

From the repository root, run:

```powershell
.\scripts\setup-local-mqtt.ps1
```

The script creates local MQTT accounts for the backend and the development device `aquarium_001`. Record the backend password temporarily; it must be entered in `backend/.env`.

The generated password file is ignored by Git and must not be committed.

### 2. Create the backend environment file

Copy the example:

```powershell
Copy-Item backend/.env.example backend/.env
```

Edit `backend/.env` and replace the placeholders:

- `MQTT_PASSWORD`: password created for the `aquarium_backend` MQTT account.
- `API_BEARER_TOKEN`: a random token of at least 32 characters.

Generate a local development API token with Node.js:

```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

The example database URL and Docker Compose defaults are for local development only. Keep the database and broker bound to localhost. If you change the PostgreSQL password, update the Compose configuration and `DATABASE_URL` consistently.

### 3. Start PostgreSQL and Mosquitto

```powershell
.\scripts\start-local-stack.ps1
```

Check the containers:

```powershell
docker ps
```

On a fresh PostgreSQL volume, the initial schema is loaded from `backend/migrations/001_init.sql`. The backend also provides a migration command for an existing local database:

```powershell
cd backend
npm install
npm run db:migrate
```

### 4. Test and start the backend

From the `backend` folder:

```powershell
npm install
npm test
npm run dev
```

The API listens on `127.0.0.1:8080` by default. In another terminal, check the health endpoint:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
```

The health endpoint reports database and MQTT connectivity. A healthy response does not confirm that the physical ESP32 is connected.

To stop the local containers later:

```powershell
.\scripts\stop-local-stack.ps1
```

## Connect the Android app to the local backend

The local development token is accepted only by debug builds and is not suitable for public or production deployment.

### Physical Android phone over USB

With USB debugging authorized, run:

```powershell
adb reverse tcp:8080 tcp:8080
```

Then, from the `mobile` directory, launch the app with local development values:

```powershell
flutter run `
  --dart-define=AQUARIUM_API_BASE_URL=http://127.0.0.1:8080 `
  --dart-define=AQUARIUM_API_DEV_TOKEN=YOUR_LOCAL_DEV_TOKEN `
  --dart-define=AQUARIUM_DEVICE_ID=aquarium_001
```

### Android Emulator

For the standard Android Emulator, use `10.0.2.2` to reach the development computer:

```powershell
flutter run `
  --dart-define=AQUARIUM_API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=AQUARIUM_API_DEV_TOKEN=YOUR_LOCAL_DEV_TOKEN `
  --dart-define=AQUARIUM_DEVICE_ID=aquarium_001
```

Replace the token placeholder locally. Never paste the token into GitHub, chat, screenshots, issue reports, or documentation.

The Android debug manifest permits cleartext HTTP for this localhost development workflow. Do not copy that permission into a release manifest or expose this development API to the internet.

## Build the ESP32 firmware

The current firmware is a safe ESP-IDF bootstrap. It initializes non-volatile storage (NVS) and logs that hardware integration is pending. It does **not** yet read sensors, connect Wi-Fi/MQTT, control a pump or feeder, or operate an LTE modem.

Before building or flashing:

1. Confirm the exact ESP32 board model and revision.
2. Check the board's official schematic and datasheet.
3. Confirm the target chip family and select the matching ESP-IDF target.
4. Confirm the actual COM port and use a data-capable USB cable.

Open the ESP-IDF terminal, navigate to `firmware/`, then select the target that matches the confirmed board. For example, use `esp32s3` **only if the physical board is an ESP32-S3**:

```powershell
idf.py set-target esp32s3
idf.py build
```

Flash only after confirming the target and serial port:

```powershell
idf.py -p COMx flash monitor
```

See [firmware/README.md](firmware/README.md) for hardware integration precautions.

## Testing and continuous integration

GitHub Actions runs the following checks for pull requests and configured development-branch pushes:

**Flutter** (from `mobile/`):

```powershell
flutter pub get
flutter analyze --fatal-infos
flutter test
```

**Backend** (from `backend/`):

```powershell
npm install
npm test
```

Run these checks locally before submitting a pull request. The CI workflow is defined in [.github/workflows/ci.yml](.github/workflows/ci.yml).

If Windows Application Control blocks Flutter's `flutter_tester.exe`, inspect the related Code Integrity or AppLocker event with your administrator or IT support. Do not disable Windows security controls just to run tests. GitHub Actions provides a separate CI test environment.

Manual integration testing is still required. A passing unit test or CI run does not prove that the app works with the real ESP32, sensors, pump, feeder, LTE modem, or phone notifications.

## Team collaboration workflow

The project has one software developer responsible for source-code implementation and integration. Other team members support hardware verification, test execution, evidence collection, and documentation.

### Clone and update

Each collaborator can clone the public repository:

```powershell
git clone https://github.com/jeyms-what/smart-aquarium-iot.git
cd smart-aquarium-iot
```

Before starting assigned work:

```powershell
git switch main
git pull origin main
```

### Use a feature or documentation branch

Do not commit directly to `main`.

```powershell
git switch -c docs/update-hardware-record
```

After making assigned changes:

```powershell
git status
git add .
git commit -m "docs: update hardware verification record"
git push -u origin docs/update-hardware-record
```

Open a pull request on GitHub with `main` as the base branch. Include a summary, evidence, test results, and known limitations. Review the diff and CI results before merging.

### Suggested team responsibilities

| Member | Responsibility |
|---|---|
| You — software developer | Own Flutter, backend, MQTT, PostgreSQL, ESP-IDF source, software integration, and releases |
| Member 2 — hardware support | Inventory exact parts, provide datasheets, verify power and wiring, assemble the prototype, and bench-test sensors/actuators |
| Member 3 — QA and documentation | Execute test cases, reproduce defects, capture evidence, maintain acceptance records, and prepare user/project documentation |

Collaborators should use Issues to report defects and attach reproducible steps, logs, and evidence. Source-code changes should be coordinated with the software owner to avoid conflicting implementations.

## Security and hardware safety

- This repository is public. Never commit `.env`, API tokens, passwords, Wi-Fi credentials, private keys, certificates, or generated MQTT password files.
- If a credential is accidentally published, revoke or rotate it immediately. Removing it from the latest commit does not make an exposed credential safe again.
- The current bearer-token setup is for local development only. Do not use it for a public deployment or release APK.
- Do not expose the development API or MQTT broker directly to the public internet.
- Use TLS and unique device credentials before production deployment.
- Do not energize a pump, motor, feeder, or relay until its voltage/current ratings, driver circuit, isolation, protection, wiring, and safe boot behavior have been verified.
- Do not power an LTE modem from the ESP32 3.3 V pin unless the exact module's power requirements and supply design explicitly support it.
- Do not treat raw turbidity ADC values as NTU without a documented calibration method.
- Do not represent test fixtures or simulated values as actual aquarium measurements.
- A command published to MQTT is not confirmed actuation. The device must acknowledge it, and physical state should only be marked verified when actual feedback supports that result.

## Documentation

| Document | Purpose |
|---|---|
| [Architecture](docs/architecture.md) | System boundaries, components, and engineering rules |
| [Development plan](docs/development-plan.md) | Milestones, dates, work ownership, and acceptance gates |
| [Development status](docs/development-status.md) | Implemented, pending, and not-yet-verified work |
| [MQTT and API contract](docs/mqtt-contract.md) | Topic names, payloads, and endpoint expectations |
| [Mobile data layer](docs/mobile-data-layer.md) | Flutter repository, API, and SQLite design |
| [Acceptance tests](docs/acceptance-tests.md) | Test procedures and evidence requirements |
| [Team responsibilities](docs/team-responsibilities.md) | Team roles and collaboration expectations |
| [Changelog](CHANGELOG.md) | Version history |

## Roadmap

The planned implementation sequence is:

1. Verify all development toolchains and local infrastructure.
2. Integrate one real sensor from ESP32 through MQTT, backend, PostgreSQL, API, and Flutter.
3. Add safe actuator control with command expiry, device acknowledgment, and physical feedback.
4. Add resilient local event storage and synchronization after connectivity returns.
5. Add explainable offline recommendations using validated readings and a configured fish/species profile.
6. Integrate FCM, direct SMS, LTE data, and Wi-Fi/LTE failover after the exact modem and network requirements are confirmed.
7. Complete hardware/software integration testing, documentation, and demonstration preparation.

A feature is complete only after the relevant code, tests, target-device or hardware verification, and evidence are available. See [docs/development-plan.md](docs/development-plan.md) for the detailed schedule and acceptance gates.
