# My stocks — where we stopped, and what's left

**Last worked: 2026-08-06.** Handoff note for continuing on another device.

The goal: **search for a stock that isn't in a market's curated list → add it → it behaves like every
other stock** (live price, change, dividend yield, tappable price curve), and the list **survives
closing the app** by living in Firebase under a collection named `ephedrine2010`.

---

## Status at a glance

| Stage | What | State |
|---|---|---|
| **1** | Search + "My stocks" section, **in memory** | ✅ **Done & verified** |
| **2** | Firestore persistence + local mirror | ⛔ Not started — blocked by stage 3 |
| **3** | Google sign-in (Windows needs custom OAuth) | ⛔ Not started |

**The list currently resets when the app closes.** That is expected — persistence is stage 2, and it
can't work until stage 3 exists, because `firestore.rules` already demands a signed-in user and
nothing signs in yet.

---

## Decisions already made (don't re-litigate these)

Settled over several rounds; the build follows them.

| Question | Decision |
|---|---|
| Where do added stocks appear? | **Their own "My stocks" section**, between the curated leaders and the session's movers — so those two lists keep meaning what they say |
| Search scope | **Current market only** — results are filtered to that market's own exchange, so an added row's currency and trading-hours labels stay truthful |
| Persistence | **Firebase Firestore**, all data under a root collection named **`ephedrine2010`** |
| Auth | **Real Google sign-in** (not anonymous), per-user doc at `ephedrine2010/{uid}` |
| Auth on Windows | `google_sign_in` has **no Windows support** → hand-rolled **loopback OAuth with PKCE** |
| Does sign-in gate the app? | **No.** Only "My stocks" is gated; the dashboard, tiles, screener, charts and details all work signed-out exactly as today |

---

## Stage 1 — what was built (done)

### New files
| File | Role |
|---|---|
| `lib/data/models/saved_stock.dart` | `SavedStock` — identity only, plus `toJson`/`fromJson` ready for stage 2 |
| `lib/services/my_stocks_service.dart` | Routes search + prices saved rows. `DataPolicy`-aware. **Never mocks** |
| `lib/services/my_stocks_store.dart` | **The persistence seam.** In-memory today; Firestore slots in here |
| `lib/market_details/cubit/my_stocks_cubit.dart` + `my_stocks_state.dart` | One market's saved list + its live rows |
| `lib/market_details/cubit/stock_search_cubit.dart` | The debounced search box (350 ms, min 2 chars) |
| `lib/market_details/widgets/my_stocks_table.dart` | The table — same 5 columns as leaders, plus remove |
| `lib/market_details/widgets/add_stock_dialog.dart` | `showAddStock()` — search field + results |
| `test/search_probe.dart` | Live probe (excluded from `flutter test` — no `_test` suffix) |

### Changed files
| File | Change |
|---|---|
| `lib/services/sources/yahoo_source.dart` | `search()`, `fetchLeaderRow()`, extracted `_leaderFor()`, `_probeAsTicker()`, `_suffixesFor()` |
| `lib/services/sources/coingecko_source.dart` | `search()` + `fetchLeaderRows()` |
| `lib/services/price_history_service.dart` | `HistoryTarget.fromSaved()` |
| `lib/services/dashboard_repository.dart` | `.myStocks` getter |
| `lib/market_details/market_details_dialog.dart` | The section, `MultiBlocProvider`, saved stocks folded into `_chartTargets` |
| `lib/market_details/widgets/leaders_table.dart` | `_DividendCell` → public `DividendCell` (shared with the new table) |
| `lib/main.dart` | Creates + `load()`s the store before the first frame, provides it |
| `lib/data/models/models.dart` | Barrel export |
| `test/smoke_test.dart` | 2 new tests |
| `CLAUDE.md` | New "My stocks" section + folder tables |

