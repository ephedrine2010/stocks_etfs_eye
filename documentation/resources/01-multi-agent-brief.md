# 01 · Multi-agent Morning Brief

Upgrades the daily AI **Morning Brief** from a single model call into a small analyst **desk**: three
specialist analysts each file a view, then a chief editor reconciles them into the final brief.
Inspired by [TradingAgents](https://github.com/TauricResearch/TradingAgents) (see
[00-tooling-landscape.md](00-tooling-landscape.md)).

**One file changed:** `lib/data/sources/deepseek_source.dart`. No model, repository, or UI change —
the brief still returns the same normalized `Brief`, so the UI is untouched.

## The flow
```
snapshots (ground truth: id, name, index, price, changePct, open)
   │
   ├─▶ Fundamental desk ─┐   (3 analyst calls, in parallel, maxTokens 900 each)
   ├─▶ Sentiment desk   ─┼─▶ desk filings {view, markets:[{id,s,note}]}
   └─▶ Technical desk   ─┘
                          │
                          ▼
                 Chief editor call  (maxTokens 4000, reconciles the three)
                          │
                          ▼
             Brief {lead, lines[], hint} + citations = the 3 desks
```

## The desks
Defined once in `_desks` (id · UI label · lens), so the brief cache, the prompts, and the citation
chips all line up:

| id | Label (UI chip) | Lens |
|----|-----------------|------|
| `fundamental` | Fundamental desk | macro & fundamentals — moves vs the broad regime (rates, growth, rotation) |
| `sentiment` | Sentiment desk | sentiment & risk — risk-on/risk-off tone and cross-market momentum |
| `technical` | Technical desk | technicals & price action — size/direction of each move, relative strength |

## Key methods (`DeepSeekSource`)
- `_multiAgent` — `static final bool = true`. The on/off gate. `final` (not `const`) so the retained
  one-shot path (`_soloBrief`) isn't flagged as dead code. Flip to `false` to revert instantly.
- `_chat(user, maxTokens, {system})` — now takes an optional `system` override (was hard-coded).
- `_analystSystem(lens)` / `_editorSystem` — the desk and editor system prompts.
- `_deskFiling(desk, ground)` — one analyst's compact JSON filing; **fails soft** to an empty filing
  so one desk erroring can't sink the brief.
- `_panelBrief(snapshots)` — runs the three desks with `Future.wait`, then the editor synthesis, then
  `_parseBrief(..., source: 'deepseek-chat · 3-desk panel', citations: <desk labels>)`.
- `fetchBrief` — caches under `deepseek:brief:panel` (24h, success-only) and dispatches to
  `_panelBrief` or `_soloBrief` per `_multiAgent`.
- `_parseBrief(data, {source, citations})` — gained optional overrides so the panel can stamp its
  source label and surface the desks as the brief's citations.

## What changes on screen
- **SOURCES** chips read **Fundamental desk · Sentiment desk · Technical desk** (was generic/empty).
- Footer attribution reads **`deepseek-chat · 3-desk panel`**.
- The lead/lines/hint read more reconciled — the editor is told to note where desks disagree.

## Scope & guardrails
- **Direct DeepSeek path only** (desktop with a local `.env` key — the user's normal Option 1). The
  proxy backend (`ai_proxy_source.dart`) is server-side and unchanged (still one-shot).
- Same **"use only the provided numbers / no web / not investment advice"** rules in every prompt.
- Same immutable `Brief` model and **24h success-only cache**. New cache key so it regenerates cleanly
  the first time after the change.

## Cost note
The panel is **4 model calls per brief** instead of 1, but it's cached 24h → **once per day**. If cost
matters more than depth, set `_multiAgent = false` to fall back to the single call
(`deepseek:brief`). Per-market Takes remain mock-gated (`_liveTakes = false`), unchanged.

## Verification
`flutter analyze` clean; both offline smoke tests pass. Live path confirmed by launching the desktop
app with the `.env` key — the brief card renders the three desk chips.
