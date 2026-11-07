# Digestion Sim — Journey of a Baby Carrot

A simple, visual Godot 4.5 illustration of the human digestive system. A baby carrot travels
Mouth → Esophagus → Stomach → Small Intestine → Large Intestine → Rectum & Anus and changes
shape as it is digested (whole → chewed → paste → liquid → waste).

## Modes
- **Explore**: Step one station at a time or Play continuously. The side panel shows the type of
  digestion (mechanical, chemical, absorption), what happens, what is broken down, and which
  helper organs (salivary glands, liver, gallbladder, pancreas) are involved. The panel and map
  highlights switch as soon as the carrot crosses into the next organ, not when it reaches the stop.
- **Quiz part 1**: drag the next stop onto the map (anywhere). Before the carrot can move on, the
  helper organs must be labelled by dropping each card on its own box: Salivary Glands before the
  Esophagus; Liver, Gallbladder and Pancreas (any order) before the Small Intestine; Appendix before
  the Large Intestine. A right card at the wrong time is a reminder, not a mistake.
- **Quiz part 2**: drag each organ's job onto its label box.

## Controls
| Key | Action |
|-----|--------|
| Space | Play / Pause (Explore) |
| Right arrow / N | Step |
| R | Reset / restart quiz |
| M | Switch Explore / Quiz |
| F11 | Full screen on/off (also the "Full screen" button) |
| Tab, arrows, Enter | Move between and press buttons/cards/boxes |

## Project layout
- `scripts/engine/` — system-agnostic engine (`SimSystem` data contract, `SimToken` traveller, UI).
- `scripts/systems/digestive_system.gd` — all stations, path geometry, organ boxes and text.
- `scripts/systems/food_token.gd` — the carrot and its animations.
- `art/digestive_background.png`, `art/carrots/` — rendered from the SVGs in `art/source/`
  (the background's `food-path` is invisible; the cell path was traced from it).

## Export
Project → Export → **Web** (needs Godot 4.5 export templates). Serve `exports/web/` from a web server.
