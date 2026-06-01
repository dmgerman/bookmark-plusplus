# bookmark-plusplus

A fork / modernization of Drew Adams' **Bookmark+** package (originally
hosted on EmacsWiki), targeting **Emacs 30+**. Vendored as a git submodule
under the parent `.emacs.d` repo; the `.git` file points to
`../../.git/modules/bookmark-plusplus`.

## Layout

- `bookmark+.el` — driver / entry point
- `bookmark+-mac.el` — macros (load *source*, not `.elc`, before
  byte-compiling the rest)
- `bookmark+-1.el` — main non-bmenu code
- `bookmark+-bmu.el` — `*Bookmark List*` (bmenu) buffer
- `bookmark+-key.el` — key and menu bindings
- `bookmark+-lit.el` — bookmark highlighting (optional)
- `bookmark+-doc.el` — upstream documentation (comment-only, untouched)
- `bookmark+-chg.el` — upstream changelog (comment-only, untouched)
- `readme.org`, `doc/reference.org` — locally-authored user docs

## What this fork has dropped from upstream

Modernization replaced or removed each of these external dependencies.
**Do not reintroduce them** — corresponding replacements are in place:

| Upstream dep | Replacement |
|---|---|
| `crosshairs.el` (Drew Adams) | built-in `pulse.el` (`bmkp-highlight-on-jump-flag` / `bmkp-highlight-jump-target`) |
| `fit-frame.el` (Drew Adams) | built-in `fit-frame-to-buffer` (helper: `bmkp-fit-bmenu-frame`) |
| `narrow-indirect.el` (Drew Adams) | built-in `clone-indirect-buffer-other-window` + `narrow-to-region` |
| `thingatpt+.el` (Drew Adams) | inlined as `bmkp-symbol-nearest-point`, `bmkp-region-or-symbol-name-nearest-point`, `bmkp-thing-at-point`; `bmkp-near-point-distance` defcustom |
| `zones.el` (Drew Adams) helper calls | inlined as `bmkp-read-any-variable`, `bmkp-readable-marker`. The izones bookmark *type* is still gated on `(boundp 'zz-izones-var)` because the data structure is zones-specific. |
| `linkd.el` (Drew Adams, dead since 2007) | built-in `outline-minor-mode` with `outline-regexp` matching Drew's `;;(@*` / `;;(@>` markers |
| `emacs-w3m` active integration | `bmkp-jump-w3m` now routes to `bmkp-jump-eww`; no new w3m bookmarks created |
| Icicles completion-framework integration | bookmark+ uses the built-in `completing-read` everywhere; users layer vertico / consult / marginalia / etc. on top |

`dired+.el` is still recognised as an optional dependency (Drew Adams, still
maintained); referenced via `(declare-function ...)`.

## Working here

- Source `.el` files are fair game to modify.
- Files are large (`bookmark+-1.el` is ~600 KB). Use `Read` with
  `offset`/`limit`, and `grep` for symbols before editing.
- Build cleanly with: `emacs -Q --batch -L . -l bookmark+-mac.el -f
  batch-byte-compile bookmark+-mac.el bookmark+-lit.el bookmark+-bmu.el
  bookmark+-1.el bookmark+-key.el bookmark+.el`. Should produce **0
  warnings** under Emacs 30+.
- Confirm the approach before making changes (per global `CLAUDE.md`).
- **Do not commit** unless the user explicitly grants authority for the
  current session. When in doubt, stage and ask.
