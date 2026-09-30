extends RefCounted
## Deterministic drivetrain and course simulation.
##
## A DC motor turns the motor gear. The motor gear turns the wheel gear.
## The ratio is wheel teeth / motor teeth: a bigger ratio gives the wheels
## more pull (torque) but a lower top speed. Every race is simulated with a
## fixed time step so the same build always gives the same result.

const G := 9.8
const MASS := 10.0
const WHEEL_R := 0.3
const MOTOR_T0 := 7.0    # stall torque, N*m
const MOTOR_W0 := 450.0  # no-load speed, rad/s
const DRAG := 0.10
const DT := 1.0 / 60.0
const MAX_TIME := 60.0

const MOTOR_GEARS := [8, 12, 16, 20]
const WHEEL_GEARS := [16, 24, 32, 40, 48, 56]

## Every course belongs to a vehicle family (ground, energy or air).
## A segment is a stretch of track:
##   kind   flat, hill, mud, down, cloud, head, tail, runway or air
##   len    metres along the track
##   slope  degrees (negative is downhill)
##   roll   rolling resistance (0.03 is normal, mud is much higher)
##   power  multiplier on motor torque (clouds, a winding-down spring)
##   wind   constant push in newtons; positive helps, negative is a headwind
##   drag   multiplier on air drag
##   takeoff  runway only: speed needed at the end of the segment or you crash
##   stall  air only: below this speed for a second and you fall
##   place  finishes the sentence "... [place]" in the loss notes
static var COURSES: Array = _build_courses()


static func _s(kind: String, length: float, place: String, extra: Dictionary = {}) -> Dictionary:
	var d := {"kind": kind, "len": length, "slope": 0.0, "roll": 0.03, "power": 1.0, "wind": 0.0, "drag": 1.0, "place": place}
	d.merge(extra, true)
	return d


## An air segment: no rolling resistance, thinner air, and a stall speed.
static func _air(length: float, place: String, extra: Dictionary = {}) -> Dictionary:
	var d := {"roll": 0.0, "drag": 0.5, "stall": 12.0}
	d.merge(extra, true)
	return _s("air", length, place, d)


