# Bookmark++ design: standalone sibling of built-in `bookmark.el`

## Goal

Refactor Bookmark+ from a **replacement** of the built-in `bookmark.el`
into an **additive sibling** that coexists with it cleanly. After the
refactor:

- Loading bookmark++ does not redefine any function from `bookmark.el`.
- Every command in bookmark++ is prefixed `bmkp-` (or lives in
  `bmkp-list-mode`).
- The built-in `bookmark-set` / `bookmark-jump` / `*Bookmark List*`
  work exactly as their manual entries describe.
- `unload-feature 'bookmark+` leaves a working Emacs.
- Third-party packages that read or call `bookmark-*` (consult-bookmark,
  helm-bookmark, org-bookmark, etc.) are unaffected by the load.

## Shared store, parallel commands and UIs

Bookmarks live where they have always lived: in the variable
`bookmark-alist`, persisted to the path named by `bookmark-default-file`
(or `bmkp-current-bookmark-file` when using multi-file features). There
is no separate `bmkp-alist`, no separate `bmkp-bookmark-default-file`.

Two parallel command sets operate on the shared alist:

| Concern              | Built-in                  | Bookmark++                           |
|----------------------+---------------------------+--------------------------------------|
| Create at point      | `bookmark-set`            | `bmkp-set` (type-aware, tags, hooks) |
| Jump                 | `bookmark-jump`           | `bmkp-jump` (region, type-default)   |
| Rename / delete      | `bookmark-{rename,delete}`| `bmkp-{rename,delete}`               |
| Annotation editing   | `bookmark-edit-annotation`| `bmkp-edit-annotation`               |
| Load / save file     | `bookmark-{load,save}`    | `bmkp-{load,save}` (multi-file)      |
| Browse buffer        | `*Bookmark List*`         | `*Bmkp List*` (rich UI)              |

A user can pick either set at any moment. The records produced by
either are valid bookmarks the other can see.

## Record identity: the `id` field

Every bookmark record carries an `(id . STRING)` property in its
property alist:

```elisp
("README.md" (id . "8f3a7b3c-...")
             (filename . "/path/to/proj-A/README.md")
             (position . 1234)
             ...)
```

- `id` is opaque (`format-time-string` plus random hex bits).
- It is assigned at record creation by `bookmark-make-record-default`.
- For records read from a file that lack `id` (created by the built-in,
  or by earlier bookmark++ versions), one is generated at load time
  and the alist is marked dirty so the next save writes them.
- The built-in `bookmark.el` ignores `id` on read and preserves it on
  save. Round-trip is safe in both directions.

Lookups:

```elisp
(bmkp-get-by-id   ID)    ; → exactly one record, or nil
;; Name lookup is just (assoc NAME bookmark-alist) — names are unique.
```

The `id` field is the **stable** identity that survives renames.
Names are unique display labels, but they may change at any time
(rename, auto-disambiguate). Anywhere we need "this specific bookmark
even if it gets renamed later" (sequence bookmarks, bookmark-list
bookmarks), we store the `id`, not the name.

## Name uniqueness

Bookmark names are enforced unique within `bookmark-alist`. Two
mechanisms maintain this:

1. **Auto-disambiguate on creation.** When `bookmark-store` is asked
   to create a new bookmark (no-overwrite arg) whose name collides
   with an existing one, the new bookmark is auto-renamed
   `foo` → `foo<2>` → `foo<3>` → ... Callers that need to refer to
   the bookmark afterward use the return value's `car`, not the
   originally-requested name.
