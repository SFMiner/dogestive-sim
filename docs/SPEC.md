# Digestion Sim — Build Spec (manager-owned; agents follow exactly)

Godot 4.5, GDScript only, **TABS for indentation**, static typing everywhere, GL Compatibility, HTML5 export.
Viewport 1280x720 (`canvas_items` / `keep`). All UI built in code; the only scene is `res://scenes/main.tscn`
(full-rect Control running `scripts/engine/main.gd`). Don't hand-write `.uid` files.

Reference implementation: the sister project `/home/user/circulation-sim` (read-only!). Its `scripts/main.gd`,
`station_card.gd`, `map_drop_area.gd` already solve theme-in-code, drag-and-drop with mouse+touch, tap/Enter-to-submit,
keyboard shortcuts in `_input`, movement, shake feedback. Reuse those patterns; do not edit that project.

## What it teaches
A baby carrot travels the digestive tract: Mouth → Esophagus → Stomach → Small Intestine → Large Intestine →
Rectum & Anus. It changes SHAPE (not colour) as it is digested: carrot 1 (whole) → 2 → 3 (chewed, in the mouth)
→ 4 (paste, stomach) → 5 (liquid, small intestine; nutrients pass into the blood) → 6 (waste, large intestine).
This is a simple visual illustration, not a simulation.

## Engine / data split (DONE — read, don't edit)
- `scripts/engine/sim_system.gd` — `SimSystem`, the data contract. The engine must only use this API.
- `scripts/engine/sim_token.gd` — `SimToken`, the traveller contract: `reset_token()`, `on_travel(seg, t)`,
  `on_arrive(index) -> float` (seconds the arrival animation takes).
- `scripts/systems/digestive_system.gd` — `DigestiveSystem extends SimSystem`, all geometry and text.
The engine creates the system and token in ONE place (`main.gd`: `_create_system()` / `_create_token()`), so a future
circulatory system can plug in. Linear systems (`is_loop == false`) end at the last station.

Station model: token starts at `system.start_pos` with `current_station = -1` ("Ready to eat").
`segments[i]` leads INTO station i. `next_station(i)` returns -1 at the end of a linear system.
Travel: `t += delta / system.travel_time(seg, speed)`; position = `point_on_segment(seg, t)`; call
`token.on_travel(seg, t)` each frame. On t >= 1: snap to station pos, `current_station = seg`,
`var wait: float = token.on_arrive(seg)`; the token is "busy" for `wait` seconds (no new move starts until then).

## Layout
- Map area x 0..680, y 0..720, map-local == screen. `MapView` (Node2D) at (0,0); the token is a child of MapView.
- `BoxTarget` controls (one per organ, rect = `organs[id]["box"]`) sit ABOVE the map, as children of a full-map
  Control layer; `MapDropArea` (full map, quiz part 1 only) sits above the map but BELOW the BoxTargets layer.
- Side panel x 680..1280 (PanelContainer, ~16 px margins), same structure as circulation-sim.

## Files & owners
### Agent APP (Sonnet): `scripts/engine/main.gd`, `map_view.gd`, `station_card.gd`, `map_drop_area.gd`, `box_target.gd`
**map_view.gd** — `class_name MapView extends Node2D`; `func setup(sys: SimSystem)`; draws white bg, the background
texture into `system.background_rect`, a small dot at each station, and a pulsing orange ring at the current station
(`set_highlight(index)`, -1 = none; `_process` only while highlighted).

**box_target.gd** — `class_name BoxTarget extends Button` (flat, transparent StyleBoxEmpty for all states except focus),
one per organ, positioned/sized to the organ box. Shows text with a child Label (autowrap, centred, dark text):
states: `HIDDEN` ("?" large purple), `NAME` (organ name, 18 px), `NAME_AND_FUNCTION` (name 15 px bold-ish + function 12 px,
must fit the ~158x60 box — use two Labels in a VBox or one Label with smaller font). Outline drawn in `_draw` by role:
`current` (orange 4 px), `helper` (green 3 px dashed or solid), `correct` (green 3 px), `selected` (blue 3 px), none.
In explore + quiz part 1: `mouse_filter = IGNORE`, `focus_mode = NONE`. In quiz part 2: `MOUSE_FILTER_STOP`,
`FOCUS_ALL`, accepts drops (`_can_drop_data` for {"organ_id"}), emits `signal answer_dropped(target_id: String, card_id: String)`
and on press emits `signal box_pressed(target_id: String)`.

**station_card.gd** — like circulation's StationCard but generic: `var card_id: String`, `setup(id, text)`,
autowrap text (Button `autowrap_mode`), drag data `{"organ_id": card_id}` for part 2 or `{"card_id": card_id}` for part 1
(one class; caller sets `drag_key`). `mark_used()`, `shake()`, `set_selected(bool)`. Tap/Enter emits `selected(card_id)`
but never after a drag (same guard as circulation).

