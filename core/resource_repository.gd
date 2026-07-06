@tool
class_name DH_VRE_ResourceRepository
extends RefCounted

signal resources_reseted(resources: Array[Resource])

signal resources_changed(
	added: Array[Resource],
	removed: Array[Resource],
	modified: Array[Resource]
)

signal error_occurred(message: String)

signal resources_saved(paths: Array[String])

signal selected_class_changed(class_name_: String)
signal include_subclasses_changed(include: bool)
signal confirmation_needed(paths: Array[String])

const MAX_ERROR_PATHS: int = 3

var class_registry: DH_VRE_ResourceClassMap

var selected_class: String = "":
	set(value):
		if selected_class != value:
			selected_class = value
			selected_class_changed.emit(value)
			_reload()

var include_subclasses: bool = true:
	set(value):
		if include_subclasses != value:
			include_subclasses = value
			include_subclasses_changed.emit(value)
			_reload()

var current_class_resources: Array[Resource] = []
var _current_class_props: Array[DH_VRE_ResourceProperty] = []


func _init(p_class_registry: DH_VRE_ResourceClassMap = null) -> void:
	class_registry = p_class_registry if p_class_registry else DH_VRE_ResourceClassMap.new()


func start() -> void:
	class_registry.rebuild()
	var monitor: DH_FileSystemMonitorPlugin = DH_FileSystemMonitorPlugin.instance
	if monitor == null:
		push_error("VRE: FileSystemMonitor plugin is not enabled — live refresh disabled.")
		return
	if not monitor.changes_detected.is_connected(_on_files_changed):
		monitor.changes_detected.connect(_on_files_changed)
	if not monitor.script_classes_updated.is_connected(_on_script_classes_updated):
		monitor.script_classes_updated.connect(_on_script_classes_updated)


func stop() -> void:
	var monitor: DH_FileSystemMonitorPlugin = DH_FileSystemMonitorPlugin.instance
	if monitor == null:
		return
	if monitor.changes_detected.is_connected(_on_files_changed):
		monitor.changes_detected.disconnect(_on_files_changed)
	if monitor.script_classes_updated.is_connected(_on_script_classes_updated):
		monitor.script_classes_updated.disconnect(_on_script_classes_updated)


func reload() -> void:
	_reload()


## Full reload for the given class names. Always emits resources_reseted.
func load_resources(class_names: Array[String]) -> void:
	current_class_resources = DH_VRE_ProjectClassScanner.load_classed_resources_from_dir(class_names)
	resources_reseted.emit(current_class_resources.duplicate())


## Incremental update from a monitor ChangeSet: filters the already-computed
## changes to watched .tres and applies them — no rescan, no mtime cache.
## Emits resources_changed only if something watched changed; silent otherwise.
func _on_files_changed(changes: DH_FSM_ChangeSet) -> void:
	if selected_class.is_empty():
		return
	var watched_classes: Array[String] = class_registry.get_descendant_classes(selected_class, include_subclasses)
	var added: Array[Resource] = []
	var removed: Array[Resource] = []
	var modified: Array[Resource] = []

	for file_path: String in changes.created_file_paths:
		_collect_created(file_path, watched_classes, added)
	for file_path: String in changes.modified_file_paths:
		_collect_modified(file_path, watched_classes, added, removed, modified)
	for file_path: String in changes.deleted_file_paths:
		_collect_deleted(file_path, removed)
	for move: DH_FSM_Move in changes.moved_files:
		_collect_moved(move, watched_classes, added, removed)

	if added.is_empty() and removed.is_empty() and modified.is_empty():
		return

	_apply_to_current(added, removed, modified)
	resources_changed.emit(added, removed, modified)


func _collect_created(file_path: String, watched_classes: Array[String], added: Array[Resource]) -> void:
	if not _is_watched_tres(file_path, watched_classes):
		return
	var res: Resource = _load_fresh(file_path)
	if res:
		added.append(res)


## A modified file can also enter or leave the watched set when its script_class
## changed on disk: unwatched-now but tracked -> removal; watched-now but
## untracked -> addition; otherwise a plain refresh.
func _collect_modified(
		file_path: String,
		watched_classes: Array[String],
		added: Array[Resource],
		removed: Array[Resource],
		modified: Array[Resource]
		) -> void:
	var tracked: Resource = _find_loaded(file_path)
	if not _is_watched_tres(file_path, watched_classes):
		if tracked:
			removed.append(tracked)
		return
	var res: Resource = _load_fresh(file_path)
	if res == null:
		return
	if tracked == null:
		added.append(res)
	else:
		modified.append(res)


