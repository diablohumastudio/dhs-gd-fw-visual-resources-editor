# VRE Architecture — Fixes (open)

Open code-level findings, consolidated from Claude, Codex, and Gemini analyses.
**This file tracks open items only** — when an item is resolved, move it to
[CHANGELOG.md](CHANGELOG.md) keeping its number for traceability.

---

### 9. MVVM Violation: Domain Logic Leaks Into Views

**Problem:** `ResourceRow._build_field_labels()` (the View) calls
`get_script().get_script_property_list()`, filters `PROPERTY_USAGE_EDITOR`,
and excludes `resource_*` / `metadata/*` / `script` properties — duplicating
the filtering in `ResourceClassMap.get_properties_from_script_path()`.

**Fix:** Move property-ownership computation into `ResourceRowVM`; the VM
provides ready-to-render cell data, the View blindly renders it.

**References:**
- `view/resource_list/resource_row.gd:22-49`
- `model/resource_class_map.gd:93-117`

---

### 11. "Caveman" Filesystem Scanning

**Problem:** `get_class_from_tres_file` opens every `.tres` file to read the
first line for `script_class` — O(N) disk I/O per full scan (class switch).

**Fix:** Use `EditorFileSystemDirectory.get_file_script_class_name(idx)` for
instant lookups.

**References:**
- `model/project_class_scanner.gd:35-45`

---

### 12. Type-Unsafe Property Merging

**Problem:** `get_shared_properties()` merges properties by name only. If
`ClassA.power: int` and `ClassB.power: String`, the first type found wins and
bulk-editing can write the wrong type.

**Fix:** Detect type mismatches during the union: mark conflicting properties
"mixed type" and disable editing, or include only name+type exact matches.

**References:**
- `model/resource_class_map.gd:79-90`

---

### 16. BulkEditor Multi-Select Proxy May Corrupt Data

**Problem:** With mixed scripts selected, `_get_common_script()` falls back to
the selected class's base script and the proxy is created with default values
(values are only copied for single selection). Untouched proxy properties hold
defaults that can be written to all resources.

**Fix:** Only expose properties shared across all selected scripts, or disable
editing with a warning when scripts differ.

**References:**
- `model/bulk_editor.gd:61-78` (proxy creation)
- `model/bulk_editor.gd:92-97` (common-script fallback)

---

### 17. UI Node Thrashing (No Object Pooling)

**Problem:** `ResourceList` / `ResourceRow` rebuild all rows and cells with
`queue_free()` + `instantiate()` on every page change or class switch.

**Fix:** Pool `ResourceRow` and `ResourceFieldLabel` nodes; hide and update
instead of destroying.

**References:**
- `view/resource_list/resource_list.gd:49-52,79-85`
- `view/resource_list/resource_row.gd:22-49`

---

### 19. `search_filter` Is Dead Infrastructure

**Problem:** `ResourceListVM.search_filter` is declared but nothing sets or
reads it. Ghost feature.

**Fix:** Remove until search is actually implemented.

**References:**
- `viewmodel/resource_list_vm.gd:20`

---

### 21. Duplicate Null Check in ProjectClassScanner

**Problem:** `scan_folder_for_classed_tres_paths` checks
`dir == null or not is_instance_valid(dir)` twice.

**Fix:** Remove the redundant second check.

**References:**
- `model/project_class_scanner.gd:10-16`

---

### 22. Unnecessary Lambdas in Signal Forwarding

**Problem:** Several VMs wrap forwarding connections in lambdas, e.g.
`connect(func(msg: String): error_occurred.emit(msg))`. Per CLAUDE.md,
`connect(error_occurred.emit)` suffices when no arguments are transformed.

**References:**
- `viewmodel/error_dialog_vm.gd:9`
- `viewmodel/subclass_filter_vm.gd:12-13`
- `viewmodel/save_resource_dialog_vm.gd:13-15`

---

### 24. `Dialogs.gd` Is a Pointless Indirection

**Problem:** `Dialogs` exists solely to forward VM assignments from the Window
to its three child dialogs.

**Fix:** Move the three dialog nodes into `visual_resources_editor_window.tscn`
as unique-name children and assign VMs directly in the Window's `_ready()`.

**References:**
- `view/dialogs/dialogs.gd`
- `visual_resources_editor_window.gd:15-17`
