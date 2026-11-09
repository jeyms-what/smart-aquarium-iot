CREATE TABLE IF NOT EXISTS devices (
  device_id TEXT PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS telemetry_samples (
  id BIGSERIAL PRIMARY KEY,
  event_id UUID NOT NULL,
  device_id TEXT NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  sequence_number BIGINT NOT NULL CHECK (sequence_number >= 0),
  sensor_code TEXT NOT NULL,
  measurement_value DOUBLE PRECISION,
  measurement_unit TEXT NOT NULL,
  is_valid BOOLEAN NOT NULL,
  measured_at TIMESTAMPTZ NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  time_quality TEXT NOT NULL CHECK (time_quality IN ('ntp_synced','rtc_synced','rtc_estimated','uptime_only')),
  UNIQUE (event_id, sensor_code)
);
CREATE INDEX IF NOT EXISTS idx_telemetry_device_sensor_time
  ON telemetry_samples (device_id, sensor_code, measured_at DESC);

CREATE TABLE IF NOT EXISTS device_events (
  id BIGSERIAL PRIMARY KEY,
  event_id UUID NOT NULL,
  device_id TEXT NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  payload JSONB NOT NULL,
  UNIQUE (event_id, event_type)
);
CREATE INDEX IF NOT EXISTS idx_device_events_device_time
  ON device_events (device_id, event_type, occurred_at DESC);

CREATE TABLE IF NOT EXISTS commands (
  command_id UUID PRIMARY KEY,
  device_id TEXT NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  command TEXT NOT NULL CHECK (command IN ('SET_PUMP','FEED_NOW')),
  requested_state TEXT CHECK (requested_state IN ('ON','OFF') OR requested_state IS NULL),
  status TEXT NOT NULL CHECK (status IN ('queued','published_unconfirmed','publish_failed','executed','rejected','failed')),
  requested_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  acknowledged_at TIMESTAMPTZ,
  state_verified BOOLEAN NOT NULL DEFAULT FALSE,
  payload JSONB NOT NULL,
  result JSONB,
  CHECK (expires_at > requested_at)
);
CREATE INDEX IF NOT EXISTS idx_commands_device_requested
  ON commands (device_id, requested_at DESC);