### Verified
- `flutter analyze` — clean.
- `flutter test` — **9/9 pass**.
- `flutter test test/search_probe.dart` — **live, both probes pass**:
  ```
  🇺🇸 "palantir" → PLTR      Palantir Technologies Inc.
  🇸🇦 "alinma"   → 1150.SR   Alinma Bank  (+3 more, all .SR)
  🇪🇬 "COMI"     → COMI.CA   Commercial International Bank Egypt
  🇨🇳 "600519"   → 600519.SS Kweichow Moutai
  🇦🇪 "EMAAR"    → EMAAR.AE  Emaar Properties PJSC
  🪙 "cardano"  → cardano   Cardano
  row PLTR px=158.43 chg=-2.60% div=—
  ```

**Not yet done:** nobody has clicked through this in the running Windows app. Worth doing first thing.

---

## Gotchas discovered (keep these)

- **Yahoo's search index doesn't cover every exchange its chart endpoint serves.** EGX (`.CA`)
  returns **zero hits for any query** — including `COMI` and `COMI.CA` — yet `COMI.CA` prices fine.
  That's why `_probeAsTicker` exists: an empty scoped search retries `<query><suffix>` and offers it
  **only after a real quote comes back**. Without it Egypt could never add a stock. It is a
  verification, not a guess — don't loosen it into "just append the suffix".
- **Exchange suffixes are derived, not tabled.** `_suffixesFor()` reads each market's
  `movers` + `leaders` in `markets.dart`. It deliberately **excludes `watch`**, whose refs omit the
  `yahoo:` field and would contribute a bogus empty suffix — letting US tickers into the KSA list.
- **Multi-word queries on thin exchanges can still miss.** `"ping an"` → 0 for China (Yahoo ranks the
  HK listing above `.SS`, and the ticker probe correctly refuses to treat a phrase as a ticker).
  `601318` works. Acceptable; don't "fix" it by guessing.
- **A saved stock that can't be priced still renders**, with muted "—"s. Dropping a row the user
  explicitly added reads as the app having forgotten it.
- **Gold and USA share the "no suffix" set**, so the Gold dialog's search will accept any US-listed
  ticker. There's no way to tell "gold-related" from a ticker suffix; accepted as-is.
- `SavedStock` stores **identity only**, never a price — same reason the curves never mock.

---

## Stage 2 — Firestore persistence (not started)

Everything lands inside **`lib/services/my_stocks_store.dart`**. That's the point of the seam: the
cubits and widgets don't change.

### Data shape
```
ephedrine2010/{uid}          ← one doc per signed-in user
  {
    my_stocks: {
      us: [ {marketId, symbol, name, query, provider}, … ],
      sa: [ … ],
      cr: [ … ]
    },
    updatedAt: <server timestamp>
  }
```
`SavedStock.toJson()` / `.fromJson()` already produce exactly this row shape. `fromJson` returns
`null` for a malformed record rather than throwing, so one bad entry can't take the list down.

