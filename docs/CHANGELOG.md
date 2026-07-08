# Changelog

Resolved items from [FIXES.md](FIXES.md) and [TODOS.md](TODOS.md) are recorded
here with their original numbers; those files track open items only.

## [Unreleased]

### Changed
- Restructured folders to MVVM layer names: `core/` → `model/` (flattened,
  `data_models/` merged in), `view_models/` → `viewmodel/`, `ui/` → `view/`.
- Moved `visual_resources_editor_window.gd/.tscn` to the addon root, next to
  the plugin and toolbar scripts (it is the composition root).
- Docs cleanup: removed superseded analysis/proposal documents; rewrote
  `ARCHITECTURE.md` against the current code; `FIXES.md` and `TODOS.md` now
  track open items only, resolved items move to this changelog.

### Added
- **Resizable columns**: header separators are now drag grips (`column_grip`)
  with an h-resize cursor; widths live in `ResourceListVM.column_widths`
  (File 200 / fields 120 default, 40 min) and reset when the class changes.
  The header ends in an invisible ghost of the row delete button so both sides
  compute identical total widths under any theme. *(resolves TODOS #8)*
- **Horizontal scroll** with a frozen header: rows scroll in `%RowsScroll`,
  the header follows in a scrollbar-less `%HeaderScroll` synced in code.
- `CLAUDE.md` with studio conventions and the docs workflow.

### Fixed
- Three stale `preload("uid://…")` calls pointed at old scene UIDs
  (header_field_label, resource_field_label, field_separator) and only
  resolved through the host project's UID cache; realigned with the scene
  headers.

## [2.0.0]

### Changed
- **MVVM rearchitecture**: removed the `VREStateManager` proxy and `VREModel`
  facade. `DH_VRE_ResourceRepository` is now the Model hub; ViewModels bind
  Views to it directly. Sort logic extracted to `DH_VRE_ResourceSorter`; class
  metadata to `DH_VRE_ResourceClassMap`. Every View binds to a dedicated VM;
  `DH_VRE_Window` is the composition root.
  *(resolves FIXES #1, #2, #3, #4, #5; TODOS #2, #7)*
- **Live refresh via FileSystemMonitor** (new peer dependency): the repository
  consumes `DH_FSM_ChangeSet`s instead of rescanning with an mtime cache.
  Handles create/modify/delete/move, class renames, and orphaned-class
  resaving incrementally.
  *(obsoletes FIXES #14; resolves most of TODOS #4 — class-switch scan
  remains open)*
- All disk writes centralized behind the repository (`save_one` /
  `save_multi`); bulk-edit writes are debounced so text fields no longer save
  per keystroke. *(resolves FIXES #7, #8; TODOS #1)*
- Delete I/O moved out of the View layer: `ConfirmDeleteDialog` delegates to
  its VM; `ResourceRepository.delete()` owns `OS.move_to_trash()`.
  *(resolves FIXES #10)*
- Class names prefixed `DH_VRE_` for studio-framework consistency.
- Extracted to its own repository, consumed as a git submodule.

### Added
- Peer-dependency guard: enabling the plugin without FileSystemMonitor raises
  a clear `push_error` naming the missing repo.
- Selection state pushed per-row: `ResourceListVM` pushes `is_selected` into
  row VMs — fixes the row-VM signal leak and O(N·M) selection sweeps.
  *(resolves FIXES #6)*

### Fixed
- "Create New" works for non-`@tool` classes (instantiate + null-check instead
  of `can_instantiate()`).
- `ResourceFieldLabel` no longer mutates the shared theme stylebox (duplicates
  it per instance). *(resolves FIXES #13)*
- Shadow counters removed: `ResourceListVM` recomputes counts from the
  pagination manager on every emit. *(resolves FIXES #23)*
- Bulk-edit multi-select is safe with mixed scripts: the inspector proxy is
  built from the common base-class script (only shared properties exposed) and
  only the edited property is written to the selected resources.
  *(resolves FIXES #16)*

### Removed
- Dead code: `class_definition.gd`, `StatusLabelVM`/`PaginationBarVM`,
  `request_create_new_resouce()` typo API. *(resolves FIXES #18, #20)*
