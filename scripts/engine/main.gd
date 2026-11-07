extends Control
## App layer: builds all UI in code and owns modes, movement and input.
## Talks to the body system only through SimSystem / SimToken.

const SIDE_X: float = 680.0
const SIDE_W: float = 600.0
const QUIZ_SPEED: float = 170.0
const LOOP_PAUSE: float = 1.5
const START_TEXT: String = "Press Step or Play to send the carrot into the mouth."
const END_TEXT: String = "Press Reset to eat another carrot."

const COL_BG: Color = Color("#f7f3ee")
const COL_PANEL: Color = Color("#ffffff")
const COL_ACCENT: Color = Color("#e8641b")
const COL_TEXT: Color = Color("#2a2320")
const COL_MUTED: Color = Color("#6f6862")
const COL_GREEN: Color = Color("#3d8b37")
const COL_BLUE: Color = Color("#2f6fbf")
const COL_GREY: Color = Color("#8a8580")
const COL_RED: Color = Color("#c0392b")

var system: SimSystem
var token: SimToken
var speed: float = 140.0
var current_station: int = -1
var quiz_mode: bool = false
var quiz_part: int = 1
var quiz_complete: bool = false
var quiz2_complete: bool = false
var mistakes: int = 0
var mistakes2: int = 0
var steps_done: int = 0
var matched_count: int = 0
var loop_forever: bool = false

var _moving: bool = false
var _moving_segment: int = 0
var _t: float = 0.0
var _busy: float = 0.0
var _playing: bool = false
var _loop_timer: float = 0.0
var _syncing: bool = false
var _selected_card_id: String = ""
var _revealed: Dictionary = {}
## Organ ids labelled in quiz part 1 (helper organs dropped on their own boxes).
var _labelled: Dictionary = {}
## Station whose text and highlights are showing. Switches to the next station as soon as the
## token crosses into that organ (system.switch_t), before it reaches the station dot.
var _display_station: int = -1
var _crossed: bool = false
var _matched: Dictionary = {}

var _map: MapView
var _fullscreen_btn: Button
var _drop_area: MapDropArea
var _box_layer: Control
var _boxes: Dictionary = {}

var _explore_box: VBoxContainer
var _quiz_box: VBoxContainer
var _explore_btn: Button
var _quiz_btn: Button
var _step_btn: Button
var _play_btn: Button
var _reset_btn: Button
var _speed_slider: HSlider
var _speed_label: Label
var _loop_check: CheckBox
var _station_label: Label
var _chips_box: HFlowContainer
var _info_label: Label
var _breaking_label: Label
var _helpers_label: Label
var _end_label: Label
var _route_markers: Array[Label] = []
var _route_names: Array[Label] = []

var _prompt_label: Label
var _feedback_label: Label
var _stats_label: Label
var _card_grid: GridContainer
var _part2_btn: Button
var _again_btn: Button
var _cards: Array[StationCard] = []


func _create_system() -> SimSystem:
	return DigestiveSystem.new()


func _create_token() -> SimToken:
	return FoodToken.new()


func _ready() -> void:
	system = _create_system()
	_register_actions()
	theme = _build_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg: ColorRect = ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_map = MapView.new()
	_map.position = Vector2.ZERO
	add_child(_map)
	_map.setup(system)
	token = _create_token()
	_map.add_child(token)
	token.position = system.start_pos

	_drop_area = MapDropArea.new()
	_drop_area.position = Vector2.ZERO
	_drop_area.size = system.map_size
	_drop_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drop_area.card_dropped.connect(_on_map_dropped)
	add_child(_drop_area)

	_box_layer = Control.new()
	_box_layer.position = Vector2.ZERO
	_box_layer.size = system.map_size
	_box_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box_layer)
	for id: String in system.organ_order:
		var organ: Dictionary = system.organs[id]
		var bt: BoxTarget = BoxTarget.new()
		_box_layer.add_child(bt)
		bt.setup(id, organ["name"], organ["function"], organ["box"])
		bt.answer_dropped.connect(_on_box_dropped)
		bt.box_pressed.connect(_on_box_pressed)
		_boxes[id] = bt

	_build_side_panel()
	_set_mode(false)
	_step_btn.call_deferred("grab_focus")


# ---------------------------------------------------------------- input

func _register_actions() -> void:
	_add_key_action("sim_play", [KEY_SPACE])
	_add_key_action("sim_step", [KEY_RIGHT, KEY_N])
	_add_key_action("sim_reset", [KEY_R])
	_add_key_action("sim_mode", [KEY_M])
	_add_key_action("sim_fullscreen", [KEY_F11])


