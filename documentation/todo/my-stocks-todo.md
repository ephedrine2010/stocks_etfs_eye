# My stocks — what's left

**Last worked: 2026-08-06.**

The goal: **search for a stock that isn't in a market's curated list → add it → it behaves like every
other stock** (live price, change, dividend yield, tappable price curve), and the list **survives
closing the app** by living in Firebase under a root collection named `ephedrine2010`.

---

## Status at a glance

| Stage | What | State |
|---|---|---|
| **1** | Search + "My stocks" section | ✅ Built · `flutter analyze` clean · 16/16 tests |
| **3a** | Auth surface (`AuthService`, `AuthCubit`, sign-in strip) | ✅ Built |
| **3c** | Windows loopback OAuth + PKCE | ✅ **Verified live — sign-in works** |
| **2** | Firestore persistence + local mirror | ⚠️ Built + unit-tested, **round trip never observed** |
| **3b** | `google_sign_in` for Android/iOS/macOS/Web | ⛔ Not started |

`flutter analyze` clean, `flutter test` 16/16 — including `test/my_stocks_store_test.dart`, which
runs the store with Firebase *and* `shared_preferences` both absent to prove it degrades to
session-only instead of throwing.

---

## Do these next

### 1. Prove persistence actually round-trips ⚠️
Everything below it is built on the assumption that it does, and **nobody has watched it happen.**
The offline tests only prove the store survives its layers failing — they never touch Firestore.

1. Run the app, open USA → My stocks → **Sign in** → **Add stock** → `palantir` → add `PLTR`.
2. Close the app fully, relaunch, open USA.
3. `PLTR` should already be there, already signed in.
4. Separately: add a stock **while signed out**, *then* sign in — it must survive the merge in
   `MyStocksStore.bindUser` rather than vanish.

If it fails, look at `_writeRemote` / `_readRemote` in `lib/services/my_stocks_store.dart` first —
both swallow their exceptions on purpose (so a Firestore outage can't blank a list the user knows
they have), which also means **a genuine failure is silent**. Add a temporary `print` in those
`catch` blocks rather than assuming the write worked.

### 2. Deploy the tightened Firestore rules ⚠️ security
`firestore.rules` in the repo is correct but **has not been deployed**. What is live is still the old
blanket rule — *any* signed-in user can read and write *everything*. That was harmless when nothing
could sign in. Sign-in now works, so it isn't any more.

```bash
firebase deploy --only firestore:rules
```

### 3. Stage 3b — Google on mobile / web / macOS
- `flutter pub add google_sign_in` (7.2.0 — Android/iOS/macOS/Web; **NOT Windows, NOT Linux**).
- Fill in `googleAuthFlowFor()` in `lib/services/auth/google_flow_io.dart` (non-Windows branch) and
  `google_flow_stub.dart` (Web). Both return `UnavailableGoogleAuthFlow()` today, which is why the
  sign-in strip correctly renders **nothing** on those platforms instead of a dead button.
- Nothing above those two files should need to change — `GoogleAuthFlow` is the whole seam.

---

## Notes to check in future

### The OAuth client must live in the *same* project as Firebase 🔥
This cost the most time of anything here, because the error names the wrong thing. Firebase reports:

> the supplied auth credential is malformed or has expired  (`INVALID_IDP_RESPONSE`)

…for a token that is neither. Firebase only accepts a Google ID token whose `aud` is a client of
**its own** project. The client in `.env` had come from an unrelated project (`997023802750`) instead
of `stocketfseye` (`1049316374463`), so a flawless sign-in was refused at the last step.

**If that message ever returns:** compare the number prefixing `GOOGLE_OAUTH_CLIENT_ID` against
`projectId`/`messagingSenderId` in `lib/firebase_options.dart` *before* suspecting anything else.

A **Desktop**-type client in the right project works fine — the earlier theory that Firebase rejects
desktop clients outright was wrong. Desktop clients also accept **any** loopback port, which is why
the flow binds port 0 and needs no redirect URI registered.

### Console access — which account, which project
- **`ephedrine2010x@gmail.com` owns `stocketfseye`** — it is `authuser=2` in the browser, and what
  the Firebase CLI is logged in as. The browser's default account (`authuser=0`/`u/0`) has **no
  access at all** and gives a bare "project does not exist or you do not have permission".
- Firebase console URLs need `/u/2/`; Cloud console needs `?authuser=2`.
- There is an unrelated project called **`stocks-etfs-prj`** that the console likes to default to.
  It is not this app. Check the project chip before changing anything.

### The Web client's secret can no longer be read
Google shows only `****HpuP` and has permanently disabled viewing/downloading. Getting it would mean
minting a **new** secret on the very credential Firebase's Google provider uses. Avoided — the
Desktop client sidesteps it. Don't go down that path without a reason.

