// Zero-dependency env loader. Reads KEY=VALUE lines from the first existing file
// in a candidate list into process.env (without overwriting values already set).
// Reuses the old app's secrets file so the DeepSeek key isn't duplicated.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));

const CANDIDATES = [
  path.join(here, '.env'),
  path.join(here, 'ai_agents_sub.env'),
  // Reuse the original project's secrets file.
  path.join(here, '..', 'assets', 'stocks_eye_old', 'ai_agents_sub.env'),
];

export function loadEnv() {
  const file = CANDIDATES.find((f) => fs.existsSync(f));
  if (!file) return;
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const val = trimmed.slice(eq + 1).trim().replace(/^["']|["']$/g, '');
    if (!(key in process.env)) process.env[key] = val;
  }
  console.log(`[env] loaded ${path.basename(file)}`);
}

export default { loadEnv };
