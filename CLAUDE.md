# CLAUDE.md — Visual Resources Editor (DH_VRE)

Godot 4 `@tool` editor plugin (GDScript). MVVM layout: `model/`, `viewmodel/`,
`view/`; `visual_resources_editor_window.gd/.tscn` at the root is the
composition root. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

- **Peer dependency**: the FileSystemMonitor addon
  (`DH_FileSystemMonitorPlugin`) must be installed at
  `addons/diablohumastudio_framework/file_system_monitor` — this plugin does
  not compile without it.
- Consumed as a git submodule by DiabloHumaStudio game projects.
- All class names are prefixed `DH_VRE_`.

## Code Conventions

- **Files**: snake_case (e.g. `resource_repository.gd`)
- **Classes**: PascalCase with prefix (e.g. `DH_VRE_ResourceRepository`)
- **Indentation**: ALWAYS tabs, never spaces (Godot auto-formats with tabs)
- **Scenes**: visual things are defined in `.tscn`, not built in code.
  Script-only nodes (no children, no editor-configured properties) use a bare
  `.gd` extending the base type, assigned in the parent `.tscn`.
- **Node references**: `%UniqueNode` directly in code (node must have
  `unique_name_in_owner = true`). `%Name` / `$Child` work ONLY on `self` —
  for other objects use `other.get_node("%Name")`.
- **Resource loading**: use UIDs (`uid://...`) in `load()`/`preload()` for
  hardcoded paths; string paths only for dynamic runtime paths.
- **Types**: explicit types everywhere; never `:=`. Type `for` loop variables
  (`for res: Resource in ...`); never `range()` (`for i: int in count:`).
  Empty typed arrays via the 4-arg constructor
  (`Array([], TYPE_OBJECT, "RefCounted", DH_VRE_ResourceProperty)`), never a
  bare `[]` where a typed array is expected.
- **Signals**: connect via the scene when source and target are in the same
  scene; via code for dynamic nodes or cross-scene callables. No lambdas for
  plain forwarding — `signal.connect(other_signal.emit)`.

## Development Practices

- Prefer editing existing files over creating new ones; never create docs
  unless asked.
- Verify enum values and API signatures by reading source files — never
  assume.
- Do NOT run Godot headless to generate `.uid` files or the class cache — ask
  the user to open Godot instead.
- Never commit unless explicitly asked.

## Docs Workflow

- [docs/FIXES.md](docs/FIXES.md) (code-level findings) and
  [docs/TODOS.md](docs/TODOS.md) (architectural issues) track **open items
  only**.
- When an item is fixed or becomes obsolete: remove it from FIXES.md/TODOS.md
  and record it in [docs/CHANGELOG.md](docs/CHANGELOG.md) under the release
  that resolved it, keeping its original number (e.g. *resolves FIXES #12*).
- Item numbers are never reused.
