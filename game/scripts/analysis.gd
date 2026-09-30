extends RefCounted
## Turns a finished (or failed) race into plain-language "Why did I lose?" notes.

const Drivetrain = preload("res://scripts/drivetrain.gd")

const MIN_LOSS_SECONDS := 0.2
const STALL_SPEED := 1.0
const STALL_SECONDS := 2.0


## Returns up to two notes, biggest time loss first. Each note is a Dictionary:
## time (float, when the segment began), place (String), title, body,
## direction ("pull" or "speed"), stalled (bool), suggested_ratio (float).
static func explain(result: Dictionary) -> Array:
	var ci: int = result["course"]
	var best: Dictionary = Drivetrain.best_build(ci)
	var best_result: Dictionary = best["result"]
	var ratio: float = result["ratio"]
	var segs := Drivetrain.segments(ci)
	if result["fail"] == "crash":
		return [_crash_note(result, best)]
	var notes: Array = []
	for i in segs.size():
		if i >= result["seg_enter"].size():
			continue  # never got this far
		var loss: float = result["seg_durations"][i] - best_result["seg_durations"][i]
		if loss < MIN_LOSS_SECONDS:
			continue
		var stalled := _stalled_in_segment(result, i)
		var direction := "pull" if ratio < best["ratio"] else "speed"
		notes.append({
			"segment": i,
			"stalled": stalled,
			"loss": loss,
			"time": result["seg_enter"][i],
			"place": segs[i]["place"],
			"title": _title(segs[i]["kind"], i, direction, stalled),
			"body": _body(ratio, direction, stalled),
			"direction": direction,
			"suggested_ratio": _suggested_ratio(ratio, direction, stalled),
		})
	notes.sort_custom(func(a, b): return a["loss"] > b["loss"])
	# A stall explains everything after it, so give that one note on its own.
	for n in notes:
		if n["stalled"]:
			return [n]
	# Two notes with the same advice say the same thing: keep the bigger one.
	if notes.size() > 1 and notes[0]["suggested_ratio"] == notes[1]["suggested_ratio"]:
		return [notes[0]]
	return notes.slice(0, 2)


## A crash beats everything else: say what went wrong and which way to move.
static func _crash_note(result: Dictionary, best: Dictionary) -> Dictionary:
	var ci: int = result["course"]
	var seg: int = result["crash_segment"]
	var kind: String = Drivetrain.segments(ci)[seg]["kind"]
	var ratio: float = result["ratio"]
	var direction := "pull" if ratio < best["ratio"] else "speed"
	var r := "%s : 1" % _fmt(ratio)
	var title := "Too slow to take off" if kind == "runway" else "Fell out of the sky"
	var body: String
	if kind == "runway":
		if direction == "pull":
			body = "A %s ratio did not speed up fast enough before the runway ended. A bigger ratio speeds up faster." % r
		else:
			body = "A %s ratio pulls hard but the wheels top out below take-off speed. A smaller ratio is faster." % r
	else:
		if direction == "pull":
			body = "A %s ratio let the plane slow down too much. A bigger ratio pulls harder." % r
		else:
			body = "A %s ratio topped out and the plane slowed down. A smaller ratio is faster." % r
	return {
		"segment": seg,
		"stalled": true,
		"loss": 999.0,
		"time": result["time"],
		"place": Drivetrain.segments(ci)[seg]["place"],
		"title": title,
		"body": body,
		"direction": direction,
		"suggested_ratio": _suggested_ratio(ratio, direction, true),
	}


static func _stalled_in_segment(result: Dictionary, seg: int) -> bool:
	var ci: int = result["course"]
	var kind: String = Drivetrain.segments(ci)[seg]["kind"]
	if kind != "hill" and kind != "mud":
		return false
	var xs: PackedFloat32Array = result["xs"]
	var vs: PackedFloat32Array = result["vs"]
	var start_x := Drivetrain.segment_start(ci, seg)
	var end_x := Drivetrain.segment_end(ci, seg)
	var needed := int(STALL_SECONDS / Drivetrain.DT)
	var slow_steps := 0
	for k in xs.size():
		if xs[k] >= start_x and xs[k] < end_x and vs[k] < STALL_SPEED:
			slow_steps += 1
			if slow_steps >= needed:
				return true
	return false


## Titles by segment kind: [when more pull was needed, when more speed was needed].
const TITLES := {
	"mud": ["Bogged down in the mud", "Slow through the mud"],
	"down": ["Slow off the ramp", "Topped out downhill"],
	"cloud": ["Slow in the clouds", "Topped out in the clouds"],
	"head": ["Slow into the wind", "Topped out into the wind"],
	"tail": ["Slow to use the tailwind", "Topped out with the wind"],
	"runway": ["Slow on the runway", "Topped out on the runway"],
	"air": ["Slow in the air", "Topped out in the air"],
}


static func _title(kind: String, index: int, direction: String, stalled: bool) -> String:
	var pick := 0 if direction == "pull" else 1
	if kind == "hill":
		return "Stalled on the hill" if stalled else "Slow up the hill"
	if kind == "mud" and stalled:
		return "Stuck in the mud"
	if TITLES.has(kind):
		return TITLES[kind][pick]
	if index == 0:
		return "Slow off the line" if direction == "pull" else "Topped out early"
	return "Slow to speed up" if direction == "pull" else "Topped out on the flat"


static func _body(ratio: float, direction: String, stalled: bool) -> String:
	var r := "%s : 1" % _fmt(ratio)
	if direction == "pull":
		if stalled:
			return "A %s ratio spins fast but cannot pull through here. A bigger ratio pulls harder." % r
		return "A %s ratio did not pull hard enough. A bigger ratio pulls harder." % r
	return "A %s ratio pulls hard but the wheels top out. A smaller ratio is faster." % r


## Nudge the ratio (double it after a stall, else half again) and snap to
## the nearest gear pair. This is a hint, not the answer.
static func _suggested_ratio(ratio: float, direction: String, stalled: bool) -> float:
	var target := ratio / 1.5
	if direction == "pull":
		target = ratio * (2.0 if stalled else 1.5)
	var pair := nearest_gears(target)
	return Drivetrain.ratio_of(pair[0], pair[1])


## The gear pair nearest to a ratio. Pass owned lists to stay within what the
## player has found; they default to every gear in the game.
static func nearest_gears(target_ratio: float, motors: Array = Drivetrain.MOTOR_GEARS, wheels: Array = Drivetrain.WHEEL_GEARS) -> Array:
	var best_pair := [motors[0], wheels[0]]
	var best_gap := INF
	for m in motors:
		for w in wheels:
			var gap := absf(Drivetrain.ratio_of(m, w) - target_ratio)
			if gap < best_gap:
				best_gap = gap
				best_pair = [m, w]
	return best_pair


static func _fmt(ratio: float) -> String:
	if is_equal_approx(ratio, roundf(ratio)):
		return str(int(ratio))
	return "%.1f" % ratio


static func format_ratio(ratio: float) -> String:
	return "%s : 1" % _fmt(ratio)


static func format_time(seconds: float) -> String:
	var whole := int(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]
