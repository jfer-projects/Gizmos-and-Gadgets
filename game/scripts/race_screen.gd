extends Control
## Plays back a race that has already been simulated. The player does not
## steer: the build decides the race.

const TT = preload("res://scripts/tt.gd")
const Drivetrain = preload("res://scripts/drivetrain.gd")
const Analysis = preload("res://scripts/analysis.gd")

const PX_PER_M := 4.0
const CAR_UNIT := 0.9
const STALL_CUTOFF := 3.0  # seconds stuck on the hill before we stop watching

var main
var _t := 0.0
var _speed := 1.0
var _end_at := 0.0
var _done_at := -1.0
var _player: Dictionary
var _rival: Dictionary
var _time_label: Label
var _place_label: Label
var _speed_label: Label
var _banner: Label
var _ff: Button


func _ready() -> void:
	_player = main.result
	_rival = Drivetrain.rival_result()
	_end_at = _find_end_time()
	_time_label = TT.label("0:00.0", 26, TT.INK, true)
	_place_label = TT.label("1st", 26, TT.INK, true)
	_speed_label = TT.label("", 16, TT.MUTED, true)
	_banner = TT.label("", 30, TT.DANGER, true)
	_banner.visible = false
	var hud := HBoxContainer.new()
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 16
	hud.offset_top = 12
	hud.offset_right = -16
	hud.add_theme_constant_override("separation", 16)
	add_child(hud)
	hud.add_child(_pill(_place_label))
	hud.add_child(_pill(_time_label))
	hud.add_child(_pill(_speed_label))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(fill)
	_ff = TT.button("Fast", "plain")
	_ff.pressed.connect(_toggle_speed)
	hud.add_child(_ff)
	var skip := TT.button("Skip", "ghost")
	skip.pressed.connect(_finish)
	hud.add_child(skip)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_top = 96
	_banner.offset_left = -200
	_banner.offset_right = 200
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_banner)


func _pill(l: Label) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", TT.box(TT.RAISED, TT.INK, 24, 2, false))
	p.add_child(l)
	return p


func _toggle_speed() -> void:
	_speed = 3.0 if _speed == 1.0 else 1.0
	_ff.text = "Normal" if _speed > 1.0 else "Fast"


## Watching a stalled car for a minute is no fun: stop soon after it gives up.
func _find_end_time() -> float:
	var vs: PackedFloat32Array = _player["vs"]
	var xs: PackedFloat32Array = _player["xs"]
	if _player["finished"]:
		return maxf(_player["time"], _rival["time"]) + 0.5
	var slow := 0
	var need := int(STALL_CUTOFF / Drivetrain.DT)
	for k in vs.size():
		if vs[k] < 0.5 and Drivetrain.slope_deg_at(xs[k]) > 5.0:
			slow += 1
			if slow >= need:
				return k * Drivetrain.DT
		else:
			slow = 0
	return _player["time"]


func _process(delta: float) -> void:
	if _done_at >= 0.0:
		if Time.get_ticks_msec() / 1000.0 - _done_at > 1.6:
			_finish()
		return
	_t += delta * _speed
	if _t >= _end_at:
		_t = _end_at
		_done_at = Time.get_ticks_msec() / 1000.0
		if not _player["finished"]:
			_banner.text = "Stalled on the hill"
			_banner.visible = true
	_update_hud()
	queue_redraw()


func _finish() -> void:
	set_process(false)
	main.go("results")


func _sample(res: Dictionary, key: String) -> float:
	var arr: PackedFloat32Array = res[key]
	var i := clampi(int(_t / Drivetrain.DT), 0, arr.size() - 1)
	return arr[i]


