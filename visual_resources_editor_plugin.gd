@tool
extends EditorPlugin

const TOOLBAR_MENU_NAME: String = "VisualResourcesEditor"
const _CORE_PATH: String = "res://addons/diablohumastudio_framework/core/main_toolbar_plugin/main_toolbar_plugin.gd"
# Peer dependency: live refresh (resource_repository.gd) references this class,
# so VRE only compiles in a project that also has the FileSystemMonitor addon.
const _MONITOR_CLASS_NAME: StringName = &"DH_FileSystemMonitorPlugin"
const _MONITOR_REPO_URL: String = "https://github.com/diablohumastudio/dhs-gd-fw-file-system-monitor"

func _enter_tree() -> void:
	if not _is_file_system_monitor_installed():
		push_error("VRE: requires the FileSystemMonitor addon — install %s at addons/diablohumastudio_framework/file_system_monitor and enable it." % _MONITOR_REPO_URL)
		return
	add_toolbar_menu()

func _is_file_system_monitor_installed() -> bool:
	for global_class: Dictionary in ProjectSettings.get_global_class_list():
		if global_class["class"] == _MONITOR_CLASS_NAME:
			return true
	return false

func add_toolbar_menu():
	var tool_bar_menu: DH_VisualResourcesEditorToolbar = DH_VisualResourcesEditorToolbar.new()
	if ResourceLoader.exists(_CORE_PATH):
		load(_CORE_PATH).add_toolbar_submenu(TOOLBAR_MENU_NAME, tool_bar_menu, self)
	else:
		add_tool_submenu_item(TOOLBAR_MENU_NAME, tool_bar_menu)

func _exit_tree() -> void:
	if ResourceLoader.exists(_CORE_PATH):
		load(_CORE_PATH).remove_toolbar_submenu(TOOLBAR_MENU_NAME, self)
	else:
		remove_tool_menu_item(TOOLBAR_MENU_NAME)