func _add_key_action(action: String, keys: Array[Key]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k: Key in keys:
		var ev: InputEventKey = InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.is_echo():
		return
	if event.is_action_pressed("sim_fullscreen"):
		toggle_fullscreen()
	elif event.is_action_pressed("sim_mode"):
		toggle_mode()
	elif event.is_action_pressed("sim_reset"):
		if quiz_mode:
			restart_quiz()
		else:
			reset_sim()
	elif event.is_action_pressed("sim_step"):
		if quiz_mode:
			return
		step()
	elif event.is_action_pressed("sim_play"):
		if quiz_mode:
			return
		toggle_play()
	else:
		return
	get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- theme

func _box(bg_color: Color, border: Color, border_w: int, radius: int, margin: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


func _make_check_icon(checked: bool) -> ImageTexture:
	var s: int = 26
	var img: Image = Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill: Color = COL_ACCENT if checked else Color.WHITE
	for y: int in range(2, s - 2):
		for x: int in range(2, s - 2):
			var edge: bool = x < 4 or y < 4 or x >= s - 4 or y >= s - 4
			img.set_pixel(x, y, COL_ACCENT if edge else fill)
	if checked:
		for i: int in range(5):
			for w: int in range(3):
				img.set_pixel(6 + i, 13 + i + w - 1, Color.WHITE)
		for i: int in range(9):
			for w: int in range(3):
				img.set_pixel(10 + i, 17 - i + w - 1, Color.WHITE)
	return ImageTexture.create_from_image(img)


func _build_theme() -> Theme:
	var th: Theme = Theme.new()
	th.default_font_size = 18
	for ctrl: String in ["Label", "Button", "CheckBox"]:
		th.set_color("font_color", ctrl, COL_TEXT)
	for ctrl: String in ["Button", "CheckBox"]:
		th.set_color("font_hover_color", ctrl, COL_TEXT)
		th.set_color("font_focus_color", ctrl, COL_TEXT)
		th.set_color("font_pressed_color", ctrl, COL_TEXT)
		th.set_color("font_hover_pressed_color", ctrl, COL_TEXT)
		th.set_color("font_disabled_color", ctrl, COL_MUTED)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	th.set_stylebox("normal", "Button", _box(Color("#f3ebe2"), Color("#dccfc1"), 2, 10, 10))
	th.set_stylebox("hover", "Button", _box(Color("#ecdfd1"), COL_ACCENT, 2, 10, 10))
	th.set_stylebox("pressed", "Button", _box(COL_ACCENT, COL_ACCENT, 2, 10, 10))
	th.set_stylebox("hover_pressed", "Button", _box(COL_ACCENT, COL_ACCENT, 2, 10, 10))
	th.set_stylebox("disabled", "Button", _box(Color("#ebe7e2"), Color("#ddd8d2"), 2, 10, 10))
	var focus: StyleBoxFlat = _box(Color(0, 0, 0, 0), COL_BLUE, 3, 10, 10)
	focus.draw_center = false
	th.set_stylebox("focus", "Button", focus)
	th.set_stylebox("focus", "CheckBox", focus)
	# Compact variation used by quiz cards (smaller margins so wrapped text fits).
	th.set_type_variation("CardButton", "Button")
	th.set_stylebox("normal", "CardButton", _box(Color("#f3ebe2"), Color("#dccfc1"), 2, 10, 7))
	th.set_stylebox("hover", "CardButton", _box(Color("#ecdfd1"), COL_ACCENT, 2, 10, 7))
	th.set_stylebox("pressed", "CardButton", _box(Color("#ecdfd1"), COL_ACCENT, 2, 10, 7))
	th.set_stylebox("hover_pressed", "CardButton", _box(Color("#ecdfd1"), COL_ACCENT, 2, 10, 7))
	th.set_stylebox("disabled", "CardButton", _box(Color("#e1efdd"), Color("#b5d4ae"), 2, 10, 7))
	th.set_color("font_pressed_color", "CardButton", COL_TEXT)
	th.set_color("font_hover_pressed_color", "CardButton", COL_TEXT)
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		th.set_stylebox(st, "CheckBox", empty)
	th.set_icon("checked", "CheckBox", _make_check_icon(true))
	th.set_icon("unchecked", "CheckBox", _make_check_icon(false))
	th.set_icon("checked_disabled", "CheckBox", _make_check_icon(true))
	th.set_icon("unchecked_disabled", "CheckBox", _make_check_icon(false))
	th.set_constant("h_separation", "CheckBox", 10)
	th.set_stylebox("panel", "PanelContainer", _box(COL_PANEL, Color("#e6dccf"), 2, 16, 14))
	var track: StyleBoxFlat = _box(Color("#e2d9cd"), Color(0, 0, 0, 0), 0, 4, 0)
	track.content_margin_top = 4.0
	track.content_margin_bottom = 4.0
	th.set_stylebox("slider", "HSlider", track)
	var area: StyleBoxFlat = _box(COL_ACCENT, Color(0, 0, 0, 0), 0, 4, 0)
	area.content_margin_top = 4.0
	area.content_margin_bottom = 4.0
	th.set_stylebox("grabber_area", "HSlider", area)
	th.set_stylebox("grabber_area_highlight", "HSlider", area)
	return th


# ---------------------------------------------------------------- layout

func _make_button(label_text: String) -> Button:
	var b: Button = Button.new()
	b.text = label_text
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(44, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func _make_label(label_text: String, font_size: int, color: Color = COL_TEXT) -> Label:
	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


## Part 1 feedback quotes a station's info text (up to 5 lines); part 2 feedback is short,
## which leaves room for its 12 long cards.
const FEEDBACK_LINES_PART1: int = 5
const FEEDBACK_LINES_PART2: int = 2


func _set_feedback_lines(lines: int) -> void:
	var font: Font = _feedback_label.get_theme_font("font")
	var font_size: int = _feedback_label.get_theme_font_size("font_size")
	var line_h: float = font.get_height(font_size) + float(_feedback_label.get_theme_constant("line_spacing"))
	_feedback_label.custom_minimum_size = Vector2(100, ceilf(line_h * float(lines)) + 2.0)
	_feedback_label.max_lines_visible = lines


func _make_wrap_label(font_size: int, color: Color = COL_TEXT) -> Label:
	var lbl: Label = _make_label("", font_size, color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(100, 0)
	return lbl


func _build_side_panel() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(SIDE_X + 8.0, 8.0)
	panel.size = Vector2(SIDE_W - 16.0, system.map_size.y - 16.0)
	panel.clip_contents = true
	add_child(panel)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	# Title row: title centred in the space left of the Full screen button.
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	root.add_child(title_row)
	var title: Label = _make_label(system.title, 28, COL_ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title_row.add_child(title)
	_fullscreen_btn = Button.new()
	_fullscreen_btn.add_theme_font_size_override("font_size", 15)
	_fullscreen_btn.custom_minimum_size = Vector2(118, 0)
	_fullscreen_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_fullscreen_btn.tooltip_text = "Full screen on/off (F11)"
	_fullscreen_btn.pressed.connect(toggle_fullscreen)
	title_row.add_child(_fullscreen_btn)
	# Also catches leaving full screen another way (Esc in a browser, window manager).
	get_viewport().size_changed.connect(_refresh_fullscreen_button)
	_refresh_fullscreen_button()

	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	var group: ButtonGroup = ButtonGroup.new()
	_explore_btn = _make_button("Explore")
	_quiz_btn = _make_button("Quiz")
	for b: Button in [_explore_btn, _quiz_btn]:
		b.toggle_mode = true
		b.button_group = group
		tabs.add_child(b)
	_explore_btn.set_pressed_no_signal(true)
	_explore_btn.toggled.connect(_on_explore_tab_toggled)
	_quiz_btn.toggled.connect(_on_quiz_tab_toggled)

	_explore_box = VBoxContainer.new()
	_explore_box.add_theme_constant_override("separation", 8)
	root.add_child(_explore_box)
	_build_explore()

	_quiz_box = VBoxContainer.new()
	_quiz_box.add_theme_constant_override("separation", 8)
	root.add_child(_quiz_box)
	_build_quiz()


func _build_explore() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_explore_box.add_child(row)
	_step_btn = _make_button("Step >")
	_play_btn = _make_button("Play")
	_reset_btn = _make_button("Reset")
	for b: Button in [_step_btn, _play_btn, _reset_btn]:
		row.add_child(b)
	_step_btn.pressed.connect(step)
	_play_btn.pressed.connect(toggle_play)
	_reset_btn.pressed.connect(reset_sim)

	var srow: HBoxContainer = HBoxContainer.new()
	srow.add_theme_constant_override("separation", 10)
	_explore_box.add_child(srow)
	_speed_label = _make_label("Speed: 140", 18)
	_speed_label.custom_minimum_size = Vector2(110, 44)
	_speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	srow.add_child(_speed_label)
	_speed_slider = HSlider.new()
	_speed_slider.min_value = 60.0
	_speed_slider.max_value = 320.0
	_speed_slider.step = 10.0
	_speed_slider.value = speed
	_speed_slider.custom_minimum_size = Vector2(150, 44)
	_speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speed_slider.focus_mode = Control.FOCUS_ALL
	_speed_slider.value_changed.connect(_on_speed_changed)
	srow.add_child(_speed_slider)
	_loop_check = CheckBox.new()
	_loop_check.text = "Loop forever"
	_loop_check.custom_minimum_size = Vector2(44, 44)
	_loop_check.focus_mode = Control.FOCUS_ALL
	_loop_check.toggled.connect(_on_loop_toggled)
	srow.add_child(_loop_check)

	var info_panel: PanelContainer = PanelContainer.new()
	_explore_box.add_child(info_panel)
	var ibox: VBoxContainer = VBoxContainer.new()
	ibox.add_theme_constant_override("separation", 6)
	info_panel.add_child(ibox)
	_station_label = _make_label("", 28, COL_ACCENT)
	ibox.add_child(_station_label)
	_chips_box = HFlowContainer.new()
	_chips_box.add_theme_constant_override("h_separation", 6)
	_chips_box.add_theme_constant_override("v_separation", 4)
	ibox.add_child(_chips_box)
	_info_label = _make_wrap_label(17)
	_info_label.custom_minimum_size = Vector2(100, 70)
	ibox.add_child(_info_label)
	_breaking_label = _make_wrap_label(16)
	ibox.add_child(_breaking_label)
	_helpers_label = _make_wrap_label(16)
	ibox.add_child(_helpers_label)
	_end_label = _make_wrap_label(17, COL_ACCENT)
	_end_label.text = END_TEXT
	ibox.add_child(_end_label)

	var route_title: Label = _make_label("Route", 16, COL_MUTED)
	_explore_box.add_child(route_title)
	var cols: HBoxContainer = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	_explore_box.add_child(cols)
	var per_col: int = ceili(float(system.station_count()) / 2.0)
	for c: int in range(2):
		var colbox: VBoxContainer = VBoxContainer.new()
		colbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		colbox.add_theme_constant_override("separation", 0)
		cols.add_child(colbox)
		for r: int in range(per_col):
			var idx: int = c * per_col + r
			if idx >= system.station_count():
				break
			var line: HBoxContainer = HBoxContainer.new()
			var marker: Label = _make_label("", 17, COL_ACCENT)
			marker.custom_minimum_size = Vector2(22, 0)
			var nm: Label = _make_label("%d. %s" % [idx + 1, system.station_name(idx)], 17)
			line.add_child(marker)
			line.add_child(nm)
			colbox.add_child(line)
			_route_markers.append(marker)
			_route_names.append(nm)


func _build_quiz() -> void:
	_prompt_label = _make_wrap_label(21, COL_ACCENT)
	# Fixed heights so the card grid below never jumps while a student is dragging.
	_prompt_label.custom_minimum_size = Vector2(100, 64)
	_prompt_label.max_lines_visible = 2
	_quiz_box.add_child(_prompt_label)
	_feedback_label = _make_wrap_label(16)
	_set_feedback_lines(FEEDBACK_LINES_PART1)
	_quiz_box.add_child(_feedback_label)
	_stats_label = _make_label("", 17, COL_MUTED)
	_quiz_box.add_child(_stats_label)
	_card_grid = GridContainer.new()
	_card_grid.columns = 2
	_card_grid.add_theme_constant_override("h_separation", 8)
	_card_grid.add_theme_constant_override("v_separation", 6)
	_quiz_box.add_child(_card_grid)
	_part2_btn = _make_button("Go to Part 2")
	_part2_btn.pressed.connect(start_part2)
	_part2_btn.visible = false
	_quiz_box.add_child(_part2_btn)
	_again_btn = _make_button("Start Over")
	_again_btn.pressed.connect(restart_quiz)
	_again_btn.visible = false
	_quiz_box.add_child(_again_btn)


# ---------------------------------------------------------------- modes

func toggle_mode() -> void:
	_set_mode(not quiz_mode)


func _on_explore_tab_toggled(on: bool) -> void:
	if on and not _syncing:
		_set_mode(false)


func _on_quiz_tab_toggled(on: bool) -> void:
	if on and not _syncing:
		_set_mode(true)


func _set_mode(want_quiz: bool) -> void:
	quiz_mode = want_quiz
	_syncing = true
	_explore_btn.set_pressed_no_signal(not want_quiz)
	_quiz_btn.set_pressed_no_signal(want_quiz)
	_syncing = false
	_explore_box.visible = not want_quiz
	_quiz_box.visible = want_quiz
	_drop_area.mouse_filter = Control.MOUSE_FILTER_STOP if want_quiz else Control.MOUSE_FILTER_IGNORE
	if want_quiz:
		restart_quiz()
	else:
		_clear_cards()
		_set_boxes_interactive(false)
		reset_sim()
		_step_btn.call_deferred("grab_focus")


func is_busy() -> bool:
	return _moving or _busy > 0.0


func _place_token_at_start() -> void:
	_moving = false
	_playing = false
	_busy = 0.0
	_t = 0.0
	_loop_timer = 0.0
	current_station = -1
	_display_station = -1
	_crossed = false
	token.reset_token()
	token.position = system.start_pos
	_map.set_highlight(-1)


# ---------------------------------------------------------------- explore

func reset_sim() -> void:
	if quiz_mode:
		return
	_place_token_at_start()
	_show_all_names()
	_update_info()
	_refresh_buttons()


func step() -> void:
	if quiz_mode or not _can_step():
		return
	_begin_move()


func toggle_play() -> void:
	if quiz_mode:
		return
	if _playing:
		_playing = false
	else:
		if system.next_station(current_station) == -1:
			if is_busy():
				return
			reset_sim()
		_playing = true
		_loop_timer = LOOP_PAUSE
	_refresh_buttons()


func _can_step() -> bool:
	return not (_moving or _busy > 0.0 or _playing) and system.next_station(current_station) != -1


func _on_speed_changed(value: float) -> void:
	speed = value
	_speed_label.text = "Speed: %d" % int(value)


func _on_loop_toggled(on: bool) -> void:
	loop_forever = on


func _refresh_buttons() -> void:
	_play_btn.text = "Pause" if _playing else "Play"
	_step_btn.disabled = not _can_step()


func _show_all_names() -> void:
	for id: String in system.organ_order:
		var bt: BoxTarget = _boxes[id]
		bt.set_state(BoxTarget.State.NAME)
		bt.locked = false
	_apply_roles()


## Outlines: boxes of the current station = current, its helpers = helper.
func _apply_roles() -> void:
	for id: String in system.organ_order:
		var bt: BoxTarget = _boxes[id]
		bt.set_role(BoxTarget.Role.NONE)
	if _display_station < 0:
		return
	var st: Dictionary = system.stations[_display_station]
	for hid: String in st["helpers"]:
		var hb: BoxTarget = _boxes[hid]
		hb.set_role(BoxTarget.Role.HELPER)
	for bid: String in st["boxes"]:
		var cb: BoxTarget = _boxes[bid]
		cb.set_role(BoxTarget.Role.CURRENT)


func _make_chip(text_str: String, color: Color) -> PanelContainer:
	var chip: PanelContainer = PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _box(color, color, 0, 12, 4))
	var lbl: Label = _make_label(text_str, 15, Color.WHITE)
	chip.add_child(lbl)
	return chip


func _update_info() -> void:
	for ch: Node in _chips_box.get_children():
		_chips_box.remove_child(ch)
		ch.queue_free()
	var last: int = system.station_count() - 1
	for i: int in range(system.station_count()):
		var here: bool = i == _display_station
		_route_markers[i].text = ">" if here else ""
		_route_names[i].add_theme_color_override("font_color", COL_ACCENT if here else COL_TEXT)
	if _display_station < 0:
		_station_label.text = system.start_label
		_info_label.text = START_TEXT
		_breaking_label.visible = false
		_helpers_label.visible = false
		_end_label.visible = false
		return
	var st: Dictionary = system.stations[_display_station]
	_station_label.text = st["name"]
	_info_label.text = st["info"]
	var kinds: Array = st["digestion"]
	if kinds.has("mechanical"):
		_chips_box.add_child(_make_chip("Mechanical", COL_ACCENT))
	if kinds.has("chemical"):
		_chips_box.add_child(_make_chip("Chemical", COL_GREEN))
	if kinds.has("absorption"):
		_chips_box.add_child(_make_chip("Absorption: nutrients into blood", COL_BLUE))
	if kinds.has("none"):
		_chips_box.add_child(_make_chip("No digestion", COL_GREY))
	_breaking_label.visible = true
	_breaking_label.text = "Breaking down: %s" % st["breaking_down"]
	var helper_names: PackedStringArray = PackedStringArray()
	for hid: String in st["helpers"]:
		helper_names.append(str(system.organs[hid]["name"]))
	_helpers_label.visible = not helper_names.is_empty()
	_helpers_label.text = "Helpers: %s" % ", ".join(helper_names)
	_end_label.visible = current_station == last and _display_station == last \
		and system.next_station(current_station) == -1


# ---------------------------------------------------------------- movement

func _begin_move() -> void:
	var seg: int = system.next_station(current_station)
	if seg < 0:
		return
	_moving = true
	_moving_segment = seg
	_t = 0.0
	# The old station's text and highlights stay until the token crosses into the next organ.
	_crossed = false
	_refresh_buttons()


func _process(delta: float) -> void:
	if _moving:
		_advance(delta)
		return
	if _busy > 0.0:
		_busy = maxf(_busy - delta, 0.0)
		if _busy <= 0.0 and not quiz_mode:
			_refresh_buttons()
		return
	if quiz_mode:
		return
	_step_btn.disabled = not _can_step()
	if not _playing:
		return
	if system.next_station(current_station) == -1:
		if loop_forever:
			_loop_timer -= delta
			if _loop_timer <= 0.0:
				reset_sim()
				_playing = true
				_loop_timer = LOOP_PAUSE
				_refresh_buttons()
		else:
			_playing = false
			_refresh_buttons()
	else:
		_begin_move()


func _advance(delta: float) -> void:
	var move_speed: float = QUIZ_SPEED if quiz_mode else speed
	_t += delta / system.travel_time(_moving_segment, move_speed)
	if not _crossed and _t >= system.switch_t(_moving_segment):
		_cross_border(_moving_segment)
	if _t >= 1.0:
		_arrive()
		return
	token.position = system.point_on_segment(_moving_segment, _t)
	token.on_travel(_moving_segment, _t)


## The token has entered the organ of station `seg`: switch the panel and map highlights.
func _cross_border(seg: int) -> void:
	_crossed = true
	_display_station = seg
	_map.set_highlight(seg)
	if quiz_mode:
		_reveal_quiz_station(seg)
	else:
		_apply_roles()
		_update_info()


func _arrive() -> void:
	_moving = false
	if not _crossed:
		_cross_border(_moving_segment)
	current_station = _moving_segment
	token.position = system.station_pos(current_station)
	_busy = maxf(token.on_arrive(current_station), 0.0)
	if quiz_mode:
		_on_quiz_arrived()
		return
	_end_label.visible = system.next_station(current_station) == -1
	if _playing:
		_loop_timer = LOOP_PAUSE
	_refresh_buttons()


# ---------------------------------------------------------------- quiz

func _clear_cards() -> void:
	for c: StationCard in _cards:
		_card_grid.remove_child(c)
		c.queue_free()
	_cards.clear()
	_selected_card_id = ""


func _set_boxes_interactive(on: bool) -> void:
	for id: String in system.organ_order:
		var bt: BoxTarget = _boxes[id]
		bt.set_interactive(on)


func _build_cards(items: Array[Dictionary], columns: int, font_size: int, key: String) -> void:
	_clear_cards()
	items.shuffle()
	_card_grid.visible = true
	_card_grid.columns = columns
	for item: Dictionary in items:
		var card: StationCard = StationCard.new()
		card.drag_key = key
		card.setup(item["id"], item["text"])
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(100, 44)
		card.add_theme_font_size_override("font_size", font_size)
		card.selected.connect(_on_card_selected)
		_card_grid.add_child(card)
		_cards.append(card)


func restart_quiz() -> void:
	quiz_part = 1
	_set_feedback_lines(FEEDBACK_LINES_PART1)
	_place_token_at_start()
	quiz_complete = false
	quiz2_complete = false
	mistakes = 0
	mistakes2 = 0
	steps_done = 0
	matched_count = 0
	_revealed.clear()
	_labelled.clear()
	_matched.clear()
	# Every "?" box takes drops: helper cards must land on their own box; station cards
	# count anywhere on the map (a box just passes them on).
	_set_boxes_interactive(true)
	for id: String in system.organ_order:
		var bt: BoxTarget = _boxes[id]
		bt.locked = false
		bt.set_state(BoxTarget.State.HIDDEN)
		bt.set_role(BoxTarget.Role.NONE)
	_part2_btn.visible = false
	_again_btn.visible = false
	var items: Array[Dictionary] = []
	for i: int in range(system.station_count()):
		items.append({"id": "station:%d" % i, "text": system.station_name(i)})
	var organ_cards: Array[String] = system.all_quiz_helpers()
	for oid: String in system.quiz_distractors:
		if not organ_cards.has(oid):
			organ_cards.append(oid)
	for oid: String in organ_cards:
		items.append({"id": "organ:%s" % oid, "text": str(system.organs[oid]["name"])})
	_build_cards(items, 2, 18, "card_id")
	_drop_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_prompt_label.text = "Drag the FIRST stop for %s onto the map!" % system.traveller_name
	_set_feedback("Tap a card, or press Enter on it, if you cannot drag.", COL_MUTED)
	_update_stats()
	_focus_first_card()


func start_part2() -> void:
	if not system.has_match_quiz or not quiz_complete:
		return
	quiz_part = 2
	_set_feedback_lines(FEEDBACK_LINES_PART2)
	quiz2_complete = false
	mistakes2 = 0
	matched_count = 0
	_matched.clear()
	_moving = false
	_busy = 0.0
	_map.set_highlight(-1)
	token.reset_token()
	token.visible = false
	_part2_btn.visible = false
	_again_btn.visible = false
	_drop_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id: String in system.organ_order:
		var bt: BoxTarget = _boxes[id]
		bt.locked = false
		bt.set_state(BoxTarget.State.NAME)
		bt.set_role(BoxTarget.Role.NONE)
	_set_boxes_interactive(true)
	var items: Array[Dictionary] = []
	for oid: String in system.organ_order:
		items.append({"id": oid, "text": str(system.organs[oid]["function"])})
	_build_cards(items, 2, 14, "organ_id")
	_prompt_label.text = "Part 2: What does each organ do? Drag each job onto the right organ."
	_set_feedback("Or tap a job card, then tap the organ.", COL_MUTED)
	_update_stats()
	_focus_first_card()


func _set_feedback(text_str: String, color: Color) -> void:
	_feedback_label.text = text_str
	_feedback_label.add_theme_color_override("font_color", color)


func _update_stats() -> void:
	if quiz_part == 1:
		_stats_label.text = "Progress: %d / %d     Mistakes: %d" % [steps_done, _part1_total(), mistakes]
	else:
		_stats_label.text = "Progress: %d / %d     Mistakes: %d" % [matched_count, system.organ_order.size(), mistakes2]


func _focus_first_card() -> void:
	call_deferred("_do_focus_first_card")


func _do_focus_first_card() -> void:
	if not quiz_mode:
		return
	for c: StationCard in _cards:
		if is_instance_valid(c) and c.is_inside_tree() and not c.disabled:
			c.grab_focus()
			return


func _find_card(id: String) -> StationCard:
	for c: StationCard in _cards:
		if c.card_id == id:
			return c
	return null


func _on_card_selected(id: String) -> void:
	if quiz_part == 1:
		if _is_helper_card(id) and not quiz_complete and not _moving and _busy <= 0.0:
			# Helper cards must go on their own box: tap the card, then tap the box.
			_select_card(id if _selected_card_id != id else "")
			if _selected_card_id != "":
				_set_feedback("Now tap its box on the map.", COL_BLUE)
			return
		submit_answer(id)
		return
	if quiz2_complete:
		return
	_select_card(id if _selected_card_id != id else "")
	if _selected_card_id != "":
		_set_feedback("Now tap the organ that does this job.", COL_BLUE)


func _select_card(id: String) -> void:
	_selected_card_id = id
	for c: StationCard in _cards:
		c.set_selected(c.card_id == id and not c.used)


func _on_map_dropped(card_id: String) -> void:
	submit_answer(card_id)


func _on_box_dropped(target_id: String, card_id: String) -> void:
	if quiz_part == 1:
		submit_answer(card_id, target_id)
	else:
		submit_match(target_id, card_id)


func _on_box_pressed(target_id: String) -> void:
	if quiz_part == 1:
		if quiz_complete:
			return
		if _selected_card_id == "":
			_set_feedback("Tap a helper organ card first, then tap its box.", COL_MUTED)
			return
		submit_answer(_selected_card_id, target_id)
		return
	if quiz2_complete:
		return
	if _selected_card_id == "":
		_set_feedback("Pick a job card first, then tap the organ.", COL_MUTED)
		return
	submit_match(target_id, _selected_card_id)


## Quiz part 1: card id is "station:<i>" or "organ:<id>". `target_id` is the organ box it was
## dropped on ("" = open map, or tapped). Station cards count anywhere; helper organ cards
## must land on their own box, and the whole helper group must be labelled before moving on.
func submit_answer(card_id: String, target_id: String = "") -> void:
	if not quiz_mode or quiz_part != 1 or _moving or _busy > 0.0 or quiz_complete:
		return
	var expected: int = system.next_station(current_station)
	var card: StationCard = _find_card(card_id)
	if card != null and card.used:
		return
	if _is_helper_card(card_id):
		_submit_helper(card, card_id.substr(6), target_id)
		return
	_select_card("")
	var guess: int = -1
	if card_id.begins_with("station:"):
		guess = int(card_id.substr(8))
	if guess == expected and guess >= 0 and not _pending_helpers().is_empty():
		# Right stop, wrong time: a reminder, not a mistake.
		_set_feedback("Right stop, but not yet! First label the helper organs on the map.", COL_ACCENT)
		if card != null:
			card.shake()
		return
	if guess == expected and guess >= 0:
		steps_done += 1
		if card != null:
			card.mark_used()
		_update_stats()
		_begin_move()
		return
	mistakes += 1
	var msg: String = ""
	if card_id.begins_with("organ:"):
		msg = str(system.organs[card_id.substr(6)]["hint"])
	if msg == "":
		if current_station < 0:
			msg = "Not quite. Where does %s go first?" % system.traveller_name
		else:
			msg = "Not quite. Where does %s go after the %s?" % [system.traveller_name, system.station_name(current_station)]
	_set_feedback(msg, COL_RED)
	_update_stats()
	if card != null:
		card.shake()


## Quiz part 2: drop or tap-tap a function card (id == organ id) on an organ box.
func submit_match(target_id: String, card_id: String) -> void:
	if not quiz_mode or quiz_part != 2 or quiz2_complete:
		return
	if _matched.has(target_id) or _matched.has(card_id) or not _boxes.has(target_id):
		return
	var card: StationCard = _find_card(card_id)
	var bt: BoxTarget = _boxes[target_id]
	if card_id == target_id:
		_matched[target_id] = true
		matched_count += 1
		bt.set_state(BoxTarget.State.NAME_AND_FUNCTION)
		bt.set_role(BoxTarget.Role.CORRECT)
		bt.locked = true
		if card != null:
			card.mark_used()
		_select_card("")
		_set_feedback("Correct! The %s: %s." % [system.organs[target_id]["name"], str(system.organs[target_id]["function"]).to_lower()], COL_GREEN)
		_update_stats()
		if matched_count >= system.organ_order.size():
			quiz2_complete = true
			_prompt_label.text = "You matched every organ! Part 2 mistakes: %d" % mistakes2
			_set_feedback("Great work! Part 1 mistakes: %d. Part 2 mistakes: %d." % [mistakes, mistakes2], COL_GREEN)
			_card_grid.visible = false
			_again_btn.visible = true
			_again_btn.call_deferred("grab_focus")
		else:
			_focus_first_card()
		return
	mistakes2 += 1
	_select_card("")
	_set_feedback("That's not what the %s does." % system.organs[target_id]["name"], COL_RED)
	_update_stats()
	if card != null:
		card.shake()


func _submit_helper(card: StationCard, oid: String, target_id: String) -> void:
	_select_card("")
	var organ_name: String = str(system.organs[oid]["name"])
	if target_id == "":
		_set_feedback("Drop the %s card right on its own box on the map." % organ_name, COL_ACCENT)
		return
	if target_id != oid:
		mistakes += 1
		_set_feedback("That box isn't the %s. Try another box." % organ_name, COL_RED)
		_update_stats()
		if card != null:
			card.shake()
		return
	var pending: Array[String] = _pending_helpers()
	if not pending.has(oid):
		# Right box, wrong time: a reminder, not a mistake.
		if pending.is_empty():
			_set_feedback("Right box, but not yet! Follow %s: where does it go next?" % system.traveller_name, COL_ACCENT)
		else:
			_set_feedback("Right box, but not yet! Label the helper organs for this part first.", COL_ACCENT)
		if card != null:
			card.shake()
		return
	_labelled[oid] = true
	steps_done += 1
	if card != null:
		card.mark_used()
	var bt: BoxTarget = _boxes[oid]
	bt.set_state(BoxTarget.State.NAME)
	bt.set_interactive(false)
	var left: int = _pending_helpers().size()
	var msg: String = "Correct! %s" % str(system.organs[oid]["hint"])
	if left > 0:
		msg += " %d more to label." % left
	else:
		_prompt_label.text = _next_prompt()
	_set_feedback(msg, COL_GREEN)
	_update_stats()
	_focus_first_card()


func _is_helper_card(card_id: String) -> bool:
	return card_id.begins_with("organ:") and system.all_quiz_helpers().has(card_id.substr(6))


## Helper organs still to be labelled before the token may move to the next station.
func _pending_helpers() -> Array[String]:
	var left: Array[String] = []
	var group: Dictionary = system.helper_group_before(system.next_station(current_station))
	if group.is_empty():
		return left
	for oid: String in group["organs"]:
		if not _labelled.has(oid):
			left.append(oid)
	return left


func _part1_total() -> int:
	return system.station_count() + system.all_quiz_helpers().size()


func _next_prompt() -> String:
	if not _pending_helpers().is_empty():
		var group: Dictionary = system.helper_group_before(system.next_station(current_station))
		return str(group["prompt"])
	if current_station < 0:
		return "Drag the FIRST stop for %s onto the map!" % system.traveller_name
	var who: String = system.traveller_name.substr(0, 1).to_upper() + system.traveller_name.substr(1)
	return "%s is in the %s. Drag the NEXT stop onto the map!" % [who, system.station_name(current_station)]


## Quiz: the token has crossed into station `seg`'s organ; name its boxes and outline them.
func _reveal_quiz_station(seg: int) -> void:
	_revealed[seg] = true
	for id: String in system.organ_order:
		var bt: BoxTarget = _boxes[id]
		bt.set_role(BoxTarget.Role.NONE)
	for i: int in _revealed.keys():
		for bid: String in system.stations[i]["boxes"]:
			var rb: BoxTarget = _boxes[bid]
			rb.set_state(BoxTarget.State.NAME)
			rb.set_interactive(false)
	for cid: String in system.stations[seg]["boxes"]:
		var cb: BoxTarget = _boxes[cid]
		cb.set_role(BoxTarget.Role.CURRENT)


func _on_quiz_arrived() -> void:
	var st: Dictionary = system.stations[current_station]
	_update_stats()
	var info: String = st["info"]
	if system.next_station(current_station) == -1:
		quiz_complete = true
		_prompt_label.text = "Part 1 complete! Mistakes: %d" % mistakes
		_set_feedback("Correct! %s" % info, COL_GREEN)
		# The used cards are no longer needed; hiding them leaves room for the Part 2 button.
		_card_grid.visible = false
		if system.has_match_quiz:
			_part2_btn.visible = true
			_part2_btn.call_deferred("grab_focus")
		else:
			_again_btn.visible = true
			_again_btn.call_deferred("grab_focus")
		return
	_prompt_label.text = _next_prompt()
	_set_feedback("Correct! %s" % info, COL_GREEN)
	_focus_first_card()


# ---------------------------------------------------------------- full screen

func is_fullscreen() -> bool:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## Button / F11. On the web this must come from a click or key press (browser rule), which it does.
func toggle_fullscreen() -> void:
	if is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_refresh_fullscreen_button()


func _refresh_fullscreen_button() -> void:
	if _fullscreen_btn != null:
		_fullscreen_btn.text = "Exit full screen" if is_fullscreen() else "Full screen"
