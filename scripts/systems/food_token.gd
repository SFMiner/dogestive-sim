class_name FoodToken
extends SimToken
## The baby carrot that travels through the digestive system.
## Its look changes at each station: chewed, swallowed, churned, absorbed, then it leaves the body.
## Nutrient and water particles are drawn here, behind the sprite.

const BASE_SCALE: float = 0.27
const CARROT_TEXTURES: Array[Texture2D] = [
	preload("res://art/carrots/carrot_1.png"),
	preload("res://art/carrots/carrot_2.png"),
	preload("res://art/carrots/carrot_3.png"),
	preload("res://art/carrots/carrot_4.png"),
	preload("res://art/carrots/carrot_5.png"),
	preload("res://art/carrots/carrot_6.png"),
]
const NUTRIENT_COLORS: Array[Color] = [
	Color(0.424, 0.753, 0.290),  # sugar green #6cc04a
	Color(0.910, 0.353, 0.659),  # amino pink #e85aa8
	Color(0.949, 0.761, 0.188),  # fat yellow #f2c230
]
const WATER_COLORS: Array[Color] = [
	Color(0.290, 0.639, 0.875),  # water blue #4aa3df
]
const LABEL_TEXT: String = "Nutrients → blood"
const LABEL_POS: Vector2 = Vector2(-58.0, -36.0)
const LABEL_RISE: float = 30.0

var _shape: int = 1
var _sprite: Sprite2D = null
var _label: Label = null
var _tween: Tween = null
var _particles: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


const HALO_RADIUS: float = 37.0
const HALO_SQUASH: float = 0.62
const HALO_FILL: Color = Color(1.0, 1.0, 1.0, 0.9)
const HALO_RIM: Color = Color(0.3, 0.2, 0.35, 0.9)
const HALO_RIM_WIDTH: float = 2.0


func _ready() -> void:
	_rng.randomize()
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_label = Label.new()
	_label.text = LABEL_TEXT
	_label.position = LABEL_POS
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.12, 0.2, 0.12))
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color.WHITE)
	_label.visible = false
	add_child(_label)
	reset_token()


func reset_token() -> void:
	_kill_tween()
	_particles.clear()
	_set_shape(1)
	scale = Vector2.ONE
	rotation = 0.0
	modulate = Color.WHITE
	visible = true
	_settle_sprite()
	_label.visible = false
	_label.modulate = Color.WHITE
	queue_redraw()


func on_travel(_seg: int, t: float) -> void:
	_sprite.scale.x = BASE_SCALE * (1.0 + 0.06 * sin(t * 40.0))


func on_arrive(index: int) -> float:
	var tween: Tween = _restart_tween()
	_settle_sprite()
	_label.visible = false
	match index:
		DigestiveSystem.MOUTH:
			return _anim_mouth(tween)
		DigestiveSystem.ESOPHAGUS:
			return _anim_esophagus(tween)
		DigestiveSystem.STOMACH:
			return _anim_stomach(tween)
		DigestiveSystem.SMALL_INTESTINE:
			return _anim_small_intestine(tween)
		DigestiveSystem.LARGE_INTESTINE:
			return _anim_large_intestine(tween)
		DigestiveSystem.RECTUM:
			return _anim_rectum(tween)
	return 0.0


func _process(delta: float) -> void:
	if _particles.is_empty():
		return
	var alive: Array[Dictionary] = []
	for p: Dictionary in _particles:
		var age: float = float(p["age"]) + delta
		if age < float(p["life"]):
			p["age"] = age
			alive.append(p)
	_particles = alive
	queue_redraw()