static func _build_courses() -> Array:
	return [
		# ---- Ground -------------------------------------------------------
		{"id": "hill", "family": "ground", "name": "Hill Climb", "rival": 3.3, "drag": 1.0,
			"blurb": "A flat start, then a steep hill.",
			"segments": [_s("flat", 200, "at the start"), _s("hill", 120, "on the hill", {"slope": 22.0}), _s("flat", 200, "on the flat")]},
		{"id": "sprint", "family": "ground", "name": "Windy Straight", "rival": 3.05, "drag": 0.15,
			"blurb": "Almost no air drag. Long and fast.",
			"segments": [_s("flat", 100, "at the start"), _s("flat", 900, "on the straight")]},
		{"id": "ramp", "family": "ground", "name": "Ramp Yard", "rival": 2.95, "drag": 1.0,
			"blurb": "A short, very steep ramp, then a long downhill.",
			"segments": [_s("flat", 150, "at the start"), _s("hill", 40, "on the ramp", {"slope": 32.0}), _s("flat", 150, "after the ramp"), _s("down", 300, "on the downhill", {"slope": -12.0})]},
		{"id": "mud", "family": "ground", "name": "Mud Flats", "rival": 3.7, "drag": 1.0,
			"blurb": "Thick mud drags on your wheels.",
			"segments": [_s("flat", 80, "at the start"), _s("mud", 300, "in the mud", {"roll": 0.35}), _s("flat", 100, "after the mud")]},
		{"id": "pass", "family": "ground", "name": "Mountain Pass", "rival": 4.0, "drag": 1.0,
			"blurb": "Two climbs, and the second is steeper.",
			"segments": [_s("flat", 60, "at the start"), _s("hill", 120, "on the first climb", {"slope": 25.0}), _s("flat", 60, "between the climbs"), _s("hill", 120, "on the second climb", {"slope": 30.0}), _s("flat", 60, "at the top")]},
		# ---- Green energy -------------------------------------------------
		{"id": "solar", "family": "energy", "name": "Solar Roof", "rival": 3.3, "drag": 1.0,
			"blurb": "Solar power fades when clouds roll in.",
			"segments": [_s("flat", 100, "in the sun"), _s("cloud", 200, "in the clouds", {"power": 0.35}), _s("flat", 200, "back in the sun")]},
		{"id": "wind", "family": "energy", "name": "Windy Lane", "rival": 3.95, "drag": 1.0,
			"blurb": "A headwind, then a tailwind.",
			"segments": [_s("flat", 100, "at the start"), _s("head", 250, "into the wind", {"wind": -45.0}), _s("tail", 250, "with the wind behind you", {"wind": 45.0})]},
		{"id": "spring", "family": "energy", "name": "Spring Hill", "rival": 5.1, "drag": 1.0,
			"blurb": "A wind-up spring pushes hard at first, then fades.",
			"segments": [_s("flat", 60, "at the start"), _s("hill", 100, "on the first slope", {"slope": 14.0, "power": 0.8}), _s("hill", 100, "on the second slope", {"slope": 14.0, "power": 0.55}), _s("hill", 100, "on the last slope", {"slope": 14.0, "power": 0.35})]},
		{"id": "ridge", "family": "energy", "name": "Cloudy Ridge", "rival": 4.3, "drag": 1.0,
			"blurb": "A climb where the sun goes in.",
			"segments": [_s("flat", 80, "at the start"), _s("hill", 100, "on the sunny climb", {"slope": 18.0}), _s("cloud", 100, "on the cloudy climb", {"slope": 18.0, "power": 0.5}), _s("flat", 100, "on the ridge")]},
		{"id": "eco", "family": "energy", "name": "Eco Grand Prix", "rival": 3.95, "drag": 1.0,
			"blurb": "Sun, clouds, wind and hills, all in one race.",
			"segments": [_s("flat", 80, "at the start"), _s("head", 150, "into the wind", {"wind": -40.0}), _s("cloud", 120, "in the clouds", {"slope": 10.0, "power": 0.5}), _s("tail", 150, "with the wind behind you", {"wind": 40.0})]},
		# ---- Air ----------------------------------------------------------
		{"id": "runway", "family": "air", "name": "Runway Dash", "rival": 2.55, "drag": 1.0,
			"blurb": "Reach take-off speed before the runway ends.",
			"segments": [_s("runway", 200, "on the runway", {"takeoff": 17.0}), _air(500, "in the air")]},
		{"id": "short", "family": "air", "name": "Short Field", "rival": 2.5, "drag": 1.0,
			"blurb": "A short runway. You need to speed up fast.",
			"segments": [_s("runway", 120, "on the runway", {"takeoff": 17.0}), _air(450, "in the air")]},
		{"id": "headwind", "family": "air", "name": "Headwind Hop", "rival": 3.65, "drag": 1.0,
			"blurb": "A strong wind blows against you in the air.",
			"segments": [_s("runway", 220, "on the runway", {"takeoff": 18.0}), _air(600, "in the air", {"wind": -40.0})]},
		{"id": "canyon", "family": "air", "name": "Canyon Run", "rival": 2.65, "drag": 1.0,
			"blurb": "Gusts push you around between the canyon walls.",
			"segments": [_s("runway", 200, "on the runway", {"takeoff": 17.0}), _air(250, "in the tail gust", {"wind": 40.0}), _air(250, "in the crosswind", {"drag": 1.4})]},
		{"id": "grand", "family": "air", "name": "Grand Air Race", "rival": 3.05, "drag": 1.0,
			"blurb": "A short runway, a headwind and a long final leg.",
			"segments": [_s("runway", 150, "on the runway", {"takeoff": 18.0}), _air(250, "in the headwind", {"wind": -35.0}), _air(350, "on the final leg")]},
	]

static var _best_cache: Dictionary = {}
static var _rival_cache: Dictionary = {}


static func family_of(ci: int) -> String:
	return COURSES[ci]["family"]


static func course_count() -> int:
	return COURSES.size()


static func segments(ci: int) -> Array:
	return COURSES[ci]["segments"]


static func ratio_of(motor_teeth: int, wheel_teeth: int) -> float:
	return float(wheel_teeth) / float(motor_teeth)


static func course_length(ci: int) -> float:
	var total := 0.0
	for seg in segments(ci):
		total += seg["len"]
	return total


static func segment_end(ci: int, index: int) -> float:
	var total := 0.0
	var segs := segments(ci)
	for i in range(index + 1):
		total += segs[i]["len"]
	return total


static func segment_start(ci: int, index: int) -> float:
	return segment_end(ci, index) - float(segments(ci)[index]["len"])


static func segment_at(ci: int, x: float) -> int:
	var a := 0.0
	var segs := segments(ci)
	for i in segs.size():
		a += segs[i]["len"]
		if x < a:
			return i
	return segs.size() - 1


static func slope_deg_at(ci: int, x: float) -> float:
	return segments(ci)[segment_at(ci, x)]["slope"]


## Relative scores (0 to 100) shown in the Garage. They always add to 100.
static func torque_score(ratio: float) -> int:
	return int(round(100.0 * ratio / (ratio + 1.0)))


static func speed_score(ratio: float) -> int:
	return 100 - torque_score(ratio)


