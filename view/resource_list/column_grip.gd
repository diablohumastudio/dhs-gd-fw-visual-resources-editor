@tool
class_name DH_VRE_ColumnGrip
extends VSeparator

## Emitted when a resize drag starts (LMB pressed on the grip).
signal drag_started()
## Emitted while dragging: total horizontal delta in pixels since drag start.
signal drag_delta(delta: float)
## Emitted when the drag is released.
signal drag_ended()

var _dragging: bool = false
var _drag_start_mouse_x: float = 0.0


## The visible separator is 1 px; %GrabArea is an invisible overlay extending
## 5 px left over the column it resizes, so the grip stays easy to grab.
func _on_grab_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_drag_start_mouse_x = get_global_mouse_position().x
			drag_started.emit()
		else:
			drag_ended.emit()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		drag_delta.emit(get_global_mouse_position().x - _drag_start_mouse_x)
		accept_event()
