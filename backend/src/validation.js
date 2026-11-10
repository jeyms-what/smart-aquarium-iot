import { z } from 'zod';

export const deviceIdSchema = z.string().regex(/^[A-Za-z0-9_-]{1,64}$/);

const readingSchema = z.object({
  value: z.number().finite().nullable(),
  unit: z.string().min(1).max(24),
  valid: z.boolean(),
}).superRefine((reading, context) => {
  if (reading.valid && reading.value === null) {
    context.addIssue({ code: 'custom', message: 'A valid reading must contain a numeric value.' });
  }
});

export const telemetrySchema = z.object({
  schema_version: z.literal(1),
  device_id: deviceIdSchema,
  event_id: z.uuid(),
  sequence: z.number().int().nonnegative(),
  measured_at: z.iso.datetime({ offset: true }),
  time_quality: z.enum(['ntp_synced', 'rtc_synced', 'rtc_estimated', 'uptime_only']),
  readings: z
    .record(z.string().regex(/^[a-z][a-z0-9_]{0,47}$/), readingSchema)
    .refine((readings) => Object.keys(readings).length > 0, {
      message: 'At least one sensor reading is required.',
    }),
});

export const alertSchema = z.object({
  event_id: z.uuid(),
  device_id: deviceIdSchema,
  severity: z.enum(['info', 'warning', 'critical']),
  code: z.string().min(1).max(64),
  title: z.string().min(1).max(160),
  detected_at: z.iso.datetime({ offset: true }),
}).passthrough();

export const commandRequestSchema = z.object({
  command: z.enum(['SET_PUMP', 'FEED_NOW']),
  requested_state: z.enum(['ON', 'OFF']).optional(),
  expires_in_seconds: z.number().int().min(5).max(60).default(30),
}).superRefine((payload, context) => {
  if (payload.command === 'SET_PUMP' && !payload.requested_state) {
    context.addIssue({ code: 'custom', message: 'requested_state is required for SET_PUMP.' });
  }
  if (payload.command === 'FEED_NOW' && payload.requested_state) {
    context.addIssue({ code: 'custom', message: 'requested_state is not used for FEED_NOW.' });
  }
});

export const commandAckSchema = z.object({
  command_id: z.uuid(),
  device_id: deviceIdSchema,
  status: z.enum(['executed', 'rejected', 'failed']),
  state_verified: z.boolean(),
  resulting_state: z.record(z.string(), z.unknown()).optional(),
  occurred_at: z.iso.datetime({ offset: true }),
});
