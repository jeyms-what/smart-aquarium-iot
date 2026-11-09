import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { randomUUID } from 'node:crypto';
import { config } from './config.js';
import { pool, checkDatabase, ensureDevice } from './db.js';
import { isMqttConnected, publishCommand, closeMqtt } from './mqtt.js';
import { requireBearerToken } from './auth.js';
import { commandRequestSchema, deviceIdSchema } from './validation.js';

const app = express();
app.disable('x-powered-by');
app.use(helmet());
app.use(cors({ origin: false }));
app.use(express.json({ limit: '64kb', strict: true }));

app.get('/health', async (_req, res) => {
  let database = false;
  try { await checkDatabase(); database = true; } catch { database = false; }
  const mqtt = isMqttConnected();
  const healthy = database && mqtt;
  res.status(healthy ? 200 : 503).json({
    service: 'smart-aquarium-backend',
    status: healthy ? 'healthy' : 'degraded',
    database: { connected: database },
    mqtt: { connected: mqtt },
    timestamp: new Date().toISOString(),
  });
});

app.use('/api/v1', requireBearerToken);

app.get('/api/v1/devices/:deviceId/telemetry/latest', async (req, res, next) => {
  try {
    const deviceId = deviceIdSchema.parse(req.params.deviceId);
    const result = await pool.query(
      `SELECT DISTINCT ON (sensor_code)
         event_id, device_id, sensor_code, measurement_value, measurement_unit, is_valid,
         measured_at, received_at, time_quality, sequence_number
       FROM telemetry_samples
       WHERE device_id = $1
       ORDER BY sensor_code, measured_at DESC, sequence_number DESC`,
      [deviceId],
    );
    res.json({ device_id: deviceId, readings: result.rows });
  } catch (error) { next(error); }
});

app.get('/api/v1/devices/:deviceId/commands/:commandId', async (req, res, next) => {
  try {
    const deviceId = deviceIdSchema.parse(req.params.deviceId);
    const result = await pool.query(
      `SELECT command_id, device_id, command, requested_state, status,
              requested_at, expires_at, acknowledged_at, state_verified, result
       FROM commands WHERE device_id = $1 AND command_id = $2`,
      [deviceId, req.params.commandId],
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Command not found.' });
    return res.json(result.rows[0]);
  } catch (error) { return next(error); }
});

app.post('/api/v1/devices/:deviceId/commands', async (req, res, next) => {
  let commandId;
  try {
    const deviceId = deviceIdSchema.parse(req.params.deviceId);
    const parsed = commandRequestSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: 'Invalid command request.', details: parsed.error.issues });
    if (!isMqttConnected()) return res.status(503).json({ error: 'MQTT broker is unavailable; command was not queued.' });

    commandId = randomUUID();
    const issuedAt = new Date();
    const expiresAt = new Date(issuedAt.getTime() + parsed.data.expires_in_seconds * 1000);
    const command = {
      command_id: commandId,
      device_id: deviceId,
      command: parsed.data.command,
      ...(parsed.data.requested_state ? { requested_state: parsed.data.requested_state } : {}),
      issued_at: issuedAt.toISOString(),
      expires_at: expiresAt.toISOString(),
    };

    await ensureDevice(deviceId);
    await pool.query(
      `INSERT INTO commands
        (command_id, device_id, command, requested_state, status, requested_at, expires_at, payload)
       VALUES ($1, $2, $3, $4, 'queued', $5, $6, $7::jsonb)`,
      [commandId, deviceId, command.command, command.requested_state ?? null,
       issuedAt.toISOString(), expiresAt.toISOString(), JSON.stringify(command)],
    );

    try {
      await publishCommand(deviceId, command);
      await pool.query(`UPDATE commands SET status = 'published_unconfirmed' WHERE command_id = $1`, [commandId]);
    } catch (publishError) {
      await pool.query(`UPDATE commands SET status = 'publish_failed' WHERE command_id = $1`, [commandId]);
      return res.status(503).json({ command_id: commandId, status: 'publish_failed', error: publishError.message });
    }

    return res.status(202).json({
      command_id: commandId,
      status: 'published_unconfirmed',
      message: 'Command was published. This is not confirmation that the device executed it.',
      expires_at: expiresAt.toISOString(),
    });
  } catch (error) { return next(error); }
});

app.use((error, _req, res, _next) => {
  if (error?.name === 'ZodError') return res.status(400).json({ error: 'Invalid request.', details: error.issues });
  console.error('Request failed:', error);
  return res.status(500).json({ error: 'Internal server error.' });
});

const server = app.listen(config.port, config.host, () => {
  console.info(`Smart Aquarium API listening on http://${config.host}:${config.port}`);
  console.info('Local development binding only. Do not expose this server directly to the internet.');
});

async function shutdown(signal) {
  console.info(`${signal} received; shutting down.`);
  server.close(async () => {
    await closeMqtt();
    await pool.end();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000).unref();
}
process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));
