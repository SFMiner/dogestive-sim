class_name BoxTarget
extends Button
## A label box on the map, one per organ. Shows "?", the name, or name + function.
## In the quiz it can also be a drop target and pressable (tap a card, then tap a box).

signal answer_dropped(target_id: String, card_id: String)
signal box_pressed(target_id: String)

enum State { HIDDEN, NAME, NAME_AND_FUNCTION }
enum Role { NONE, CURRENT, HELPER, CORRECT, SELECTED }

const COL_TEXT: Color = Color("#2a2320")
const COL_QUESTION: Color = Color("#7b2d9e")
const COL_CURRENT: Color = Color("#e8641b")
const COL_HELPER: Color = Color("#3d8b37")
const COL_CORRECT: Color = Color("#2f9e44")
const COL_SELECTED: Color = Color("#2f6fbf")

var target_id: String = ""
var organ_name: String = ""
var function_text: String = ""
var state: State = State.NAME
var role: Role = Role.NONE
## Set once the right job card has been matched; the box then ignores input.
var locked: bool = false

var _name_label: Label
var _func_label: Label
var _hover_drag: bool = false


func _init() -> void:
	flat = true
	clip_contents = true
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		add_theme_stylebox_override(st, empty)
	var focus: StyleBoxFlat = StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color("#2a2320")
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(4)
	add_theme_stylebox_override("focus", focus)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)
	_name_label = _make_label()
	vb.add_child(_name_label)
	_func_label = _make_label()
	vb.add_child(_func_label)
	set_interactive(false)


func _make_label() -> Label:
	var lbl: Label = Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_color", COL_TEXT)
	lbl.add_theme_constant_override("line_spacing", -2)
	return lbl


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(id: String, display_name: String, function_str: String, rect: Rect2) -> void:
	target_id = id
	organ_name = display_name
	function_text = function_str
	position = rect.position
	size = rect.size
	custom_minimum_size = rect.size
	set_state(State.NAME)


func set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.HIDDEN:
			_name_label.text = "?"
			_name_label.add_theme_font_size_override("font_size", 30)
			_name_label.add_theme_color_override("font_color", COL_QUESTION)
			_func_label.visible = false
		State.NAME:
			_name_label.text = organ_name
			_name_label.add_theme_font_size_override("font_size", 18)
			_name_label.add_theme_color_override("font_color", COL_TEXT)
			_func_label.visible = false
		State.NAME_AND_FUNCTION:
			_name_label.text = organ_name
			_name_label.add_theme_font_size_override("font_size", 15)
			_name_label.add_theme_color_override("font_color", COL_TEXT)
			_func_label.text = function_text
			_func_label.add_theme_font_size_override("font_size", 12)
			_func_label.visible = true
	queue_redraw()


func set_role(new_role: Role) -> void:
	role = new_role
	queue_redraw()


## Quiz drop target (true): receives mouse/touch/keyboard. Otherwise invisible to input.
func set_interactive(on: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		_hover_drag = mouse_filter != Control.MOUSE_FILTER_IGNORE and not locked
		queue_redraw()
	elif what == NOTIFICATION_DRAG_END:
		_hover_drag = false
		queue_redraw()


func _draw() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	if _hover_drag and role == Role.NONE:
		draw_rect(r.grow(-1.5), Color(COL_SELECTED.r, COL_SELECTED.g, COL_SELECTED.b, 0.6), false, 2.0)
	match role:
		Role.CURRENT:
			draw_rect(r.grow(-2.0), COL_CURRENT, false, 4.0)
		Role.HELPER:
			_draw_dashed_rect(r.grow(-1.5), COL_HELPER)
		Role.CORRECT:
			draw_rect(r.grow(-1.5), COL_CORRECT, false, 3.0)
		Role.SELECTED:
			draw_rect(r.grow(-1.5), COL_SELECTED, false, 3.0)
		_:
			pass


func _draw_dashed_rect(r: Rect2, col: Color) -> void:
	var tl: Vector2 = r.position
	var top_right: Vector2 = Vector2(r.end.x, r.position.y)
	var br: Vector2 = r.end
	var bl: Vector2 = Vector2(r.position.x, r.end.y)
	draw_dashed_line(tl, top_right, col, 3.0, 8.0)
	draw_dashed_line(top_right, br, col, 3.0, 8.0)
	draw_dashed_line(br, bl, col, 3.0, 8.0)
	draw_dashed_line(bl, tl, col, 3.0, 8.0)


func _on_pressed() -> void:
	if locked or get_viewport().gui_is_dragging():
		return
	box_pressed.emit(target_id)


## Accepts quiz part 2 job cards ("organ_id") and quiz part 1 cards ("card_id").
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return mouse_filter != Control.MOUSE_FILTER_IGNORE and not locked and _card_from(data) != ""


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var card_id: String = _card_from(data)
	if card_id != "":
		answer_dropped.emit(target_id, card_id)


func _card_from(data: Variant) -> String:
	if not data is Dictionary:
		return ""
	var d: Dictionary = data
	for key: String in ["organ_id", "card_id"]:
		if d.has(key):
			return str(d[key])
	return ""
