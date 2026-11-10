import test from 'node:test';
import assert from 'node:assert/strict';
import { commandRequestSchema, telemetrySchema } from '../src/validation.js';

const validTelemetry = {
  schema_version: 1,
  device_id: 'aquarium_001',
  event_id: 'b9b8b10d-2f15-47ca-a3e4-d15e5e58e6f2',
  sequence: 1,
  measured_at: '2026-11-09T01:00:00.000Z',
  time_quality: 'rtc_synced',
  readings: { water_temperature: { value: 25.1, unit: 'degC', valid: true } },
};

test('accepts a schema-valid telemetry event', () => {
  assert.equal(telemetrySchema.safeParse(validTelemetry).success, true);
});

test('rejects a telemetry event without sensor readings', () => {
  const payload = { ...validTelemetry, readings: {} };
  assert.equal(telemetrySchema.safeParse(payload).success, false);
});

test('rejects a reading marked valid when value is null', () => {
  const payload = structuredClone(validTelemetry);
  payload.readings.water_temperature = { value: null, unit: 'degC', valid: true };
  assert.equal(telemetrySchema.safeParse(payload).success, false);
});

test('requires a requested state for pump target commands', () => {
  assert.equal(commandRequestSchema.safeParse({ command: 'SET_PUMP' }).success, false);
  assert.equal(commandRequestSchema.safeParse({ command: 'SET_PUMP', requested_state: 'OFF' }).success, true);
});

test('does not accept an unbounded command expiry', () => {
  assert.equal(commandRequestSchema.safeParse({ command: 'FEED_NOW', expires_in_seconds: 999 }).success, false);
});
