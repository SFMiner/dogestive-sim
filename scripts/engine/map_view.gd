class_name MapView
extends Node2D
## Draws the map: white background, the artwork and a pulsing ring at the current station.
## No station dots: the artwork's pink pointer dots already mark each stop.
## Map-local space == screen. Knows only SimSystem.

const COL_HIGHLIGHT: Color = Color("#e8641b")

var _system: SimSystem
var _background: Texture2D
var _highlight: int = -1
var _pulse: float = 0.0


func setup(sys: SimSystem) -> void:
	_system = sys
	_background = load(sys.background_path) as Texture2D
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_process(false)
	queue_redraw()


## -1 = none. Otherwise a pulsing ring is drawn around that station.
func set_highlight(index: int) -> void:
	if _system == null or index < 0 or index >= _system.station_count():
		_highlight = -1
	else:
		_highlight = index
	_pulse = 0.0
	set_process(_highlight >= 0)
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	if _system == null:
		return
	draw_rect(Rect2(Vector2.ZERO, _system.map_size), Color.WHITE)
	if _background != null:
		draw_texture_rect(_background, _system.background_rect, false)
	if _highlight >= 0:
		var hp: Vector2 = _system.station_pos(_highlight)
		var wave: float = 0.5 + 0.5 * sin(_pulse * 6.0)
		var ring_r: float = 19.0 + 5.0 * wave
		draw_arc(hp, ring_r + 5.0, 0.0, TAU, 48, Color(COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 0.35 * (1.0 - wave)), 4.0, true)
		# White edge so the orange ring still shows on orange organs (mouth, small intestine).
		draw_arc(hp, ring_r, 0.0, TAU, 48, Color.WHITE, 8.0, true)
		draw_arc(hp, ring_r, 0.0, TAU, 48, COL_HIGHLIGHT, 4.0, true)