func _update_hud() -> void:
	var px := _sample(_player, "xs")
	var rx := _sample(_rival, "xs")
	_place_label.text = "1st" if px >= rx else "2nd"
	_time_label.text = "%.1f s" % _t
	_speed_label.text = "%.0f km/h" % (_sample(_player, "vs") * 3.6)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), TT.BLUE_TINT)
	var px := _sample(_player, "xs")
	var cam := Drivetrain.world_point(px)
	var anchor := Vector2(size.x * 0.34, size.y * 0.66)
	# far hills, moving slower than the ground
	var far := PackedVector2Array([Vector2(0, size.y)])
	for i in range(0, int(size.x) + 24, 24):
		var wx := (float(i) + cam.x * PX_PER_M * 0.25)
		far.append(Vector2(i, size.y * 0.5 - 24.0 * sin(wx * 0.011) - 12.0 * sin(wx * 0.027)))
	far.append(Vector2(size.x, size.y))
	draw_colored_polygon(far, TT.TEAL_TINT)
	draw_polyline(far.slice(1, far.size() - 1), TT.INK, 2.0, true)
	# the ground
	var total := Drivetrain.course_length()
	var pts := PackedVector2Array()
	var s := maxf(0.0, px - anchor.x / PX_PER_M - 10.0)
	var s_end := minf(total + 40.0, px + (size.x - anchor.x) / PX_PER_M + 20.0)
	var last := Vector2.ZERO
	while s <= s_end:
		last = _to_screen(Drivetrain.world_point(s), cam, anchor)
		pts.append(last)
		s += 4.0
	if pts.size() >= 2:
		var poly := pts.duplicate()
		poly.append(Vector2(pts[pts.size() - 1].x, size.y + 10))
		poly.append(Vector2(pts[0].x, size.y + 10))
		draw_colored_polygon(poly, TT.BRAND_TINT)
		draw_polyline(pts, TT.INK, 3.0, true)
	# finish flag
	var fp := _to_screen(Drivetrain.world_point(total), cam, anchor)
	draw_line(fp, fp + Vector2(0, -70), TT.INK, 4.0)
	draw_rect(Rect2(fp + Vector2(0, -70), Vector2(34, 24)), TT.BRAND)
	draw_rect(Rect2(fp + Vector2(0, -70), Vector2(34, 24)), TT.INK, false, 2.5)
	# hill sign
	var hs := _to_screen(Drivetrain.world_point(Drivetrain.segment_end(0) + 20.0), cam, anchor)
	draw_string(TT.bold_font(), hs + Vector2(-6, 34), "HILL", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TT.MUTED)
	# rival and player cars
	_draw_car_on_track(_sample(_rival, "xs"), cam, anchor, TT.BLUE, 12, 40)
	_draw_car_on_track(px, cam, anchor, TT.BRAND, main.motor_teeth, main.wheel_teeth)
	# progress bar
	var bar := Rect2(size.x * 0.5 - 150, size.y - 26, 300, 12)
	draw_rect(bar, TT.RAISED)
	draw_rect(bar, TT.INK, false, 2.0)
	draw_circle(Vector2(bar.position.x + bar.size.x * clampf(_sample(_rival, "xs") / total, 0, 1), bar.position.y + 6), 8, TT.BLUE)
	draw_circle(Vector2(bar.position.x + bar.size.x * clampf(px / total, 0, 1), bar.position.y + 6), 8, TT.BRAND)
	draw_arc(Vector2(bar.position.x + bar.size.x * clampf(px / total, 0, 1), bar.position.y + 6), 8, 0, TAU, 16, TT.INK, 2.0)


func _to_screen(world: Vector2, cam: Vector2, anchor: Vector2) -> Vector2:
	return Vector2(anchor.x + (world.x - cam.x) * PX_PER_M, anchor.y - (world.y - cam.y) * PX_PER_M)


func _draw_car_on_track(s: float, cam: Vector2, anchor: Vector2, body: Color, m_teeth: int, w_teeth: int) -> void:
	var here := _to_screen(Drivetrain.world_point(s), cam, anchor)
	var deg := Drivetrain.slope_deg_at(s)
	var tilt := -deg_to_rad(deg)
	var spin := s * 0.6
	TT.draw_car(self, here, CAR_UNIT, tilt, body, spin, m_teeth, w_teeth)
