class_name MapDropArea
extends Control
## Transparent drop target covering the map (quiz part 1). Emits the dropped card id.

signal card_dropped(card_id: String)

const DATA_KEY: String = "card_id"

var _drag_active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		_drag_active = mouse_filter != Control.MOUSE_FILTER_IGNORE
		queue_redraw()
	elif what == NOTIFICATION_DRAG_END:
		_drag_active = false
		queue_redraw()


func _draw() -> void:
	if _drag_active:
		draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color(0.91, 0.39, 0.11, 0.7), false, 3.0)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has(DATA_KEY)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and (data as Dictionary).has(DATA_KEY):
		card_dropped.emit(str((data as Dictionary)[DATA_KEY]))