func _collect_deleted(file_path: String, removed: Array[Resource]) -> void:
	var tracked: Resource = _find_loaded(file_path)
	if tracked:
		removed.append(tracked)


## A move out of the watched set = removal; into it = addition; within = both
## (old instance out, fresh instance at the new path in). The to_path fallback
## covers dock moves where the editor already updated the cached resource_path.
func _collect_moved(move: DH_FSM_Move, watched_classes: Array[String], added: Array[Resource], removed: Array[Resource]) -> void:
	var tracked: Resource = _find_loaded(move.from_path)
	if tracked == null:
		tracked = _find_loaded(move.to_path)
	if tracked:
		removed.append(tracked)
	if _is_watched_tres(move.to_path, watched_classes):
		var res: Resource = _load_fresh(move.to_path)
		if res:
			added.append(res)


func _is_watched_tres(file_path: String, watched_classes: Array[String]) -> bool:
	if file_path.begins_with("res://addons/") or not file_path.ends_with(".tres"):
		return false
	return watched_classes.has(DH_VRE_ProjectClassScanner.get_class_from_tres_file(file_path))


func _load_fresh(file_path: String) -> Resource:
	return ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_REPLACE)


func _find_loaded(file_path: String) -> Resource:
	for res: Resource in current_class_resources:
		if res.resource_path == file_path:
			return res
	return null


func _apply_to_current(added: Array[Resource], removed: Array[Resource], modified: Array[Resource]) -> void:
	for res: Resource in removed:
		current_class_resources.erase(res)
	for res: Resource in modified:
		for i: int in current_class_resources.size():
			if current_class_resources[i].resource_path == res.resource_path:
				current_class_resources[i] = res
				break
	for res: Resource in added:
		if not current_class_resources.has(res):
			current_class_resources.append(res)


## Resaves all current resources (used on property schema change).
func resave_all() -> void:
	for res: Resource in current_class_resources:
		ResourceSaver.save(res, res.resource_path)


## Resaves a specific subset (used for orphaned class cleanup).
func resave_resources(resources: Array[Resource]) -> void:
	for res: Resource in resources:
		ResourceSaver.save(res, res.resource_path)


## Looks up a loaded resource by path. Falls back to ResourceLoader.load
## if the path isn't in current_class_resources.
func get_by_path(path: String) -> Resource:
	var tracked: Resource = _find_loaded(path)
	return tracked if tracked else ResourceLoader.load(path)


## Instantiates a resource from `script` and saves it at `path`.
## Emits error_occurred on failure.
func create(script: GDScript, path: String) -> Error:
	if script == null:
		error_occurred.emit("Script is null; cannot create resource.")
		return ERR_INVALID_PARAMETER
	# can_instantiate() is false in-editor for every non-@tool script, so try
	# to instantiate and null-check instead (covers invalid scripts and
	# constructors with required arguments).
	var instance: Resource = script.new() as Resource
	if instance == null:
		error_occurred.emit("Can't instantiate %s.\nCheck its constructor." % script.get_global_name())
		return ERR_CANT_CREATE
	var err: Error = ResourceSaver.save(instance, path)
	if err != OK:
		error_occurred.emit("Failed to save resource:\n%s" % path)
	return err


## Emits confirmation_needed so the confirm dialog can gate the deletion.
func request_delete(paths: Array[String]) -> void:
	if paths.is_empty():
		return
	confirmation_needed.emit(paths)


## Moves the given resource paths to trash and refreshes EditorFileSystem.
## Emits error_occurred for paths that failed; silent on success.
func delete(paths: Array[String]) -> void:
	var failed_paths: Array[String] = []
	for path: String in paths:
		if not path.begins_with("res://"):
			push_warning("VRE: Skipping delete of path outside project: %s" % path)
			failed_paths.append(path)
			continue
		var err: Error = OS.move_to_trash(ProjectSettings.globalize_path(path))
		if err != OK:
			failed_paths.append(path)
	var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	for path: String in paths:
		efs.update_file(path)
	if not failed_paths.is_empty():
		error_occurred.emit("Failed to delete:\n%s" % "\n".join(failed_paths))


