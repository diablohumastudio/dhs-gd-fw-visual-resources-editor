@tool
extends HBoxContainer

const HEADER_FIELD_LABEL_SCENE: PackedScene = preload("uid://3xl34fn7aksm")
const COLUMN_GRIP_SCENE: PackedScene = preload("uid://dmrrxxh827aso")

const ARROW_UP: String = " ↑"
const ARROW_DOWN: String = " ↓"

var _vm: DH_VRE_ResourceListVM = null
var _field_buttons: Array[Button] = []
var _column_names: Array[String] = []
var _drag_start_width: float = 0.0

var current_shared_property_list: Array[DH_VRE_ResourceProperty] = []:
	set(value):
		current_shared_property_list = value
		if is_inside_tree():
			_rebuild_labels()


func set_view_model(vm: DH_VRE_ResourceListVM) -> void:
	_vm = vm
	%FileLabel.pressed.connect(func() -> void: _vm.request_sort(DH_VRE_ResourceListVM.FILE_COLUMN))
	_vm.sort_state_changed.connect(_on_sort_state_changed)
	_vm.column_widths_changed.connect(_on_column_widths_changed)
	_connect_grip(%FileGrip, func() -> String: return DH_VRE_ResourceListVM.FILE_COLUMN)
	_connect_grip(%DelGrip, _last_column_name)
	_update_sort_indicators(_vm.sort_column, _vm.sort_ascending)


func _rebuild_labels() -> void:
	_field_buttons.clear()
	_column_names.clear()

	for child: Node in %FieldsContainer.get_children():
		child.visible = false   # queue_free is deferred; hide so HBox min-size ignores it now
		child.queue_free()

	for i: int in current_shared_property_list.size():
		var col_name: String = current_shared_property_list[i].name
		if i > 0:
			_add_grip(current_shared_property_list[i - 1].name)
		var btn: Button = HEADER_FIELD_LABEL_SCENE.instantiate()
		btn.text = col_name
		%FieldsContainer.add_child(btn)
		_field_buttons.append(btn)
		_column_names.append(col_name)
		if _vm:
			btn.pressed.connect(_vm.request_sort.bind(col_name))

	if _vm:
		_update_sort_indicators(_vm.sort_column, _vm.sort_ascending)
		_apply_column_widths()


## Adds a grip between field columns; dragging it resizes the column at its left.
func _add_grip(column: String) -> void:
	var grip: DH_VRE_ColumnGrip = COLUMN_GRIP_SCENE.instantiate()
	%FieldsContainer.add_child(grip)
	if _vm:
		_connect_grip(grip, func() -> String: return column)


## column_getter is resolved at drag time so %DelGrip always targets the
## current last column even after the column set is rebuilt.
func _connect_grip(grip: DH_VRE_ColumnGrip, column_getter: Callable) -> void:
	grip.drag_started.connect(func() -> void:
		_drag_start_width = _vm.get_column_width(column_getter.call()))
	grip.drag_delta.connect(func(delta: float) -> void:
		_vm.set_column_width(column_getter.call(), _drag_start_width + delta))


func _last_column_name() -> String:
	if _column_names.is_empty():
		return DH_VRE_ResourceListVM.FILE_COLUMN
	return _column_names[_column_names.size() - 1]


func _on_column_widths_changed(_widths: Dictionary) -> void:
	_apply_column_widths()


func _apply_column_widths() -> void:
	if _vm == null or _vm.column_widths.is_empty():
		return
	%FileLabel.custom_minimum_size.x = _vm.get_column_width(DH_VRE_ResourceListVM.FILE_COLUMN)
	for i: int in _field_buttons.size():
		var btn: Button = _field_buttons[i]
		if is_instance_valid(btn):
			btn.custom_minimum_size.x = _vm.get_column_width(_column_names[i])


func _on_sort_state_changed(column: String, ascending: bool) -> void:
	_update_sort_indicators(column, ascending)


func _update_sort_indicators(column: String, ascending: bool) -> void:
	var arrow: String = ARROW_UP if ascending else ARROW_DOWN

	# File button
	if column.is_empty():
		%FileLabel.text = "File" + arrow
	else:
		%FileLabel.text = "File"

	# Property buttons
	for i: int in _field_buttons.size():
		var btn: Button = _field_buttons[i]
		if not is_instance_valid(btn):
			continue
		if _column_names[i] == column:
			btn.text = _column_names[i] + arrow
		else:
			btn.text = _column_names[i]
