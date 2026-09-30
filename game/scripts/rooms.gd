extends RefCounted
## The three workshop rooms and where their crates sit.

const Puzzles = preload("res://scripts/puzzles.gd")

const MAX_CARRY := 3

## Positions are fractions of the floor (0 to 1). The drop-off door is on the
## right wall, so crates stay clear of it.
const ROOMS := [
	{"id": "gear", "name": "Gear Shop", "kinds": ["direction", "speed", "ratio"], "family": "ground",
		"spots": [Vector2(0.10, 0.28), Vector2(0.27, 0.80), Vector2(0.30, 0.50), Vector2(0.46, 0.24), Vector2(0.46, 0.78), Vector2(0.64, 0.46), Vector2(0.74, 0.80)]},
	{"id": "green", "name": "Green Shed", "kinds": ["circuit", "energy", "magnet"], "family": "energy",
		"spots": [Vector2(0.22, 0.32), Vector2(0.46, 0.70), Vector2(0.68, 0.30)]},
	{"id": "hangar", "name": "Hangar", "kinds": ["balance"], "family": "air",
		"spots": [Vector2(0.32, 0.40), Vector2(0.62, 0.66)]},
]

const DROP_ZONE := Rect2(0.90, 0.05, 0.10, 0.30)  # fractions of the floor


static func room_count() -> int:
	return ROOMS.size()


## Puzzle ids in a room, in the order they are defined.
static func puzzles_in(room: int) -> Array:
	var out: Array = []
	for p in Puzzles.PUZZLES:
		if ROOMS[room]["kinds"].has(p["kind"]):
			out.append(p["id"])
	return out
