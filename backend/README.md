# Backend development notes

This backend is maintained by the project's sole software developer. Other team members may report defects and capture evidence, but backend source changes are integrated by the developer.

## Responsibilities

- Express REST API and request validation.
- MQTT telemetry ingestion and command publication/acknowledgment.
- PostgreSQL data model and migrations.
- Later phases: authentication/authorization hardening, alerts, FCM worker, sync endpoints, observability, backups, and deployment.

## Local setup

Follow the root `README.md` first. Copy `.env.example` to `.env`, configure the local API token and Mosquitto backend credentials, start the Docker services, and then run:

```powershell
npm install
npm test
npm run dev
```

Check `http://localhost:8080/health`. The service defaults to localhost-only binding. Do not expose the development API or broker directly to the public internet.

## Command status semantics

`published_unconfirmed` means the backend handed the message to MQTT. It does not mean the device received, executed, or physically verified the operation. Only a valid device acknowledgment can advance the command state, and physical verification requires suitable hardware feedback.
