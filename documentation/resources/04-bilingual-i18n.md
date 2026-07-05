# 04 · Bilingual EN ⇄ AR toggle

Adds an in-app **language switch** that flips the whole dashboard between **English and Arabic**,
including full **right-to-left** layout. A natural fit for the app's MENA focus (see the coverage gap
in [00-tooling-landscape.md](00-tooling-landscape.md)) — the markets are Gulf/Egypt, now the UI can be
too. The choice **persists** across relaunches.

## Files touched
| File | Change |
|------|--------|
| `lib/cubit/locale_cubit.dart` | **New** — shared `LocaleCubit` (Locale state + `toggle`/`setLocale`, persisted) |
| `lib/app/i18n.dart` | **New** — the `Strings` EN/AR lookup + `context.s` extension |
| `lib/main.dart` | Restore saved locale before first frame; provide `LocaleCubit`; drive `MaterialApp` (`locale`, `supportedLocales`, `localizationsDelegates`) |
| `lib/data/models/market_config.dart` · `market.dart` | Optional `nameAr`/`cityAr`; `nameFor(ar)`/`cityFor(ar)` getters |
| `lib/data/config/markets.dart` | Arabic name + city for each of the 7 markets (one entry each) |
| `lib/ui/widgets/topbar.dart` | The `EN | ع` toggle control + translated chrome |
| `lib/ui/…` (page + widgets) | Every static string routed through `context.s` |
| `lib/ui/widgets/data_table.dart` | Data grids pinned **LTR** even in RTL mode |
| `pubspec.yaml` | `flutter_localizations` (SDK) + `shared_preferences` |
| `test/smoke_test.dart` | New Arabic/RTL + toggle test |

## How it works
- **`LocaleCubit`** holds the current `Locale`. It's a cubit (not a new state lib, not local widget
  state) because the language is **shared/domain** state — the whole tree, layout direction included,
  reacts to it. Same rationale as `SelectionCubit` (see [03-cross-market-screener.md](03-cross-market-screener.md)).
- **RTL is automatic:** setting `MaterialApp.locale` flips `Directionality` for the entire subtree.
  `main.dart` wraps `MaterialApp` in a `BlocBuilder<LocaleCubit, Locale>` so a toggle rebuilds it.
- **Strings** is a single ~60-entry EN/AR lookup read via `context.s`. Deliberately **not** the
  ARB/`gen-l10n` pipeline: at this size a plain, fully type-checked class is lighter and adds no build
  step. Market names/cities localize via `nameAr`/`cityAr` on the config (fallback to English).
- **Persistence:** `shared_preferences`. `LocaleCubit.load()` runs in `main` before `runApp`, so the
  app opens in the last-chosen language with no wrong-direction flash.

## Scope — what is and isn't translated
Only **static chrome** is translated (labels, buttons, headers, pills, disclaimers, market names,
OPEN/CLOSED, sentiment labels) **plus the AI Morning Brief** (see below). The rest of the **dynamic
content stays in its source language** — RSS headlines, per-market Take text (mock-gated off),
company names, tickers, prices. That's expected, not a gap; a half-translated toggle would read as
broken, so the chrome is all-or-nothing while raw data is left as-is. Dates keep the Latin
`EEE, d MMM yyyy` format (no `ar` date-symbol init needed).

## Bilingual AI Morning Brief (Option B)
The brief is AI-generated, so it can't be translated from a static table — instead **DeepSeek returns
both languages in one response** and the UI picks per locale. Chosen over prompting per-language
because the brief is **cached 24h**: one generation holds both, so toggling is instant with **no
refetch** and no extra model calls.
- **Model:** a small `LocalizedText {en, ar}` ([ai.dart](../../lib/data/models/ai.dart)); `Brief.lead`,
  `Brief.hint`, and each `BriefLine.text` use it. `resolve(ar)` falls back to English if the Arabic
  side is empty, so a partial reply still renders. `BriefLine.name` stays a short Latin label (it sits
  in a 46px slot).
- **Prompt:** the editor/solo prompts ask for every text field as `{"en":"…","ar":"…"}` with a
  *natural* (not literal) Arabic rendering; `max_tokens` raised 4000→6000 for the second language.
  The three internal desk filings stay English-only (never shown). The "use only the given numbers /
  no web / not investment advice" guardrails are unchanged.
- **Parser:** `_localized(v)` reads the `{en, ar}` object, or treats a plain string as mono (both
  languages) — so a degraded/older reply never breaks.
- **Direct path is fully bilingual.** The **proxy** path is bilingual-*ready* (its parser is tolerant)
  but returns mono English until the Node proxy is taught the new schema — the same direct-path-first
  staging as the multi-agent panel in [01](01-multi-agent-brief.md). The **mock** brief ships hand-
  written Arabic so the no-key/offline experience is bilingual too.

## Gotchas to preserve
- **`context.s` uses `watch`, not `read`.** A string-reading widget must *subscribe* to the language
  so it rebuilds on toggle. With `read`, widgets under `const DashboardPage` never rebuild — only
  `Directionality` flips, and the visible text stays in the old language. `watch` reaches through
  `const` ancestors via the inherited-dependency mechanism. (This shipped broken once until the
  Arabic test caught it.)
- **Call `context.s` only during `build`.** `watch` outside build throws. The screener's per-column
  header callback runs during the *table's* build, not the screener's — so its headers are resolved
  in `build` and passed into the callback (`_headerCell(col, headers)`), never read live inside it.
- **Data tables are pinned LTR** (`Directionality(textDirection: ltr)` in `AppTable`) even in Arabic:
  tickers, prices and percentages are Latin/numeric and read L→R, and it keeps column order +
  numeric right-alignment stable. Arabic header labels still render correctly (each text run carries
  its own direction).
- **Header rows must let the label flex.** The brief eyebrow overflowed by 147px in Arabic because
  the (much longer) Arabic title was a fixed child; wrapping it in `Flexible` fixed it — the same
  lesson as the screener header in [03](03-cross-market-screener.md). Always re-run `flutter test`;
  the 320–390px no-overflow assertion (now also exercised in Arabic) catches exactly this.

## Verification
`flutter analyze` clean; **all three smoke tests pass**, including the new
*"renders in Arabic (RTL) without overflow and can toggle back"* — it asserts RTL directionality,
Arabic chrome renders, no overflow at 390px, that the **brief content itself is bilingual** (the
Arabic side of a mock brief line shows, then its English side after toggling), and that tapping
**EN** flips back to LTR English with no refetch.

## Where to extend next
- **Bilingual proxy brief** — teach the Node proxy's `/api/ai/brief` the `{en, ar}` schema so the Web
  build is bilingual too (the app-side parser already accepts it).
- **Bilingual per-market Takes** — apply the same `LocalizedText` pattern to `Take.text` whenever the
  live Takes gate (`_liveTakes`) is flipped on.
- **Native review of the wording** — the Arabic strings are reasonable but unreviewed; the footer /
  disclaimer sentences, "الفارز" (Screener), and the mock brief copy are worth a second look.
- **Localized number/date formatting** (Arabic-Indic digits) if desired — currently Latin everywhere.
