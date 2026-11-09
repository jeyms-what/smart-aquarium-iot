import mqtt from 'mqtt';
import { randomUUID } from 'node:crypto';
import { config } from './config.js';
import { pool, ensureDevice } from './db.js';
import { telemetrySchema, alertSchema, commandAckSchema } from './validation.js';

const subscriptions = 'aquarium/+/telemetry,aquarium/+/alerts,aquarium/+/state,aquarium/+/network,aquarium/+/availability,aquarium/+/cmd/ack';
let connected = false;

export const mqttClient = mqtt.connect(config.mqttUrl, {
  username: config.mqttUsername,
  password: config.mqttPassword,
  clientId: `aquarium_backend_${randomUUID().slice(0, 8)}`,
  clean: true,
  connectTimeout: 10_000,
  reconnectPeriod: 5_000,
  keepalive: 30,
});

mqttClient.on('connect', () => {
  connected = true;
  mqttClient.subscribe(subscriptions.split(','), { qos: 1 }, (error) => {
    if (error) console.error('MQTT subscribe failed:', error.message);
    else console.info('MQTT connected; subscribed to device event topics.');
  });
});
mqttClient.on('reconnect', () => { connected = false; console.warn('MQTT reconnecting.'); });
mqttClient.on('close', () => { connected = false; });
mqttClient.on('offline', () => { connected = false; });
mqttClient.on('error', (error) => console.error('MQTT error:', error.message));

export function isMqttConnected() {
  return connected && mqttClient.connected;
}

async function insertDeviceEvent(deviceId, eventType, eventId, occurredAt, payload) {
  await ensureDevice(deviceId);
  await pool.query(
    `INSERT INTO device_events (event_id, device_id, event_type, occurred_at, payload)
     VALUES ($1, $2, $3, $4, $5::jsonb)
     ON CONFLICT (event_id, event_type) DO NOTHING`,
    [eventId, deviceId, eventType, occurredAt, JSON.stringify(payload)],
  );
}

async function handleTelemetry(deviceIdFromTopic, payload) {
  const message = telemetrySchema.parse(payload);
  if (message.device_id !== deviceIdFromTopic) throw new Error('Topic device ID does not match payload device_id.');
  await ensureDevice(message.device_id);
  for (const [sensorCode, reading] of Object.entries(message.readings)) {
    await pool.query(
      `INSERT INTO telemetry_samples
        (event_id, device_id, sequence_number, sensor_code, measurement_value,
         measurement_unit, is_valid, measured_at, time_quality)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       ON CONFLICT (event_id, sensor_code) DO NOTHING`,
      [message.event_id, message.device_id, message.sequence, sensorCode,
       reading.value, reading.unit, reading.valid, message.measured_at, message.time_quality],
    );
  }
}

async function handleAlert(deviceIdFromTopic, payload) {
  const message = alertSchema.parse(payload);
  if (message.device_id !== deviceIdFromTopic) throw new Error('Topic device ID does not match payload device_id.');
  await insertDeviceEvent(message.device_id, 'alert', message.event_id, message.detected_at, message);
}

async function handleCommandAck(deviceIdFromTopic, payload) {
  const message = commandAckSchema.parse(payload);
  if (message.device_id !== deviceIdFromTopic) throw new Error('Topic device ID does not match payload device_id.');
  await ensureDevice(message.device_id);
  const result = await pool.query(
    `UPDATE commands
       SET status = $1, acknowledged_at = $2, state_verified = $3, result = $4::jsonb
     WHERE command_id = $5 AND device_id = $6 AND status IN ('queued', 'published_unconfirmed')`,
    [message.status, message.occurred_at, message.state_verified,
     JSON.stringify(message), message.command_id, message.device_id],
  );
  if (result.rowCount === 0) console.warn(`Command ACK did not match an awaiting command: ${message.command_id}`);
}

async function handleGenericEvent(deviceId, eventType, payload) {
  const eventId = typeof payload.event_id === 'string' ? payload.event_id : randomUUID();
  const occurredAt = typeof payload.occurred_at === 'string' ? payload.occurred_at : new Date().toISOString();
  await insertDeviceEvent(deviceId, eventType, eventId, occurredAt, payload);
}

mqttClient.on('message', (topic, buffer) => {
  void (async () => {
    const parts = topic.split('/');
    if (parts.length < 3 || parts[0] !== 'aquarium') return;
    const deviceId = parts[1];
    const kind = parts.slice(2).join('/');
    const raw = buffer.toString('utf8');
    let payload;
    if (kind === 'availability') {
      payload = { status: raw.trim(), occurred_at: new Date().toISOString() };
    } else {
      payload = JSON.parse(raw);
    }

    switch (kind) {
      case 'telemetry': await handleTelemetry(deviceId, payload); break;
      case 'alerts': await handleAlert(deviceId, payload); break;
      case 'cmd/ack': await handleCommandAck(deviceId, payload); break;
      case 'state':
      case 'network':
      case 'availability': await handleGenericEvent(deviceId, kind, payload); break;
      default: break;
    }
  })().catch((error) => console.error(`Rejected MQTT message on ${topic}:`, error.message));
});

export function publishCommand(deviceId, payload) {
  return new Promise((resolve, reject) => {
    if (!isMqttConnected()) return reject(new Error('MQTT broker is not connected.'));
    const topic = `aquarium/${deviceId}/cmd/request`;
    mqttClient.publish(topic, JSON.stringify(payload), { qos: 1, retain: false }, (error) => {
      if (error) return reject(error);
      return resolve();
    });
  });
}

export function closeMqtt() {
  return new Promise((resolve) => mqttClient.end(false, {}, resolve));
}
