class_name StationCard
extends Button
## A draggable (and tappable / keyboard-activatable) quiz card with wrapping text.

signal selected(card_id: String)

const COL_SELECTED: Color = Color("#2f6fbf")

var card_id: String = ""
## Key used in the drag data: "card_id" (quiz part 1) or "organ_id" (quiz part 2).
var drag_key: String = "card_id"
var used: bool = false
var _label_text: String = ""
var _drag_started: bool = false


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	theme_type_variation = &"CardButton"
	button_down.connect(_on_button_down)
	pressed.connect(_on_pressed)


func setup(id: String, label_text: String) -> void:
	card_id = id
	_label_text = label_text
	text = label_text


func mark_used() -> void:
	used = true
	disabled = true
	set_selected(false)


func set_selected(on: bool) -> void:
	if on:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color("#dce8f7")
		sb.border_color = COL_SELECTED
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(8)
		for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
			add_theme_stylebox_override(st, sb)
	else:
		for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
			remove_theme_stylebox_override(st)


func shake() -> void:
	var base_x: float = position.x
	var tw: Tween = create_tween()
	tw.tween_property(self, "position:x", base_x + 9.0, 0.05)
	tw.tween_property(self, "position:x", base_x - 9.0, 0.08)
	tw.tween_property(self, "position:x", base_x + 6.0, 0.06)
	tw.tween_property(self, "position:x", base_x, 0.05)


func _on_button_down() -> void:
	_drag_started = false


func _on_pressed() -> void:
	if _drag_started or get_viewport().gui_is_dragging():
		return
	selected.emit(card_id)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled or used:
		return null
	_drag_started = true
	var root: Control = Control.new()
	var panel: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	box.border_color = Color("#e8641b")
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", box)
	var lbl: Label = Label.new()
	lbl.text = _label_text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(190, 0)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color("#2a2320"))
	panel.add_child(lbl)
	panel.position = Vector2(-90, -24)
	root.add_child(panel)
	set_drag_preview(root)
	return {drag_key: card_id}
