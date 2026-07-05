# 05 · Running & configuration

## Prerequisites
- Flutter 3.32+ / Dart 3.8+ (desktop needs the platform toolchain — e.g. Visual Studio Build Tools
  on Windows).
- Node 18+ **only if** you use the proxy (Web, or distributed AI).

```bash
flutter pub get
```

## Prices/news are always live on native
On desktop/mobile, CoinGecko/Yahoo/RSS are called directly (no CORS). The only thing that needs a
key or the proxy is **AI**. On **Web**, Yahoo/RSS are CORS-blocked, so Web needs the proxy for data
too (CoinGecko still works directly).

## Live AI — two options

### Option 1 · desktop, no proxy (`.env`) — the default workflow
Put the key in a `.env`; the desktop app reads it at runtime and calls DeepSeek directly. The key is
never compiled into the app.
```bash
echo "DEEPSEEK_API_KEY='sk-...'" > .env      # project root, git-ignored
flutter run -d windows                        # or -d macos / -d linux
```
`.env` is looked up in the working directory (where `flutter run` starts) and next to the executable
(for a built app — drop a `.env` beside the `.exe`).

### Option 2 · proxy — required for Web, best for distribution
The key stays server-side; the app calls the proxy.
```bash
cd proxy && npm install && npm start          # http://localhost:3000 (Node 18+)
# then, in another terminal:
flutter run -d chrome  --dart-define=PROXY_URL=http://localhost:3000
flutter run -d windows --dart-define=PROXY_URL=http://localhost:3000
```

**Precedence on native:** a local `.env` key (Option 1) wins over the proxy. Without either, AI is
mock. On Web, only the proxy applies.

## The proxy (`proxy/`)
A ~200-line Express app that (1) holds the DeepSeek key and (2) forwards CORS-blocked GETs for the
Web build.

| Endpoint | Purpose |
|----------|---------|
| `GET /api/health` | `{ ok, ai, live }` |
| `POST /api/ai/brief` | Live Morning Brief (cached 24h). Returns `{source:'mock'}` to signal mock. |
| `POST /api/ai/take` | Live Take, or `204` when takes are gated off (→ client uses mock). |
| `GET /api/fetch?url=…` | Host-allowlisted forwarder for Yahoo/RSS on Web. |

It reads `DEEPSEEK_API_KEY` from `proxy/.env` (git-ignored). Cost control lives in the
`LIVE = { takes, brief }` object in `proxy/server.js`. For a real deployment, tighten the
`Access-Control-Allow-Origin` from `*` to your web origin and host it on a free tier
(Render / Fly / Cloudflare Workers), then point `PROXY_URL` at it.

## Configuration knobs
| Knob | Where | Effect |
|------|-------|--------|
| `DEEPSEEK_API_KEY` | `.env` (app) or `proxy/.env` | Enables live AI |
| `PROXY_URL` | `--dart-define=PROXY_URL=…` → `AppConfig` | Routes AI (and Web data) through the proxy |
| `DataPolicy.offline` | tests | Forces all sources to mock (deterministic tests) |
| `_liveBrief` / `_liveTakes` | `deepseek_source.dart` | Cost gate (direct mode) |
| `LIVE = { takes, brief }` | `proxy/server.js` | Cost gate (proxy mode) |

## Building
```bash
flutter build windows          # desktop; add --dart-define=PROXY_URL=… if using the proxy
flutter build web              # web MUST use the proxy for live data
```

## Testing
```bash
flutter test                        # offline widget + no-overflow smoke tests (deterministic)
flutter test test/live_probe.dart   # manual: hits real endpoints; the AI test needs the proxy on :3000
```
The live probe is intentionally excluded from the default `flutter test` run (its filename has no
`_test` suffix) so the suite stays offline.

## Secrets hygiene
`.env` and `*.env` are git-ignored. Never commit keys. The original project's secrets file was
copied into `.env` and `proxy/.env`, so `assets/stocks_eye_old/` can be deleted safely.
