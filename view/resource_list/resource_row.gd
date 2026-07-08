@tool
class_name DH_VRE_ResourceRow
extends Button

const RESOURCE_FIELD_LABEL_SCENE: PackedScene = preload("uid://bgtsclwqqu255")
const FIELD_SEPARATOR_SCENE: PackedScene = preload("uid://bu4cm5ri3fy8l")

## Turquoise row tints; same hue, contrast comes from the alpha spread
## (a darker color over a dark editor theme reads as nearly no difference).
## Translucent so selection/hover styleboxes stay visible underneath.
const COLUMN_TINT_EVEN: Color = Color(0.2, 0.8, 0.75, 0.3)
const COLUMN_TINT_ODD: Color = Color(0.2, 0.8, 0.75, 0.12)

var vm: DH_VRE_ResourceRowVM = null
var current_shared_property_list: Array[DH_VRE_ResourceProperty] = []
var _prop_labels: Dictionary = {}
var _field_labels: Array[DH_VRE_ResourceFieldLabel] = []
var _column_widths: Dictionary = {}


func _ready() -> void:
	_tint_file_name_label()
	if not vm: return
	vm.is_selected_changed.connect(set_selected)
	%FileNameLabel.text = vm.resource.resource_path.get_file()
	%FileNameLabel.tooltip_text = vm.resource.resource_path
	_build_field_labels()
	set_selected(vm.is_selected())


func _build_field_labels() -> void:
	for child: Node in %FieldsContainer.get_children():
		child.visible = false   # queue_free is deferred; hide so HBox min-size ignores it now
		child.queue_free()
	_prop_labels.clear()
	_field_labels.clear()

	var owned: Dictionary = {}
	if vm.resource and vm.resource.get_script():
		for p: Dictionary in vm.resource.get_script().get_script_property_list():
			if not (p.usage & PROPERTY_USAGE_EDITOR):
				continue
			var pname: String = p.name
			if pname.begins_with("resource_") or pname.begins_with("metadata/"):
				continue
			if pname in ["script", "resource_local_to_scene"]:
				continue
			owned[pname] = true

	for i: int in current_shared_property_list.size():
		if i > 0:
			var sep: VSeparator = FIELD_SEPARATOR_SCENE.instantiate()
			%FieldsContainer.add_child(sep)

		var label: DH_VRE_ResourceFieldLabel = RESOURCE_FIELD_LABEL_SCENE.instantiate()
		label.column_tint = COLUMN_TINT_EVEN if (i + 1) % 2 == 0 else COLUMN_TINT_ODD   # +1: File is column 0
		var col_name: String = current_shared_property_list[i].name
		if owned.has(col_name):
			_prop_labels[col_name] = label
			label.set_value(vm.resource, current_shared_property_list[i])
		%FieldsContainer.add_child(label)
		_field_labels.append(label)

	_apply_column_widths()


func rebuild_fields() -> void:
	_build_field_labels()


func _tint_file_name_label() -> void:
	var style: StyleBoxFlat = %FileNameLabel.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	if style == null:
		return
	style.bg_color = COLUMN_TINT_EVEN
	%FileNameLabel.add_theme_stylebox_override("normal", style)


func apply_column_widths(widths: Dictionary) -> void:
	_column_widths = widths
	if is_node_ready():
		_apply_column_widths()


func _apply_column_widths() -> void:
	if _column_widths.is_empty():
		return
	%FileNameLabel.custom_minimum_size.x = _column_widths.get(
		DH_VRE_ResourceListVM.FILE_COLUMN, DH_VRE_ResourceListVM.DEFAULT_FILE_COLUMN_WIDTH)
	for i: int in _field_labels.size():
		_field_labels[i].custom_minimum_size.x = _column_widths.get(
			current_shared_property_list[i].name, DH_VRE_ResourceListVM.DEFAULT_COLUMN_WIDTH)
	_update_row_min_width()


## The row is a Button, not a container: it does not inherit its anchored
## Content's minimum size, so horizontal scrolling needs it set explicitly.
func _update_row_min_width() -> void:
	custom_minimum_size.x = %Content.get_combined_minimum_size().x


func update_display() -> void:
	if not vm: return
	for col: DH_VRE_ResourceProperty in current_shared_property_list:
		if _prop_labels.has(col.name):
			_prop_labels[col.name].set_value(vm.resource, col)


func set_selected(selected: bool) -> void:
	button_pressed = selected


func get_resource_path() -> String:
	return vm.resource.resource_path


func _on_pressed() -> void:
	var ctrl_held: bool = Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)
	var shift_held: bool = Input.is_key_pressed(KEY_SHIFT)
	vm.select(ctrl_held, shift_held)


func _on_delete_pressed() -> void:
	vm.request_delete()
