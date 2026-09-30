extends RefCounted
## Deterministic drivetrain and course simulation.
##
## A DC motor turns the motor gear. The motor gear turns the wheel gear.
## The ratio is wheel teeth / motor teeth: a bigger ratio gives the wheels
## more pull (torque) but a lower top speed. The whole race is simulated
## with a fixed time step so the same build always gives the same result.

const G := 9.8
const MASS := 10.0
const WHEEL_R := 0.3
const MOTOR_T0 := 7.0    # stall torque, N*m
const MOTOR_W0 := 450.0  # no-load speed, rad/s
const ROLL := 0.03
const DRAG := 0.10
const DT := 1.0 / 60.0
const MAX_TIME := 60.0

const MOTOR_GEARS := [8, 12, 16, 20]
const WHEEL_GEARS := [16, 24, 32, 40, 48, 56]

## Course segments: [length along the track in metres, slope in degrees].
const COURSE := [[200.0, 0.0], [120.0, 22.0], [200.0, 0.0]]
const SEGMENT_NAMES := ["the start", "the hill", "the flat"]

## The rival always drives this ratio. It finishes in about 32.1 s.
const RIVAL_RATIO := 3.3

static var _best_cache: Dictionary = {}
static var _rival_cache: Dictionary = {}


static func ratio_of(motor_teeth: int, wheel_teeth: int) -> float:
	return float(wheel_teeth) / float(motor_teeth)


static func course_length() -> float:
	var total := 0.0
	for seg in COURSE:
		total += seg[0]
	return total


static func segment_end(index: int) -> float:
	var total := 0.0
	for i in range(index + 1):
		total += COURSE[i][0]
	return total


static func segment_at(x: float) -> int:
	var a := 0.0
	for i in COURSE.size():
		a += COURSE[i][0]
		if x < a:
			return i
	return COURSE.size() - 1


static func slope_deg_at(x: float) -> float:
	return COURSE[segment_at(x)][1]


## Relative scores (0 to 100) shown in the Garage. They always add to 100.
static func torque_score(ratio: float) -> int:
	return int(round(100.0 * ratio / (ratio + 1.0)))


static func speed_score(ratio: float) -> int:
	return 100 - torque_score(ratio)


## Run one race at a fixed ratio. Returns:
## finished (bool), time (float), xs / vs (PackedFloat32Array per step),
## seg_enter (Array of times the car entered each segment, then the finish),
## seg_durations (Array of seconds spent in each segment).
static func simulate(ratio: float) -> Dictionary:
	var x := 0.0
	var v := 0.0
	var t := 0.0
	var total := course_length()
	var xs := PackedFloat32Array([0.0])
	var vs := PackedFloat32Array([0.0])
	var seg_enter: Array = [0.0]
	var next_bound := 0
	while x < total and t < MAX_TIME:
		var th := deg_to_rad(slope_deg_at(x))
		var wm := maxf(0.0, v / WHEEL_R * ratio)
		var tm := maxf(0.0, MOTOR_T0 * (1.0 - wm / MOTOR_W0))
		var force := ratio * tm / WHEEL_R
		var resist := MASS * G * sin(th) + ROLL * MASS * G * cos(th) + DRAG * v * v
		var a := (force - resist) / MASS
		if v <= 0.0 and a < 0.0:
			a = 0.0
		v = maxf(0.0, v + a * DT)
		x += v * DT
		t += DT
		xs.append(x)
		vs.append(v)
		while next_bound < COURSE.size() and x >= segment_end(next_bound):
			seg_enter.append(t)
			next_bound += 1
	var finished := x >= total
	var durations: Array = []
	for i in COURSE.size():
		if i >= seg_enter.size():
			durations.append(0.0)  # never reached
		elif i + 1 < seg_enter.size():
			durations.append(seg_enter[i + 1] - seg_enter[i])
		else:
			durations.append(t - seg_enter[i])  # still in it when time ran out
	return {
		"ratio": ratio,
		"finished": finished,
		"time": t,
		"xs": xs,
		"vs": vs,
		"seg_enter": seg_enter,
		"seg_durations": durations,
	}


## The fastest combination of the gears the player can choose from.
static func best_build() -> Dictionary:
	if _best_cache.is_empty():
		var best_time := INF
		for m in MOTOR_GEARS:
			for w in WHEEL_GEARS:
				var r := simulate(ratio_of(m, w))
				if r["finished"] and r["time"] < best_time:
					best_time = r["time"]
					_best_cache = {"motor": m, "wheel": w, "ratio": ratio_of(m, w), "result": r}
	return _best_cache


static func rival_result() -> Dictionary:
	if _rival_cache.is_empty():
		_rival_cache = simulate(RIVAL_RATIO)
	return _rival_cache


## World height of the course (metres) at the given distance along the track.
## Used for drawing only. Returns Vector2(x_world, y_up).
static func world_point(s: float) -> Vector2:
	if s < 0.0:
		return Vector2(s, 0.0)  # flat run-up before the start line
	var wx := 0.0
	var wy := 0.0
	var a := 0.0
	for seg in COURSE:
		var len_seg: float = seg[0]
		var th := deg_to_rad(seg[1])
		var used := clampf(s - a, 0.0, len_seg)
		wx += used * cos(th)
		wy += used * sin(th)
		a += len_seg
	if s > a:
		wx += s - a  # flat run-out past the finish
	return Vector2(wx, wy)


## Star rating for a finished race: 0 = lost, 1 = beat the rival,
## 2 = beat the rival by a quarter second, 3 = within 0.2 s of the best build.
static func stars_for(time: float, finished: bool) -> int:
	if not finished or time > rival_result()["time"]:
		return 0
	var stars := 1
	if time <= rival_result()["time"] - 0.25:
		stars = 2
	if time <= best_build()["result"]["time"] + 0.2:
		stars = 3
	return stars
