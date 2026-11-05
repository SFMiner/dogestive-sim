class_name SimSystem
extends RefCounted
## Data contract for one body system (digestive, circulatory, ...).
## The engine (main.gd, map_view.gd) reads ONLY this API; each system subclasses it and
## fills the fields in _init(). All coordinates are map-local (map area = map_size, top-left 0,0).
##
## Station model: the token starts at start_pos. segments[i] is the path that leads INTO
## stations[i] (segments[0] goes from start_pos to stations[0]). For a loop system,
## start_pos == the last station's pos and segments[0] leaves it.

var title: String = ""
var map_size: Vector2 = Vector2(680, 720)
var background_path: String = ""
var background_rect: Rect2 = Rect2()
var start_pos: Vector2 = Vector2.ZERO
## Loop systems go round again after the last station; linear ones end there.
var is_loop: bool = false
## Short label for the thing that travels, used in prompts ("the food", "the blood cell").
var traveller_name: String = "the food"
var start_label: String = ""

## Each station: {
##   "name": String, "pos": Vector2,
##   "boxes": Array[String]      – organ ids whose label boxes belong to this station,
##   "helpers": Array[String]    – organ ids that help here (highlighted differently),
##   "digestion": Array[String]  – any of "mechanical", "chemical", "absorption", "none",
##   "info": String              – what happens here (2–4 sentences),
##   "breaking_down": String     – one line, what is broken down (or "Nothing ..."),
## }
var stations: Array[Dictionary] = []
var segments: Array[PackedVector2Array] = []

## Organ id -> { "name": String, "box": Rect2, "function": String, "hint": String }
## "hint" is the feedback when the organ is wrongly picked as the next station in quiz part 1.
var organs: Dictionary = {}
## Organ ids in a stable display order (used for quiz-2 cards and drawing).
var organ_order: Array[String] = []
## Organ ids offered as wrong-answer cards in quiz part 1 (food never passes through them).
var quiz_distractors: Array[String] = []
## Whether quiz part 2 (drag each organ's function onto its box) exists for this system.
var has_match_quiz: bool = false

## Travel time per segment is length / speed, clamped to this range (seconds),
## so very long winding segments don't take forever.
var min_travel_time: float = 1.0
var max_travel_time: float = 5.0


func station_count() -> int:
	return stations.size()


func station_name(index: int) -> String:
	return stations[index]["name"]


func station_pos(index: int) -> Vector2:
	return stations[index]["pos"]


func segment_length(seg: int) -> float:
	var pts: PackedVector2Array = segments[seg]
	var total: float = 0.0
	for i: int in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total


func point_on_segment(seg: int, t: float) -> Vector2:
	var pts: PackedVector2Array = segments[seg]
	var target: float = clampf(t, 0.0, 1.0) * segment_length(seg)
	for i: int in range(pts.size() - 1):
		var piece: float = pts[i].distance_to(pts[i + 1])
		if target <= piece or i == pts.size() - 2:
			if piece <= 0.0:
				return pts[i + 1]
			return pts[i].lerp(pts[i + 1], clampf(target / piece, 0.0, 1.0))
		target -= piece
	return pts[pts.size() - 1]


## Seconds to travel a segment at the given speed (map px / s), clamped.
func travel_time(seg: int, speed: float) -> float:
	return clampf(segment_length(seg) / maxf(speed, 1.0), min_travel_time, max_travel_time)


## Index of the station after `index`, or -1 when a linear system has ended.
func next_station(index: int) -> int:
	if index + 1 < stations.size():
		return index + 1
	return 0 if is_loop else -1


## Map from SVG units to map-local coordinates (helper for subclasses).
static func svg_rect(x0: float, y0: float, x1: float, y1: float, scale_factor: float, offset: Vector2) -> Rect2:
	return Rect2(Vector2(x0, y0) * scale_factor + offset, Vector2(x1 - x0, y1 - y0) * scale_factor)