func _draw() -> void:
	# Backing halo so the orange carrot stays visible on orange organs (mouth, esophagus, intestines).
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, HALO_SQUASH))
	draw_circle(Vector2.ZERO, HALO_RADIUS, HALO_FILL, true, -1.0, true)
	draw_circle(Vector2.ZERO, HALO_RADIUS, HALO_RIM, false, HALO_RIM_WIDTH / HALO_SQUASH, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for p: Dictionary in _particles:
		var t: float = float(p["age"]) / float(p["life"])
		var eased: float = 1.0 - (1.0 - t) * (1.0 - t)
		var dest: Vector2 = p["dest"]
		var base_color: Color = p["color"]
		var radius: float = p["radius"]
		draw_circle(dest * eased, radius, Color(base_color.r, base_color.g, base_color.b, 1.0 - t))


# Arrival animations. Each one fills the tween it is given and returns the wait time.

func _anim_mouth(tween: Tween) -> float:
	_chomp(tween)
	tween.tween_callback(_set_shape.bind(2))
	tween.tween_interval(0.3)
	_chomp(tween)
	tween.tween_callback(_set_shape.bind(3))
	return 1.4


func _anim_esophagus(tween: Tween) -> float:
	tween.tween_property(_sprite, "scale:x", BASE_SCALE * 0.75, 0.15)
	tween.tween_property(_sprite, "scale:x", BASE_SCALE, 0.15)
	return 0.4


func _anim_stomach(tween: Tween) -> float:
	# Six swings of 1/6 s each (1.0 s total); the shape changes at the halfway point.
	var step: float = 1.0 / 6.0
	var angles: Array[float] = [0.25, -0.25, 0.25, -0.25, 0.25, 0.0]
	for i: int in angles.size():
		if i == 3:
			tween.tween_callback(_set_shape.bind(4))
		tween.tween_property(self, "rotation", angles[i], step)
	return 1.2


func _anim_small_intestine(tween: Tween) -> float:
	tween.tween_callback(_set_shape.bind(5))
	tween.tween_property(_sprite, "scale", Vector2(BASE_SCALE, BASE_SCALE) * 1.2, 0.12)
	tween.tween_property(_sprite, "scale", Vector2(BASE_SCALE, BASE_SCALE), 0.15)
	tween.tween_callback(_spawn_burst.bind(16, NUTRIENT_COLORS, 40.0, 70.0, 1.5))
	tween.tween_callback(_show_label)
	tween.tween_property(_label, "position:y", LABEL_POS.y - LABEL_RISE, 1.5)
	tween.parallel().tween_property(_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(_hide_label)
	return 1.8


func _anim_large_intestine(tween: Tween) -> float:
	tween.tween_callback(_set_shape.bind(6))
	tween.tween_callback(_spawn_burst.bind(10, WATER_COLORS, 25.0, 45.0, 1.0))
	return 1.2


func _anim_rectum(tween: Tween) -> float:
	tween.tween_interval(0.4)
	tween.tween_property(_sprite, "position", Vector2(0.0, 18.0), 0.6)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.6)
	return 1.2


func _chomp(tween: Tween) -> void:
	tween.tween_property(_sprite, "scale:y", BASE_SCALE * 0.6, 0.125)
	tween.tween_property(_sprite, "scale:y", BASE_SCALE, 0.125)


# Helpers

func _restart_tween() -> Tween:
	_kill_tween()
	_tween = create_tween()
	return _tween


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _settle_sprite() -> void:
	_sprite.scale = Vector2(BASE_SCALE, BASE_SCALE)
	_sprite.position = Vector2.ZERO
	rotation = 0.0


func _set_shape(shape_index: int) -> void:
	_shape = clampi(shape_index, 1, CARROT_TEXTURES.size())
	_sprite.texture = CARROT_TEXTURES[_shape - 1]


func _show_label() -> void:
	_label.position = LABEL_POS
	_label.modulate = Color.WHITE
	_label.visible = true


func _hide_label() -> void:
	_label.visible = false


func _spawn_burst(count: int, palette: Array[Color], min_dist: float, max_dist: float, life: float) -> void:
	for i: int in count:
		var angle: float = _rng.randf_range(0.0, TAU)
		var dist: float = _rng.randf_range(min_dist, max_dist)
		var color: Color = palette[_rng.randi() % palette.size()]
		_particles.append({
			"dest": Vector2.from_angle(angle) * dist,
			"radius": _rng.randf_range(3.0, 4.0),
			"color": color,
			"age": 0.0,
			"life": life,
		})
	queue_redraw()