2. **Deduplicate on load.** `bmkp-deduplicate-bookmark-names` runs
   on `bmkp-read-bookmark-file-hook` and renames any duplicate names
   found in a loaded bookmark file, marking the alist dirty so the
   next save persists the new names. This covers files written by
   the built-in `bookmark.el` (which doesn't enforce uniqueness) and
   files written by older bookmark+ versions.

This replaces the upstream Bookmark+ "same-named bookmarks coexist"
feature. The same use cases (autofiles in multiple directories with
the same basename) still work; they show as `README.md`,
`README.md<2>`, etc.

## What goes away

The `bmkp-full-record` text-property trick disappears entirely, along
with:

- `bmkp-propertize-bookmark-names-flag` defcustom and all its
  branches.
- The `print-circle` / `print-gensym` binding around file writes.
- `bmkp-maybe-unpropertize-bookmark-names` and the
  property-stripping code paths.
- `bookmark-get-bookmark` / `bookmark-get-bookmark-record` replacements.

All 65 "REPLACES ORIGINAL" comment blocks disappear too: the
replacements either move under `bmkp-*` names (the richer features
become first-class bmkp commands) or vanish (the property-trick
plumbing).

## What stays as opt-in

For users who want bookmark++'s extras to fire when they invoke the
**built-in** commands (e.g. so `bookmark-jump` from
`consult-bookmark` still pulse-highlights the landing line),
bookmark++ ships a single optional integration:

```elisp
(bmkp-install-builtin-advice)
```

This is `advice-add` on `bookmark-jump` (and a small handful of
others). It is **not** called from the package's load path. The user
opts in explicitly in their init.el. Removing the advice is
`(bmkp-uninstall-builtin-advice)`.

This is the deliberate escape hatch for users who want the old
"transparent enhancement" feel without the package replacing
anything.

## The `*Bmkp List*` buffer

A new major mode `bmkp-list-mode`, derived from `special-mode`.

- Lives in buffer `*Bmkp List*`. Built-in's `*Bookmark List*` is
  left alone.
- Reads / displays / mutates the same `bookmark-alist`.
- Carries all current bookmark+ richness: filter by type / tag /
  pattern, sort by many fields, mark for action, copy/move across
  files, query-replace through marked, define commands from view.
- Does **not** derive from `tabulated-list-mode`.

`M-x bookmark-bmenu-list` still opens the built-in's `*Bookmark
List*`. `M-x bmkp-list` opens `*Bmkp List*`.

## Migration story for existing user bookmark files

A bookmark file written by Bookmark+ today contains records with the
`bmkp-full-record` text property and was written with `print-circle`,
so it may have `#1=...` / `#1#` markers and other curiosities.

On first load by the refactored package:

1. Read the file the normal way; the property-trick markers are
   ignored or treated as inert.
2. For each record without `id`, generate one and add it.
3. Strip any `bmkp-full-record` text properties from name strings.
4. Mark the alist dirty; the next save writes a clean file the built-in
   can read and round-trip without caveat.

User-visible effect: nothing changes for them. Behind the scenes the
file format becomes plain printable Lisp.

## Phased plan

Each phase ends with a clean compile and a working package.

1. **id field + migration code.** `bookmark-make-record-default`
   produces records with `id`.  Add `bmkp-get-by-id`.  Load-time
   migration assigns `id` to records that lack one.  Existing
   text-property machinery remains untouched (parallel paths).

2. **Enforce name uniqueness.** `bookmark-store` auto-disambiguates
   colliding names (`foo` -> `foo<2>` -> ...); the caller in
   `bookmark-set` captures the actual stored name from the return
   value.  `bmkp-deduplicate-bookmark-names` runs on load to fix
   duplicates inherited from older files.  With names guaranteed
   unique, the text-property trick is no longer load-bearing:
   `(assoc name bookmark-alist)` is precise.  Net code change is
   small (~60 lines) because we chose uniqueness over preserving
   the upstream "same-named bookmarks coexist" feature.

3. **Drop the `bmkp-full-record` text-property machinery.** Remove
   all `put-text-property 'bmkp-full-record` setter sites and the
   `get-text-property` reader sites that follow them.  Remove the
   `print-circle` / `print-gensym` binding around file writes, the
   `bmkp-propertize-bookmark-names-flag` defcustom and its
   branches, and the `bmkp-maybe-unpropertize-*` helpers.
   `bmkp-get-bookmark` becomes a thin wrapper over `assoc`.  The
   `bookmark-get-bookmark` and `bookmark-get-bookmark-record`
   redefinitions can be dropped entirely.  Expected diff: ~300-400
   lines removed.

4. **Rename `bookmark-*` redefinitions to `bmkp-*`.** Bucket 2 from
   our analysis: `bookmark-set` / `-jump` / `-delete` / etc. become
   `bmkp-*` standalone commands. The built-in's defuns are left
   untouched. Update internal callers and key bindings.

5. **Extract `*Bmkp List*`.** Rename `bookmark-bmenu-*` overrides
   to `bmkp-list-*`. New buffer `*Bmkp List*`, new major mode
   `bmkp-list-mode` (not derived from `tabulated-list-mode`).
   Built-in's `bookmark-bmenu-list` left alone.

6. **Optional advice integration.** Provide
   `bmkp-install-builtin-advice` / `bmkp-uninstall-builtin-advice`
   for users who want bmkp behavior to fire from built-in commands.

7. **Docs.** Update readme.org, doc/reference.org, CLAUDE.md.
   Replace the "Differences from built-in" table with a "How
   bookmark++ relates to built-in" section that's now a much
   simpler story.

Phases 1–3 are the bulk of the work (probably 60 % of the eventual
diff) but they are internal: no user-facing rename. Phases 4–5 are
mostly mechanical renames across thousands of references. Phase 6 is
small. Phase 7 is documentation.

## Things deliberately not decided here

- **Key bindings.** `C-x r m` / `C-x r b` / `C-x r l` stay on the
  built-in. Bookmark++ uses `C-x x` (already its prefix) and
  `C-x j`. Users who want bookmark++ on `C-x r *` rebind themselves.
- **Default-handler dispatch for typed bookmarks.** Typed bookmark
  records have `(handler . bmkp-jump-X)`. The built-in's
  `bookmark-handle-bookmark` dispatches to whatever is in `handler`,
  so typed bookmarks work even when invoked via the built-in's
  `bookmark-jump`. No replacement of `bookmark-handle-bookmark`
  needed.
- **`bmkp-modified-bookmarks` tracking.** Useful feature. Will be
  reimplemented by comparing against the on-disk snapshot at file
  load, then per-mutation in bmkp commands. We do *not* track
  mutations made by the built-in's commands; if the user wants
  that, they enable the optional advice.
- **Backup-friendly file writes** (`write-file` vs `write-region`)
  are a small improvement; arguably worth a one-line patch to
  upstream Emacs. Until then, `bmkp-save` uses `write-file`.

## Sizing estimate

Current package: ~25 000 source lines plus ~10 000 lines of
upstream-style commentary files.

Post-refactor: 35–45 % smaller. Plain target: 15 000 source lines,
plus a halved commentary file.

The shrink comes from three sources:

1. The 65 "REPLACES ORIGINAL" comment blocks themselves
   (~600–800 lines of metadata).
2. The text-property machinery and its protective code paths
   (~300–400 lines).
3. The defensive Emacs-version compatibility checks that exist
   because bookmark++ has to stay drop-in compatible with whatever
   the built-in does this year (~100–200 lines).

## Risk and the rollback story

Each phase is its own series of commits, with the package compiling
clean and the manual smoke tests passing at the end of each. If a
phase reveals a problem we hadn't predicted, we stop at the previous
clean commit and reconsider.

The reversal of the whole refactor is `git revert` of the phase
commits. The text-property trick code is preserved in history
unchanged for as long as we want to be able to recover it.

## Status

- **Phase 1 (id field + migration code)** — done.
- **Phase 2 (name uniqueness)** — done.  `bookmark-store`
  auto-disambiguates; `bmkp-deduplicate-bookmark-names` runs on load.
- **Phase 3 (drop `bmkp-full-record` machinery)** — done.  All setter
  sites removed; `bmkp-get-bookmark` is a plain `assoc`; the
  `print-circle`/`print-gensym` write binding is gone; the
  `bmkp-propertize-bookmark-names-flag` defcustom is gone.
- **Phase 4 (rename `bookmark-*` redefinitions to `bmkp-*`)** — done.
- **Phase 5 (extract `*Bmkp List*`)** — done.  New major mode
  `bmkp-list-mode` (derived from `special-mode`) in its own buffer
  `*Bmkp List*`.  The built-in `bookmark-bmenu-list` /
  `*Bookmark List*` is untouched.
- **Phase 6 (optional advice integration)** — *dropped*.  Wiring
  `define-key` on `bookmark-map` or `advice-add` on `bookmark-jump`
  is a two-line user-init snippet; shipping a `bmkp-install-builtin-advice`
  helper added surface area without enough payoff.  The relevant
  snippets live in `readme.org` → "Binding bmkp commands to standard
  keys".
- **Phase 7 (docs)** — done.  `readme.org`, `doc/reference.org`, and
  `CLAUDE.md` reflect the sibling design.  `bookmark+-doc.el` (the
  upstream comment-only manual) is left for a later pass.
