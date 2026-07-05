// Stocks Eye — thin proxy for the Flutter app.
//
// Purpose (see FLUTTER_BUILD_PLAN.md, option a):
//   1. Hold the DeepSeek API key SERVER-SIDE so it never ships in any client
//      build. The app calls /api/ai/brief (and /api/ai/take) here.
//   2. For the WEB build only: forward CORS-blocked GETs (Yahoo/RSS) via
//      /api/fetch, since the browser can't call those hosts directly.
//
// Native (desktop/mobile) apps call Yahoo/CoinGecko/RSS directly and only use
// this proxy for AI. When the proxy is down, the app falls back to mock.

import express from 'express';
import { loadEnv } from './env.js';

loadEnv();

const PORT = process.env.PORT || 3000;
const API_URL = 'https://api.deepseek.com/chat/completions';
const MODEL = 'deepseek-chat';
const hasKey = () => !!process.env.DEEPSEEK_API_KEY;

// Cost control — mirror the original: Morning Brief live (cached a day),
// per-market Takes stay on mock. Flip `takes` to true to enable live takes.
const LIVE = { takes: false, brief: true };
const BRIEF_TTL = 24 * 60 * 60_000;

// Hosts the generic /api/fetch forwarder is allowed to reach (web price/news).
const FETCH_ALLOW = [
  'query1.finance.yahoo.com',
  'query2.finance.yahoo.com',
  'api.coingecko.com',
  'www.cnbc.com',
  'www.egyptindependent.com',
  'www.scmp.com',
  'www.kitco.com',
  'www.coindesk.com',
];

const SYSTEM = `You are a market analyst for a dashboard called Stocks Eye.
Rules:
- Use ONLY the numbers provided in the snapshot for prices and levels. NEVER invent figures.
- You have NO live web access. Do not fabricate news, URLs, or citations. Leave citations empty
  unless you are naming a well-known general source of context.
- Output is informational, NOT investment advice.
- Reply with ONLY a compact JSON object, no prose before or after.`;

async function deepseek(system, user, maxTokens) {
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${process.env.DEEPSEEK_API_KEY}`,
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: maxTokens,
      temperature: 0.7,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user },
      ],
    }),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`DeepSeek ${res.status}: ${body.slice(0, 300)}`);
  }
  const data = await res.json();
  return data?.choices?.[0]?.message?.content || '';
}

function parseJson(text) {
  const cleaned = String(text).replace(/```json|```/g, '').trim();
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  if (start === -1 || end === -1) throw new Error('no json');
  return JSON.parse(cleaned.slice(start, end + 1));
}

// --- tiny 1-slot TTL cache for the daily brief (cache ONLY on success) ------
let briefCache = null; // { value, expiry }

const app = express();
app.use(express.json({ limit: '256kb' }));

// Permissive CORS for local dev. Tighten `Access-Control-Allow-Origin` to your
// web origin before deploying.
app.use((req, res, next) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

app.get('/api/health', (req, res) => {
  res.json({ ok: true, ai: hasKey() ? 'live' : 'no-key', live: LIVE });
});

// Roll-up Morning Brief. Body: { snapshots: [...] }.
// Returns the live brief JSON, or { source: 'mock' } so the client uses its own
// local mock (the proxy never needs to hold mock content).
app.post('/api/ai/brief', async (req, res) => {
  if (briefCache && briefCache.expiry > Date.now()) {
    return res.json(briefCache.value);
  }
  if (!LIVE.brief || !hasKey()) return res.json({ source: 'mock' });
  try {
    const snapshots = req.body?.snapshots ?? [];
    const user =
      `Snapshots (ground truth):\n${JSON.stringify(snapshots)}\n\n` +
      `Write today's roll-up Morning Brief across all markets. Reply as JSON: ` +
      `{"lead":"...","lines":[{"id":"","flag":"","name":"","s":"bull|bear|neut","text":""}],"hint":"...","citations":[]}.`;
    const obj = parseJson(await deepseek(SYSTEM, user, 4000));
    const brief = { ...obj, source: MODEL };
    briefCache = { value: brief, expiry: Date.now() + BRIEF_TTL }; // cache on success only
    res.json(brief);
  } catch (err) {
    console.error('[ai] brief failed, signalling mock:', err?.message || err);
    res.json({ source: 'mock' });
  }
});

// Per-market Take. Body: { market: { id, name }, snapshot }.
// Gated off by default (LIVE.takes=false) → 204 tells the client to use mock.
app.post('/api/ai/take', async (req, res) => {
  if (!LIVE.takes || !hasKey()) return res.sendStatus(204);
  try {
    const { market, snapshot } = req.body ?? {};
    const user =
      `Market snapshot (ground truth):\n${JSON.stringify(snapshot)}\n\n` +
      `Write today's AI Take for ${market?.name}. Reply as JSON: ` +
      `{"sentiment":"bull|bear|neut","text":"1-2 sentences","citations":["Source"]}.`;
    const obj = parseJson(await deepseek(SYSTEM, user, 1024));
    res.json({ ...obj, source: MODEL });
  } catch (err) {
    console.error('[ai] take failed, signalling mock:', err?.message || err);
    res.sendStatus(204);
  }
});

// Generic GET forwarder for the WEB build (Yahoo/RSS are CORS-blocked in the
// browser). Host-allowlisted so it can't be used as an open proxy.
app.get('/api/fetch', async (req, res) => {
  const target = req.query.url;
  let host;
  try {
    const u = new URL(target);
    host = u.hostname;
    if (u.protocol !== 'https:' || !FETCH_ALLOW.includes(host)) {
      return res.status(403).json({ error: 'host not allowed' });
    }
  } catch {
    return res.status(400).json({ error: 'bad url' });
  }
  try {
    const upstream = await fetch(target, {
      headers: { 'User-Agent': 'Mozilla/5.0', accept: '*/*' },
    });
    const body = await upstream.text();
    res.status(upstream.status);
    res.set('Content-Type', upstream.headers.get('content-type') || 'text/plain');
    res.send(body);
  } catch (err) {
    res.status(502).json({ error: String(err?.message || err) });
  }
});

app.listen(PORT, () => {
  console.log(`\n  👁  Stocks Eye proxy → http://localhost:${PORT}`);
  console.log(`      AI: ${hasKey() ? 'live (DeepSeek)' : 'NO KEY → mock'} · brief=${LIVE.brief} takes=${LIVE.takes}\n`);
});
