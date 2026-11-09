import { timingSafeEqual } from 'node:crypto';
import { config } from './config.js';

export function requireBearerToken(req, res, next) {
  const header = req.get('authorization') ?? '';
  const match = /^Bearer\s+(.+)$/i.exec(header);
  if (!match) return res.status(401).json({ error: 'Authentication required.' });

  const supplied = Buffer.from(match[1]);
  const expected = Buffer.from(config.apiToken);
  const valid = supplied.length === expected.length && timingSafeEqual(supplied, expected);
  if (!valid) return res.status(401).json({ error: 'Invalid bearer token.' });
  return next();
}