### Work
1. `flutter pub add cloud_firestore` (6.8.0 — Android/iOS/macOS/Web/**Windows**; **no Linux**).
2. In `MyStocksStore`: `load()` does one `get()` of `ephedrine2010/{uid}`; `add`/`remove` write
   through, optimistically (update in memory + emit first, revert on failure — never claim a save
   that didn't happen).
3. **Mirror locally to `shared_preferences`** (already a dependency, currently unused anywhere in
   `lib/`). The list then renders instantly on launch and survives a Firestore outage. Firestore is
   the source of truth; the mirror reconciles when it answers.
4. Update `firestore.rules` to isolate per user, then `firebase deploy --only firestore:rules`:
   ```
   match /ephedrine2010/{uid} {
     allow read, write: if request.auth != null && request.auth.uid == uid;
   }
   ```
5. Signed-out behaviour: keep the current in-memory list for the session and show a
   "Sign in to save your stocks" affordance in the section — do **not** gate the rest of the app.

---

## Stage 3 — Google sign-in (not started)

Build in this order so the risky part is isolated and last.

### 3a. Packages + auth surface
- `flutter pub add firebase_auth` (6.5.7 — Android/iOS/macOS/Web/**Windows**; no Linux).
- `lib/services/auth_service.dart` — one interface, platform-branching implementation.
- `lib/auth/cubit/auth_cubit.dart` — `signed-out / signing-in / signed-in(uid)`, from
  `FirebaseAuth.instance.authStateChanges()`.
- Sign-in button lives **only** in the My stocks empty state.

### 3b. Google on mobile / web / macOS
- `flutter pub add google_sign_in` (7.2.0 — Android/iOS/macOS/Web; **NOT Windows, NOT Linux**).
- The package does the work; exchange its token for a Firebase credential.

### 3c. Windows — hand-rolled loopback OAuth (the risky part, do last)
`google_sign_in` has no Windows support, so:
1. Start a local `HttpServer` on `127.0.0.1:<free port>`.
2. Launch the system browser to Google's auth endpoint with **PKCE** (`code_challenge`), the client
   id from `.env`, and `redirect_uri=http://127.0.0.1:<port>`.
3. Catch the redirect, exchange `code` + `code_verifier` for tokens.
4. `GoogleAuthProvider.credential(idToken: …)` → `FirebaseAuth.instance.signInWithCredential(…)`.

No redirect URI needs registering — Google allows installed-app clients **any loopback port**.
A desktop client's "secret" is not confidential (it ships in the binary); PKCE is what actually
secures this flow. Read both values from `.env` (gitignored) — **never hardcode them**, same rule the
DeepSeek key follows. Needs `url_launcher` (not yet a dependency).

---

## Firebase console setup — state

Full details in [`documentation/firebase/firebase.md`](../firebase/firebase.md).

| # | Item | State |
|---|---|---|
| 1 | Google provider enabled in Authentication | ✅ Done |
| 2 | OAuth 2.0 **Desktop** client created; id + secret in `.env` | ✅ Done — `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET` present |
| 3 | Android SHA-1 fingerprint registered | ❌ **Not landed** — see below |
| 4 | Web authorized JavaScript origins | ❌ Not done (web-only; blocks nothing on Windows) |

### The Android SHA-1 problem
`android/app/google-services.json` still reads `"oauth_client": []` after two re-downloads. When a
fingerprint is registered *and* Google Sign-In is enabled, that array gets a `client_type: 1` entry
carrying `android_info.certificate_hash`. Empty ⇒ the fingerprint isn't saved on the Firebase
**Android app**.

Debug keystore SHA-1 (re-read any time with the command in the firebase doc):
```
99:41:10:95:5F:9B:A3:F0:3F:08:83:C1:A3:F0:16:5C:17:0B:FA:F1
```
Check it went onto **Project settings → Your apps → the Android app** (not the web app), and that it
was the **SHA1** line, not SHA256. **Android-only — blocks nothing on Windows or web.**

Also note: the Android package is still `com.example.stocks_etfs_eye`. Fine for development; the Play
Store will not accept a `com.example.*` package.

---

## Resuming on another device

```bash
flutter pub get
flutter analyze                      # expect clean
flutter test                         # expect 9/9
flutter test test/search_probe.dart  # live; expect both probes to pass
flutter run -d windows               # click through: open a market → Add stock
```

**`.env` is gitignored and will NOT be on the new machine.** Recreate it with the four keys —
`DEEPSEEK_API_KEY`, `FINNHUB_API_KEY`, `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET` —
copied from the old machine or re-issued in the consoles.

Kill a stale Windows instance before relaunching:
```bash
taskkill //F //IM stocks_etfs_eye.exe
```

---

## Suggested next session

1. Run the Windows app and click through the feature end-to-end (5 min — nothing has been seen live).
2. Stage 3a + 3b — auth on the platforms where the package does the work.
3. Stage 2 — Firestore, now that a uid exists.
4. Stage 3c — Windows loopback OAuth, last.
