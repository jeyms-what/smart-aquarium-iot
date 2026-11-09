import pg from 'pg';
import { config } from './config.js';

const { Pool } = pg;
export const pool = new Pool({
  connectionString: config.databaseUrl,
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  ssl: config.nodeEnv === 'production' ? { rejectUnauthorized: true } : false,
});

export async function checkDatabase() {
  await pool.query('SELECT 1');
  return true;
}

export async function ensureDevice(deviceId) {
  await pool.query(
    `INSERT INTO devices (device_id, last_seen_at)
     VALUES ($1, NOW())
     ON CONFLICT (device_id) DO UPDATE SET last_seen_at = NOW()`,
    [deviceId],
  );
}
