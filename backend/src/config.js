import 'dotenv/config';

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

const apiToken = required('API_BEARER_TOKEN');
if (apiToken.length < 32) {
  throw new Error('API_BEARER_TOKEN must contain at least 32 characters.');
}

export const config = Object.freeze({
  nodeEnv: process.env.NODE_ENV ?? 'development',
  host: process.env.HOST ?? '127.0.0.1',
  port: Number(process.env.PORT ?? 8080),
  databaseUrl: required('DATABASE_URL'),
  mqttUrl: required('MQTT_URL'),
  mqttUsername: required('MQTT_USERNAME'),
  mqttPassword: required('MQTT_PASSWORD'),
  apiToken,
});

if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) {
  throw new Error('PORT must be a valid TCP port.');
}