**main.gd** — builds everything. Modes: Explore / Quiz (toggle buttons, M key).
*Explore*:
- Buttons `Step >`, `Play`/`Pause`, `Reset`; speed HSlider (60–320 px/s, default 140); `Loop forever` CheckBox
  (linear system: when on, after the last station's animation wait 1.5 s, reset and play again).
- Start screen (current_station == -1): title = `system.start_label`, text "Press Step or Play to send the carrot into
  the mouth." Step at the last station does nothing; show "Press Reset to eat another carrot."
- Info panel for current station: name (large); chips row from `digestion` — "Mechanical" (orange), "Chemical" (green),
  "Absorption: nutrients into blood" (blue), "No digestion" (grey); `info` text (autowrap); "Breaking down:" + `breaking_down`;
  "Helpers:" + comma list of helper organ names (omit row when empty). Route list of the 6 stations, current marked with ">".
- Map: BoxTargets show NAME; boxes of the current station = `current`, helper boxes = `helper`; ring at current station.
*Quiz part 1* (order):
- Start: token reset at start_pos; all BoxTargets HIDDEN; cards = all stations (id "station:<i>", text = station name)
  + distractor organs (id "organ:<id>", text = organ name), shuffled, 2-column grid.
  Prompt: "Drag the FIRST stop for the carrot onto the map!" then "The carrot is in the <name>. Drag the NEXT stop onto the map!"
- Drop anywhere on the map (MapDropArea) or tap/Enter a card → submit. Correct = the next station: token travels there,
  its boxes switch to NAME on arrival, card marked used, green "Correct!" + the station's `info`.
  Wrong: mistakes += 1, card shakes, red feedback = the organ's `hint` for distractor cards, otherwise
  "Not quite. Where does food go after the <current name>?" (or "...go first?" at start). Ignore input while moving/busy.
- After the last station: "Part 1 complete! Mistakes: N" and a `Go to Part 2` button (only if `system.has_match_quiz`).
*Quiz part 2* (match functions):
- All BoxTargets show NAME and become drop/press targets. Cards = every organ's `function` (id = organ id), shuffled,
  1 column (text is long). Prompt: "Part 2: What does each organ do? Drag each job onto the right organ."
- Drop card on a box, OR tap a card (becomes `selected`, blue) then tap/Enter a box. Correct (card id == box id):
  box → NAME_AND_FUNCTION + `correct` outline, card used. Wrong: mistakes += 1, card shakes,
  "That's not what the <box organ name> does."
- All matched: "You matched every organ! Part 2 mistakes: N" + `Start Over` (back to quiz part 1).
- Quiz-1 and quiz-2 mistakes counted separately; show "Progress: x / y   Mistakes: n".
*Keyboard* (register actions in code; handle in `_input` so Space doesn't press the focused Step button — see
circulation main.gd): Space play/pause (explore only), Right/N step, R reset (explore) / restart (quiz), M mode.
*Theme*: built in code like circulation, warm palette: background #f7f3ee, panel #ffffff, accent orange #e8641b,
text #2a2320, chemical green #3d8b37, absorption blue #2f6fbf, none grey #8a8580. Buttons min 44 px tall.

### Agent TOKEN (Haiku): `scripts/systems/food_token.gd`
`class_name FoodToken extends SimToken`. Child `Sprite2D` showing `res://art/carrots/carrot_<n>.png` (n = 1..6;
PNGs are 4 px per SVG unit, so `sprite.scale = Vector2(0.27, 0.27)`). Preload all six textures.
- `reset_token()`: shape 1, scale ONE, rotation 0, modulate opaque, visible, clear particles, kill tweens.
- `on_travel(seg, t)`: gentle squeeze wobble while moving: `sprite.scale.x = 0.27 * (1.0 + 0.06 * sin(t * 40.0))`.
- `on_arrive(index) -> float` (match on DigestiveSystem constants):
  - MOUTH: chomp (squash scale.y to 0.6× and back, 0.25 s) → shape 2, pause 0.3 s, chomp → shape 3. Return 1.4.
  - ESOPHAGUS: gulp (scale.x 0.75× and back, 0.3 s). Return 0.4.
  - STOMACH: churn (rotation ±0.25 rad a few times over 1.0 s), swap to shape 4 half-way. Return 1.2.
  - SMALL_INTESTINE: swap to shape 5 with a pop, then a burst of ~16 nutrient particles (small circles, radius 3–4,
    colours: sugar green #6cc04a, amino pink #e85aa8, fat yellow #f2c230) drifting outward 40–70 px and fading over 1.5 s,
    plus a small floating Label "Nutrients → blood" (white outline, 14 px) that rises and fades. Return 1.8.
  - LARGE_INTESTINE: swap to shape 6, emit ~10 small blue (#4aa3df) water drops drifting out and fading 1.0 s. Return 1.2.
  - RECTUM: wait 0.4 s, then slide down 18 px and fade out over 0.6 s ("leaves the body"). Return 1.2.
- Particles: keep an Array of dictionaries, update in `_process`, draw in `_draw` (token's own draw, behind the sprite).
- Every new animation kills the previous tween first.

## Rules for all agents
- Tabs only; typed; Godot 4.5 API; no shadowing built-ins (`name`, `position`, `scale`, `show`, `visible`, `size`).
- Only edit files you own. Never edit `/home/user/circulation-sim`.
- Verify: `G=/tmp/claude-0/-home-user-circulation-sim/ad8ec746-7a5d-5f4a-a6b7-cc516f1289cc/scratchpad/Godot_v4.5-stable_linux.x86_64`;
  after adding class_name files run `$G --headless --path /home/user/dogestive-sim --import` once, then
  `$G --headless --path /home/user/dogestive-sim --quit-after 300 2>&1 | grep -iE "error|warn|parse"` and fix everything
  from your files. Temporary test scripts go in the project as `scripts/_test_*.gd` and must be deleted afterwards.
  Screenshots: `xvfb-run -a $G --path ... --rendering-driver opengl3 --script res://scripts/_shot.gd` saving PNGs to
  `/tmp/claude-0/-home-user/ad8ec746-7a5d-5f4a-a6b7-cc516f1289cc/scratchpad/`; look at them with Read and fix layout issues.
