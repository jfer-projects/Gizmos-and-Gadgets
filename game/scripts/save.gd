extends RefCounted
## Progress: which crates are solved, which courses have stars. Stored on the
## device only, in one small JSON file. No accounts, no network.

const Puzzles = preload("res://scripts/puzzles.gd")

const DEFAULT_PATH := "user://tinker_track_save.json"

var path: String = DEFAULT_PATH
var solved: Array = []       # puzzle ids
var stars: Dictionary = {}   # course id -> best stars (0 to 3)
var last_motor: int = 16
var last_wheel: int = 16
var play_seconds: float = 0.0
var settings: Dictionary = default_settings()


static func default_settings() -> Dictionary:
	return {
		"theme": "day",         # day, night, hc
		"sfx": true,
		"music": true,
		"read_aloud": false,
		"large_text": false,
		"reduced_motion": false,
		"pests": true,
	}


func owned(kind: String) -> Array:
	var list: Array = Puzzles.START_MOTOR.duplicate() if kind == "motor" else Puzzles.START_WHEEL.duplicate()
	for id in solved:
		var p := Puzzles.by_id(id)
		if not p.is_empty() and p["reward"]["kind"] == kind and not list.has(p["reward"]["teeth"]):
			list.append(p["reward"]["teeth"])
	list.sort()
	return list


func is_solved(id: String) -> bool:
	return solved.has(id)


func mark_solved(id: String) -> void:
	if not solved.has(id):
		solved.append(id)
	write()


func stars_for(course_id: String) -> int:
	return int(stars.get(course_id, 0))


func record_stars(course_id: String, count: int) -> void:
	if count > stars_for(course_id):
		stars[course_id] = count
	write()


## A course is open when the one before it has been won.
func course_unlocked(courses: Array, index: int) -> bool:
	return index == 0 or stars_for(courses[index - 1]["id"]) > 0


func write() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return  # read-only storage: play on without saving
	f.store_string(JSON.stringify({"solved": solved, "stars": stars, "motor": last_motor, "wheel": last_wheel, "play_seconds": play_seconds, "settings": settings}))


func load_from_disk() -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	solved = []
	for id in data.get("solved", []):
		if Puzzles.by_id(str(id)).size() > 0:
			solved.append(str(id))
	stars = {}
	var s = data.get("stars", {})
	if typeof(s) == TYPE_DICTIONARY:
		for k in s:
			stars[str(k)] = clampi(int(s[k]), 0, 3)
	play_seconds = maxf(0.0, float(data.get("play_seconds", 0.0)))
	var st = data.get("settings", {})
	if typeof(st) == TYPE_DICTIONARY:
		var defaults := default_settings()
		for k in defaults:
			if st.has(k) and typeof(st[k]) == typeof(defaults[k]):
				settings[k] = st[k]
		if not ["day", "night", "hc"].has(settings["theme"]):
			settings["theme"] = "day"
	last_motor = int(data.get("motor", 16))
	last_wheel = int(data.get("wheel", 16))
	if not owned("motor").has(last_motor):
		last_motor = 16
	if not owned("wheel").has(last_wheel):
		last_wheel = 16


## Wipe progress but keep the player's settings.
func reset_progress() -> void:
	solved = []
	stars = {}
	last_motor = 16
	last_wheel = 16
	play_seconds = 0.0
	write()