### Windows: exit segfault and threading warnings
On close the app logs and then segfaults:

```
firebase_auth_plugin/auth-state/[DEFAULT] channel sent a message
  from native to Flutter on a non-platform thread
grpc_wait_for_shutdown_with_timeout() timed out
Segmentation fault (exit 139)
```

- Both `non-platform thread` errors are **inside FlutterFire's Windows `firebase_auth` plugin** — it
  delivers auth-state and ID-token events off the platform thread, which Flutter forbids. Not
  fixable from Dart.
- The segfault follows the gRPC/Firestore teardown timeout and has only ever been seen **at exit**,
  after writes have already gone out. **Unresolved.** If it ever crashes *mid-session*, that's a
  different and more serious problem — investigate then rather than assuming it's the same thing.

### Console state — verify, don't trust this table
This table was wrong three separate times in one session (a ✅ for the `.env` keys that weren't
there, a ✅ for a provider that was disabled, a Desktop client that existed in the wrong project).
**Confirm in the console rather than believing the row.**

| # | Item | State (observed 2026-08-06) |
|---|---|---|
| 1 | Google provider in Authentication | ✅ Enabled |
| 2 | OAuth Desktop client **in `stocketfseye`** | ✅ "Stocks Eye Windows (loopback)"; id + secret in `.env` |
| 3 | OAuth consent screen | ✅ **In production**, External — no test-user list applies; scopes are `openid email profile` (non-sensitive, no verification needed) |
| 4 | Firestore rules deployed | ❌ **Not deployed** — see "Do these next" #2 |
| 5 | Android SHA-1 fingerprint | ❌ Not landed — see below |
| 6 | Web authorized JavaScript origins | ❌ Not done (web-only; blocks nothing on Windows) |

### The Android SHA-1 problem (Android only — blocks nothing on Windows or Web)
`android/app/google-services.json` still reads `"oauth_client": []` after two re-downloads. When a
fingerprint is registered *and* Google Sign-In is enabled, that array gains a `client_type: 1` entry
carrying `android_info.certificate_hash`. Empty ⇒ the fingerprint isn't saved on the Firebase
**Android app**.

Debug keystore SHA-1:
```
99:41:10:95:5F:9B:A3:F0:3F:08:83:C1:A3:F0:16:5C:17:0B:FA:F1
```
Check it went onto **Project settings → Your apps → the Android app** (not the web app), and that it
was the **SHA1** line, not SHA256.

Also: the Android package is still `com.example.stocks_etfs_eye`. Fine for development; the Play
Store will not accept a `com.example.*` package.

---

## Decisions already made (don't re-litigate these)

| Question | Decision |
|---|---|
| Where do added stocks appear? | **Their own "My stocks" section**, between the curated leaders and the session's movers — so those two lists keep meaning what they say |
| Search scope | **Current market only** — results are filtered to that market's own exchange, so an added row's currency and trading-hours labels stay truthful |
| Persistence | **Firebase Firestore**, all data under a root collection named **`ephedrine2010`** |
| Auth | **Real Google sign-in** (not anonymous), per-user doc at `ephedrine2010/{uid}` |
| Auth on Windows | `google_sign_in` has no Windows support → hand-rolled **loopback OAuth with PKCE** |
| Does sign-in gate the app? | **No.** Only "My stocks" is gated; the dashboard, tiles, screener, charts and details all work signed-out exactly as today |
| Signed-out behaviour | The list still works, session-only. Signing in **merges** it upward rather than discarding it |

### Storage shape
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
Three layers, in order of authority: **memory** → **`shared_preferences`** mirror (per-uid, so the
list is on screen at launch instead of after a round trip) → **Firestore** (source of truth).
`SavedStock.fromJson` returns `null` for a malformed record rather than throwing, so one bad entry
can't take the list down.

---

## Gotchas worth keeping (from the search work)

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

## Resuming on another device

```bash
flutter pub get
flutter analyze                      # expect clean
flutter test                         # expect 16/16
flutter test test/search_probe.dart  # live; expect both probes to pass
flutter build windows --debug && ./build/windows/x64/runner/Debug/stocks_etfs_eye.exe
```

**`.env` is gitignored and will NOT be on a new machine.** Recreate it with four keys —
`DEEPSEEK_API_KEY`, `FINNHUB_API_KEY`, `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`. The
OAuth pair **must come from a Desktop client inside `stocketfseye`** (see the first note above); a
client from any other project produces a sign-in that works right up until Firebase refuses it.

Kill a stale Windows instance before relaunching:
```bash
taskkill //F //IM stocks_etfs_eye.exe
```
