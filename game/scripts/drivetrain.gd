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

## Segment kinds: flat, hill (stalls are possible), mud (stalls are possible), down.
## len is metres along the track, slope is degrees, roll is rolling resistance.
## "place" finishes the sentence "... [place]" in the loss notes.
const COURSES := [
	{
		"id": "hill", "name": "Hill Climb", "rival": 3.3, "drag": 1.0,
		"blurb": "A flat start, then a steep hill.",
		"segments": [
			{"kind": "flat", "len": 200.0, "slope": 0.0, "roll": 0.03, "place": "at the start"},
			{"kind": "hill", "len": 120.0, "slope": 22.0, "roll": 0.03, "place": "on the hill"},
			{"kind": "flat", "len": 200.0, "slope": 0.0, "roll": 0.03, "place": "on the flat"},
		],
	},
	{
		"id": "sprint", "name": "Windy Straight", "rival": 3.05, "drag": 0.15,
		"blurb": "Almost no air drag. Long and fast.",
		"segments": [
			{"kind": "flat", "len": 100.0, "slope": 0.0, "roll": 0.03, "place": "at the start"},
			{"kind": "flat", "len": 900.0, "slope": 0.0, "roll": 0.03, "place": "on the straight"},
		],
	},
	{
		"id": "ramp", "name": "Ramp Yard", "rival": 2.95, "drag": 1.0,
		"blurb": "A short, very steep ramp, then a long downhill.",
		"segments": [
			{"kind": "flat", "len": 150.0, "slope": 0.0, "roll": 0.03, "place": "at the start"},
			{"kind": "hill", "len": 40.0, "slope": 32.0, "roll": 0.03, "place": "on the ramp"},
			{"kind": "flat", "len": 150.0, "slope": 0.0, "roll": 0.03, "place": "after the ramp"},
			{"kind": "down", "len": 300.0, "slope": -12.0, "roll": 0.03, "place": "on the downhill"},
		],
	},
	{
		"id": "mud", "name": "Mud Flats", "rival": 3.7, "drag": 1.0,
		"blurb": "Thick mud drags on your wheels.",
		"segments": [
			{"kind": "flat", "len": 80.0, "slope": 0.0, "roll": 0.03, "place": "at the start"},
			{"kind": "mud", "len": 300.0, "slope": 0.0, "roll": 0.35, "place": "in the mud"},
			{"kind": "flat", "len": 100.0, "slope": 0.0, "roll": 0.03, "place": "after the mud"},
		],
	},
	{
		"id": "pass", "name": "Mountain Pass", "rival": 4.0, "drag": 1.0,
		"blurb": "Two climbs, and the second is steeper.",
		"segments": [
			{"kind": "flat", "len": 60.0, "slope": 0.0, "roll": 0.03, "place": "at the start"},
			{"kind": "hill", "len": 120.0, "slope": 25.0, "roll": 0.03, "place": "on the first climb"},
			{"kind": "flat", "len": 60.0, "slope": 0.0, "roll": 0.03, "place": "between the climbs"},
			{"kind": "hill", "len": 120.0, "slope": 30.0, "roll": 0.03, "place": "on the second climb"},
			{"kind": "flat", "len": 60.0, "slope": 0.0, "roll": 0.03, "place": "at the top"},
		],
	},
]

static var _best_cache: Dictionary = {}
static var _rival_cache: Dictionary = {}


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
## course, ratio, finished (bool), time (float), xs / vs (PackedFloat32Array
## per step), seg_enter (times the car entered each segment, then the finish),
## seg_durations (seconds spent in each segment).
static func simulate(ci: int, ratio: float) -> Dictionary:
	var x := 0.0
	var v := 0.0
	var t := 0.0
	var total := course_length(ci)
	var segs := segments(ci)
	var drag: float = DRAG * float(COURSES[ci]["drag"])
	var xs := PackedFloat32Array([0.0])
	var vs := PackedFloat32Array([0.0])
	var seg_enter: Array = [0.0]
	var next_bound := 0
	var seg := 0
	while x < total and t < MAX_TIME:
		var s: Dictionary = segs[seg]
		var th := deg_to_rad(s["slope"])
		var wm := maxf(0.0, v / WHEEL_R * ratio)
		var tm := maxf(0.0, MOTOR_T0 * (1.0 - wm / MOTOR_W0))
		var force := ratio * tm / WHEEL_R
		var resist := MASS * G * sin(th) + float(s["roll"]) * MASS * G * cos(th) + drag * v * v
		var a := (force - resist) / MASS
		if v <= 0.0 and a < 0.0:
			a = 0.0
		v = maxf(0.0, v + a * DT)
		x += v * DT
		t += DT
		xs.append(x)
		vs.append(v)
		while next_bound < segs.size() and x >= segment_end(ci, next_bound):
			seg_enter.append(t)
			next_bound += 1
		seg = mini(next_bound, segs.size() - 1)
	var finished := x >= total
	var durations: Array = []
	for i in segs.size():
		if i >= seg_enter.size():
			durations.append(0.0)  # never reached
		elif i + 1 < seg_enter.size():
			durations.append(seg_enter[i + 1] - seg_enter[i])
		else:
			durations.append(t - seg_enter[i])  # still in it when time ran out
	return {
		"course": ci,
		"ratio": ratio,
		"finished": finished,
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
