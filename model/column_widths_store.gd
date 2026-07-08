@tool
class_name DH_VRE_ColumnWidthsStore
extends RefCounted

## Persists per-class column widths in the editor's project metadata
## (.godot/editor/project_metadata.cfg — per user, never committed).

const _SECTION: String = "visual_resources_editor"
const _KEY: String = "column_widths_by_class"


func load_widths(class_name_str: String) -> Dictionary[String, float]:
	var widths: Dictionary[String, float] = {}
	if class_name_str.is_empty():
		return widths
	var widths_by_class: Dictionary = EditorInterface.get_editor_settings() \
		.get_project_metadata(_SECTION, _KEY, {})
	var stored: Dictionary = widths_by_class.get(class_name_str, {})
	for column: String in stored:
		widths[column] = float(stored[column])
	return widths


func save_widths(class_name_str: String, widths: Dictionary[String, float]) -> void:
	if class_name_str.is_empty():
		return
	var editor_settings: EditorSettings = EditorInterface.get_editor_settings()
	var widths_by_class: Dictionary = editor_settings.get_project_metadata(_SECTION, _KEY, {})
	widths_by_class[class_name_str] = widths.duplicate()
	editor_settings.set_project_metadata(_SECTION, _KEY, widths_by_class)
