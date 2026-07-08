@tool
class_name DH_VRE_ColumnGrip
extends VSeparator

## Emitted when a resize drag starts (LMB pressed on the grip).
signal drag_started()
## Emitted while dragging: total horizontal delta in pixels since drag start.
signal drag_delta(delta: float)

var _dragging: bool = false
var _drag_start_mouse_x: float = 0.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_drag_start_mouse_x = get_global_mouse_position().x
			drag_started.emit()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		drag_delta.emit(get_global_mouse_position().x - _drag_start_mouse_x)
		accept_event()