## Saves a single resource to disk. Emits resources_saved on success,
## error_occurred on failure.
func save_one(path: String, resource: Resource) -> Error:
	var err: Error = ResourceSaver.save(resource, path)
	if err != OK:
		error_occurred.emit("Failed to save resource:\n%s" % path)
		return err
	resources_saved.emit([path] as Array[String])
	return OK


## Batch-saves resources. `entries` is an Array of {path: String, resource: Resource}.
## Emits resources_saved with the successful paths; emits error_occurred with
## the first MAX_ERROR_PATHS failures on any failure.
func save_multi(entries: Array[Dictionary]) -> void:
	var saved_paths: Array[String] = []
	var failed_paths: Array[String] = []
	for entry: Dictionary in entries:
		var path: String = entry["path"]
		var resource: Resource = entry["resource"]
		var err: Error = ResourceSaver.save(resource, path)
		if err == OK:
			saved_paths.append(path)
		else:
			failed_paths.append(path)
	if not saved_paths.is_empty():
		resources_saved.emit(saved_paths)
	if not failed_paths.is_empty():
		var shown: Array[String] = failed_paths.slice(0, MAX_ERROR_PATHS)
		var msg: String = "Failed to save:\n%s" % "\n".join(shown)
		if failed_paths.size() > MAX_ERROR_PATHS:
			msg += "\n... and %d more" % (failed_paths.size() - MAX_ERROR_PATHS)
		error_occurred.emit(msg)


## Returns the resource_path of each currently loaded resource.
func get_paths() -> Array[String]:
	var paths: Array[String] = []
	for res: Resource in current_class_resources:
		paths.append(res.resource_path)
	return paths


func clear() -> void:
	current_class_resources.clear()


func _reload() -> void:
	if selected_class.is_empty():
		current_class_resources.clear()
		resources_reseted.emit(Array([], TYPE_OBJECT, "Resource", null))
		return
	_current_class_props = class_registry.get_properties_from_class_name(selected_class).duplicate()
	var included: Array[String] = class_registry.get_descendant_classes(selected_class, include_subclasses)
	load_resources(included)


func _on_script_classes_updated() -> void:
	var previous_names: Array[String] = class_registry.names.duplicate()
	class_registry.rebuild()
	var current_names: Array[String] = class_registry.names.duplicate()
	var old_path: String = class_registry.get_script_path_from_class_name(selected_class)

	var has_map_changed: bool = previous_names != current_names
	var is_current_class_missing: bool = has_map_changed and not current_names.has(selected_class)

	if has_map_changed:
		_resave_orphaned(previous_names, current_names)

	if is_current_class_missing:
		var new_name: String = class_registry.get_class_name_from_path(old_path)
		var is_current_class_renamed: bool = not new_name.is_empty()
		if is_current_class_renamed:
			_on_current_class_renamed(new_name)
		else:
			_on_current_class_deleted()
		return

	if selected_class.is_empty():
		return

	var new_props: Array[DH_VRE_ResourceProperty] = class_registry.get_properties_from_class_name(selected_class)
	var has_current_class_props_changed: bool = not DH_VRE_ResourceProperty.arrays_equal(new_props, _current_class_props)

	if has_current_class_props_changed:
		_on_current_class_props_changed(new_props)


func _on_current_class_renamed(new_name: String) -> void:
	resave_all()
	selected_class = new_name


func _on_current_class_deleted() -> void:
	selected_class = ""


func _on_current_class_props_changed(new_props: Array[DH_VRE_ResourceProperty]) -> void:
	resave_all()
	_current_class_props = new_props.duplicate()
	_reload_fresh()


func _reload_fresh() -> void:
	var included: Array[String] = class_registry.get_descendant_classes(selected_class, include_subclasses)
	current_class_resources = DH_VRE_ProjectClassScanner.load_classed_resources_from_dir(included)
	resources_reseted.emit(current_class_resources.duplicate())


func _resave_orphaned(previous: Array[String], current: Array[String]) -> void:
	var removed_classes: Array[String] = []
	for cls: String in previous:
		if not current.has(cls):
			removed_classes.append(cls)
	if removed_classes.is_empty():
		return
	var orphaned: Array[Resource] = DH_VRE_ProjectClassScanner.load_classed_resources_from_dir(removed_classes)
	resave_resources(orphaned)
