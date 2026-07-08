@tool
class_name DH_VRE_ResourceFieldLabel
extends Label

## Alternating column background; reapplied whenever the cell shows a
## non-color value (color values take over the background instead).
var column_tint: Color = Color.TRANSPARENT:
	set(value):
		column_tint = value
		_set_bg_color(column_tint)


func set_value(resource: Resource, col: DH_VRE_ResourceProperty) -> void:
	var value: Variant = resource.get(col.name)
	text = _format_value(value, col.type)
	tooltip_text = "%s: %s" % [col.name, text]

	if col.type == TYPE_COLOR and value is Color:
		_set_bg_color(value)
		add_theme_color_override("font_color",
			Color.BLACK if value.get_luminance() > 0.5 else Color.WHITE)
	else:
		_set_bg_color(column_tint)
		remove_theme_color_override("font_color")


func _set_bg_color(bg_color: Color) -> void:
	var style: StyleBoxFlat = get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	if style == null:
		return
	style.bg_color = bg_color
	add_theme_stylebox_override("normal", style)


func _format_value(value: Variant, type: int) -> String:
	if value == null:
		return "<null>"
	match type:
		TYPE_BOOL:
			return "true" if value else "false"
		TYPE_OBJECT:
			if value is Resource and not value.resource_path.is_empty():
				return value.resource_path.get_file()
			return str(value)
		TYPE_VECTOR2:
			return "(%g, %g)" % [value.x, value.y]
		TYPE_VECTOR3:
			return "(%g, %g, %g)" % [value.x, value.y, value.z]
		TYPE_COLOR:
			return value.to_html()
	return str(value)
