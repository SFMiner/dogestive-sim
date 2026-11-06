# Digestion Sim — Claude Code Project Context

Simple visual (not a real simulation) Godot 4.5 illustration of digestion. A baby carrot moves station
to station and changes SHAPE (carrot_1..6). Explore mode, quiz part 1 (order of stations; accessory organs must be
labelled on their own boxes before the carrot moves on) and quiz part 2 (match organ functions to label boxes). HTML5 export; mouse, touch, keyboard.

## Standards
- Godot 4.5, GDScript, TABS only, static typing, GL Compatibility; UI built in code; one scene.
- Engine (scripts/engine) only uses SimSystem/SimToken; system data in scripts/systems.
- Geometry traced from art/source/digestive-system.svg ("food-path"); background PNG rendered from it at
  1295x1440 and drawn into DigestiveSystem.background_rect. If the art changes, re-trace and re-render.
- Sister project: SFMiner/circulation-sim (same UI patterns).

See docs/SPEC.md and README.md.
