# tools-map — split source (for review)

A one-page visual guide to stock/ETF analysis tooling, mapped onto the Stocks Eye pipeline.
Bilingual **English / Arabic** with a live toggle (RTL-aware) and light/dark themes.

## Files

| File | What it holds |
|------|---------------|
| `index.html` | Structure + all content (EN & AR variants side by side, marked `l-en` / `l-ar`). |
| `styles.css` | All styling: palette tokens, dual theme, the language/RTL machinery, layout. |
| `app.js` | Just the toggle — swaps `#page` between `mode-en` / `mode-ar` and updates `<html lang>`. |

## How the bilingual toggle works
- Every translatable node exists twice: `class="l-en"` and `class="l-ar"`.
- CSS hides the inactive one: `.mode-en .l-ar { display:none }` and vice-versa.
- Arabic mode also sets `direction: rtl` on `.wrap`; logical properties
  (`border-inline-end`, `inset-inline-end`, `text-align: start`) make the layout mirror cleanly.
- `.ar` applies the Arabic font stack.

## Review / run
Open `index.html` directly in a browser — no build step, no server.

## Note on the published Artifact
The Claude Artifact version is a single self-contained `tools-map.html` (CSS + JS inlined),
because the Artifact sandbox blocks external stylesheet/script files. These three split files
are the readable source; keep them in sync with that combined file if you edit either.
