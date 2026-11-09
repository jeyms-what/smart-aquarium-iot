# Architecture baseline

## System boundary

```text
Sensors / switches / actuators
           |
        ESP32-S3  ---- local safety state machine + local event queue
           |
     Wi-Fi primary / LTE backup
           |
      MQTT over TLS (production)
           |
   Mosquitto broker ---- Node.js API / workers ---- PostgreSQL
           |                         |
      command ACK                 HTTPS API
                                     |
                             Flutter Android app
                                  SQLite cache
                                     |
                                   FCM

ESP32 LTE modem ---- direct cellular SMS to authorized number
```

## Design rules

1. ESP32 owns real-time sensing and safe actuator behavior. The cloud and phone are not safety controllers.
2. Wi-Fi is preferred only when end-to-end backend reachability is verified. Router association alone is not internet health.
3. LTE is a separate IP interface/session. Failover requires establishing a new MQTT/TLS session and restoring subscriptions; existing TCP sessions do not migrate between interfaces.
4. If both IP routes fail, the ESP32 continues configured local operation and stores events for later synchronization.
5. SMS and MQTT data connectivity are distinct modem services. Simultaneous operation depends on the exact modem firmware and CMUX support and must be verified.
6. Backend `published_unconfirmed` is not successful hardware execution. The device must acknowledge and, for physical status, verify feedback.
7. No expired command may be replayed after reconnect.
8. No unverified, stale, or fabricated sensor value may be shown as current.

## Initial software components

- Flutter: presentation only, local cache, API client, recommendation presentation.
- Node.js: authenticated API, MQTT subscriber, command routing, database persistence.
- Mosquitto: local development broker with password and topic ACL. Production must use TLS and per-device credentials.
- PostgreSQL: server-side telemetry, commands, events, and device registry.
- ESP-IDF: firmware bootstrap. Sensor, actuator, and modem integrations are deferred until exact hardware is confirmed.

## Explicitly out of scope for this starter

- Production identity/account lifecycle and JWT/OIDC implementation.
- Production certificate provisioning and certificate rotation.
- Public server deployment, DNS, firewall, and backups.
- Modem PPP, CMUX, SMS and route failover.
- Sensor drivers, calibration, relay/MOSFET wiring, and pump/feeder feedback.
- Species-care content verification and clinical/aquatic-care validation.
- FCM service account integration and mobile platform configuration.