## Run one race at a fixed ratio. Returns:
## course, ratio, finished (bool), fail ("", "stall" or "crash"), crash_segment,
## time (float), xs / vs (PackedFloat32Array per step), seg_enter (times the
## car entered each segment, then the finish), seg_durations (seconds spent in
## each segment).
static func simulate(ci: int, ratio: float) -> Dictionary:
	var x := 0.0
	var v := 0.0
	var t := 0.0
	var total := course_length(ci)
	var segs := segments(ci)
	var course_drag: float = DRAG * float(COURSES[ci]["drag"])
	var xs := PackedFloat32Array([0.0])
	var vs := PackedFloat32Array([0.0])
	var seg_enter: Array = [0.0]
	var next_bound := 0
	var seg := 0
	var crashed := false
	var crash_segment := -1
	var slow_in_air := 0.0
	while x < total and t < MAX_TIME:
		var s: Dictionary = segs[seg]
		var th := deg_to_rad(s["slope"])
		var wm := maxf(0.0, v / WHEEL_R * ratio)
		var tm := maxf(0.0, MOTOR_T0 * (1.0 - wm / MOTOR_W0)) * float(s["power"])
		var force := ratio * tm / WHEEL_R + float(s["wind"])
		var resist := MASS * G * sin(th) + float(s["roll"]) * MASS * G * cos(th) + course_drag * float(s["drag"]) * v * v
		var a := (force - resist) / MASS
		if v <= 0.0 and a < 0.0:
			a = 0.0
		v = maxf(0.0, v + a * DT)
		x += v * DT
		t += DT
		xs.append(x)
		vs.append(v)
		while next_bound < segs.size() and x >= segment_end(ci, next_bound):
			# leaving a runway too slowly means no take-off
			if segs[next_bound].has("takeoff") and v < float(segs[next_bound]["takeoff"]):
				crashed = true
				crash_segment = next_bound
			seg_enter.append(t)
			next_bound += 1
		if crashed:
			break
		seg = mini(next_bound, segs.size() - 1)
		# in the air, dropping below stall speed for a second means falling
		if s.has("stall") and x < total:
			slow_in_air = slow_in_air + DT if v < float(s["stall"]) else 0.0
			if slow_in_air > 1.0:
				crashed = true
				crash_segment = seg
				break
	var finished := x >= total and not crashed
	var durations: Array = []
	for i in segs.size():
		if i >= seg_enter.size():
			durations.append(0.0)  # never reached
		elif i + 1 < seg_enter.size():
			durations.append(seg_enter[i + 1] - seg_enter[i])
		else:
			durations.append(t - seg_enter[i])  # still in it when the race ended
	return {
		"course": ci,
		"ratio": ratio,
		"finished": finished,
		"fail": "" if finished else ("crash" if crashed else "stall"),
		"crash_segment": crash_segment,
		"time": t,
		"xs": xs,
		"vs": vs,
		"seg_enter": seg_enter,
		"seg_durations": durations,
	}


## The fastest combination of all gears in the game (not only the ones owned).
static func best_build(ci: int) -> Dictionary:
	if not _best_cache.has(ci):
		var best_time := INF
		var best: Dictionary = {}
		for m in MOTOR_GEARS:
			for w in WHEEL_GEARS:
				var r := simulate(ci, ratio_of(m, w))
				if r["finished"] and r["time"] < best_time:
					best_time = r["time"]
					best = {"motor": m, "wheel": w, "ratio": ratio_of(m, w), "result": r}
		_best_cache[ci] = best
	return _best_cache[ci]


static func rival_result(ci: int) -> Dictionary:
	if not _rival_cache.has(ci):
		_rival_cache[ci] = simulate(ci, COURSES[ci]["rival"])
	return _rival_cache[ci]


## World point of the course (metres) at a distance along the track.
## Returns Vector2(x_world, y_up). Used for drawing only.
static func world_point(ci: int, s: float) -> Vector2:
	if s < 0.0:
		return Vector2(s, 0.0)  # flat run-up before the start line
	var wx := 0.0
	var wy := 0.0
	var a := 0.0
	for seg in segments(ci):
		var len_seg: float = seg["len"]
		var th := deg_to_rad(seg["slope"])
		var used := clampf(s - a, 0.0, len_seg)
		wx += used * cos(th)
		wy += used * sin(th)
		a += len_seg
	if s > a:
		wx += s - a  # flat run-out past the finish
	return Vector2(wx, wy)


## Star rating: 0 = lost, 1 = beat the rival, 2 = beat the rival by a
## quarter second, 3 = within 0.2 s of the best build.
static func stars_for(ci: int, time: float, finished: bool) -> int:
	var rival_time: float = rival_result(ci)["time"]
	if not finished or time > rival_time:
		return 0
	var stars := 1
	if time <= rival_time - 0.25:
		stars = 2
	if time <= best_build(ci)["result"]["time"] + 0.2:
		stars = 3
	return stars
