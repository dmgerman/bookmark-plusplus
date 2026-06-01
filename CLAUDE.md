# bookmark-plusplus

A fork / modernization of Drew Adams' **Bookmark+** package (originally
hosted on EmacsWiki). Vendored as a git submodule under the parent
`.emacs.d` repo; the `.git` file points to `../../.git/modules/bookmark-plusplus`.

## Layout

- `bookmark+.el` — driver / entry point
- `bookmark+-mac.el` — macros (load *source*, not `.elc`, before
  byte-compiling the rest)
- `bookmark+-1.el` — main non-bmenu code
- `bookmark+-bmu.el` — `*Bookmark List*` (bmenu) buffer
- `bookmark+-key.el` — key and menu bindings
- `bookmark+-lit.el` — bookmark highlighting (optional)
- `bookmark+-doc.el` — upstream documentation (comment-only)
- `bookmark+-chg.el` — upstream changelog (comment-only)
- `readme.org`, `doc/reference.org` — locally-authored user docs

## Working here

- This is a **fork**: source `.el` files are fair game to modify.
  Modernization tasks (lexical-binding cleanup, deprecated API removal,
  cl-lib migration, namespace tidy-up, etc.) are the point.
- Files are large (`bookmark+-1.el` is ~740 KB). Use `Read` with
  `offset`/`limit`, and `grep` for symbols before editing.
- Confirm the approach before making changes (per global `CLAUDE.md`).
- **Never commit** (parent `.emacs.d/CLAUDE.md` rule). User commits.
