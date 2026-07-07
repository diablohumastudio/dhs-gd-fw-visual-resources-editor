# VRE — Open Issues & TODOs

Open architectural issues, consolidated from Claude, Codex, and Gemini
analyses. **This file tracks open items only** — when an item is resolved,
move it to [CHANGELOG.md](CHANGELOG.md) keeping its number for traceability.
Open code-level findings live in [FIXES.md](FIXES.md).

---

### 4. Synchronous Scanning on Class Switch

**Status:** ❌ Open (low priority — profile first)

Live refresh no longer rescans (deltas come from FileSystemMonitor), but a
full synchronous scan remains on class/filter switch
(`ProjectClassScanner.load_classed_resources_from_dir`). Threading is only
worth it if switching is measurably slow on real projects (100+ resources).
See also FIXES.md #11 (first-line file reads make this scan slower than
needed).

---

### 5. Manual Window Lifecycle Management

**Status:** ❌ Open

`visual_resources_editor_toolbar.gd` manually instantiates the window and adds
it to the editor's base control — the editor doesn't track it across sessions
or layout changes.

**Fix:** Register as a proper editor dock, or use a window subclass integrated
with the engine's layout/docking system.

---

### 6. O(N) Linear Scan in Change Detection

**Status:** ❌ Open (low priority)

`ResourceRepository._find_loaded()` and `_apply_to_current()` do linear
searches over `current_class_resources` per changed file. Fine at current
scale; a `Dictionary[String, Resource]` index would make it O(1) if projects
grow to 1000+ resources per class.

**References:**
- `model/resource_repository.gd:169-186`

---

## Rejected

- **#3 Rigid UI coupling via `%UniqueNames`** — won't fix; `%UniqueNode` IS
  the studio convention. Treat renaming a unique node as a public-API rename.
  See ARCHITECTURE.md § Design Decisions.

## Priority Ranking

| # | Item | Effort | Impact |
|---|------|--------|--------|
| 5 | Manual window lifecycle | Medium | Medium — stability |
| 4 | Synchronous scan on class switch | High | Low — profile first |
| 6 | O(N) linear scan | Low | Low — only at scale |
