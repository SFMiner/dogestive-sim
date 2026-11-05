class_name SimToken
extends Node2D
## Base class for the thing that travels (food pellet, blood cell, ...).
## The engine sets `position` itself while travelling; these hooks only change the look.
## Subclasses override the hooks; the defaults do nothing.


## Back to the starting look (called on reset / quiz restart).
func reset_token() -> void:
	pass


## Called every frame while travelling along segment `seg` (leads into station `seg`), t = 0..1.
func on_travel(_seg: int, _t: float) -> void:
	pass


## Called when the token arrives at station `index`. Play the arrival animation and
## return how many seconds it takes; the engine waits that long before the next move.
func on_arrive(_index: int) -> float:
	return 0.0
