extends RefCounted
## Turns a finished (or failed) race into plain-language "Why did I lose?" notes.

const Drivetrain = preload("res://scripts/drivetrain.gd")

const MIN_LOSS_SECONDS := 0.2
const STALL_SPEED := 1.0
const STALL_SECONDS := 2.0


## Returns up to two notes, biggest time loss first. Each note is a Dictionary:
## time (float, when it happened), place (String), title, body,
## direction ("pull" or "speed"), suggested_ratio (float).
static func explain(result: Dictionary) -> Array:
	var best: Dictionary = Drivetrain.best_build()
	var best_result: Dictionary = best["result"]
	var ratio: float = result["ratio"]
	var notes: Array = []
	for i in Drivetrain.COURSE.size():
		var mine: float = result["seg_durations"][i]
		var theirs: float = best_result["seg_durations"][i]
		var reached: bool = i < result["seg_enter"].size()
		if not reached:
			continue
		var loss := mine - theirs
		if loss < MIN_LOSS_SECONDS:
			continue
		var stalled := _stalled_in_segment(result, i)
		var direction := "pull" if ratio < best["ratio"] else "speed"
		notes.append({
			"segment": i,
			"stalled": stalled,
			"loss": loss,
			"time": result["seg_enter"][i],
			"place": _place_text(i),
			"title": _title(i, direction, stalled),
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


static func _stalled_in_segment(result: Dictionary, seg: int) -> bool:
	var xs: PackedFloat32Array = result["xs"]
	var vs: PackedFloat32Array = result["vs"]
	var slow_steps := 0
	var needed := int(STALL_SECONDS / Drivetrain.DT)
	var start_x: float = Drivetrain.segment_end(seg) - float(Drivetrain.COURSE[seg][0])
	var end_x := Drivetrain.segment_end(seg)
	for k in xs.size():
		if xs[k] >= start_x and xs[k] < end_x and Drivetrain.slope_deg_at(xs[k]) > 5.0 and vs[k] < STALL_SPEED:
			slow_steps += 1
			if slow_steps >= needed:
				return true
	return false


static func _place_text(seg: int) -> String:
	return ["at the start", "on the hill", "on the flat"][seg]


static func _title(seg: int, direction: String, stalled: bool) -> String:
	if seg == 1:
		return "Stalled on the hill" if stalled else "Slow up the hill"
	if seg == 0:
		return "Slow off the line" if direction == "pull" else "Topped out early"
	return "Slow after the hill" if direction == "pull" else "Topped out on the flat"


static func _body(ratio: float, direction: String, stalled: bool) -> String:
	var r := "%s : 1" % _fmt(ratio)
	if direction == "pull":
		if stalled:
			return "A %s ratio spins fast but cannot pull up a steep hill. A bigger ratio pulls harder." % r
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


static func nearest_gears(target_ratio: float) -> Array:
	var best_pair := [Drivetrain.MOTOR_GEARS[0], Drivetrain.WHEEL_GEARS[0]]
	var best_gap := INF
	for m in Drivetrain.MOTOR_GEARS:
		for w in Drivetrain.WHEEL_GEARS:
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
