extends Control
## The picture for a crate puzzle. It shows the player's current choice and,
## once `reveal` is set, what that choice does, so the answer can be seen and
## not only read.

const TT = preload("res://scripts/tt.gd")
const Puzzles = preload("res://scripts/puzzles.gd")

const NONE := -999

var puzzle: Dictionary
var choice: int = NONE
var reveal := false

var _t := 0.0    # clock for spinning things
var _rt := 0.0   # 0 to 1 after reveal, for things that move once
var _k := 1.0    # drawing scale, so wide pictures still fit when the answer panel opens
var _vs := Vector2.ZERO  # the drawing space size (the control size divided by _k)


func _process(delta: float) -> void:
	if TT.motion or reveal:
		_t += delta
	_rt = minf(_rt + delta / 1.2, 1.0) if reveal else 0.0
	queue_redraw()


func _draw() -> void:
	draw_style_box(TT.box(TT.RAISED, TT.INK, 20, 2, true), Rect2(Vector2.ZERO, size - Vector2(0, 4)))
	var kind: String = puzzle["kind"]
	if kind == "direction" or kind == "speed" or kind == "ratio":
		_k = 1.0
		_vs = size
		_draw_gears()
		return
	_k = clampf(size.x / 640.0, 0.5, 1.0)
	_vs = size / _k
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_k, _k))
	match kind:
		"circuit":
			_draw_circuit()
		"energy":
			_draw_energy()
		"magnet":
			_draw_magnets()
		"balance":
			_draw_balance()
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _label(pos: Vector2, text: String, size_px: int = 16, color: Color = TT.INK) -> void:
	draw_string(TT.bold_font(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)


func _centered(y: float, text: String, size_px: int = 18, color: Color = TT.INK) -> void:
	var w := TT.bold_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	_label(Vector2((_vs.x - w) * 0.5, y), text, size_px, color)


# --- gears -------------------------------------------------------------------

## Teeth of each gear in the row, driver first.
func chain() -> Array:
	match puzzle["kind"]:
		"direction":
			var n := 0 if choice == NONE else choice
			var row: Array = [12]
			for i in n:
				row.append(12)
			row.append(12)
			return row
		"speed":
			return [puzzle["driver"], choice if choice != NONE else 0]
		"ratio":
			return [puzzle["motor"], choice if choice != NONE else 0]
	return []


func _draw_gears() -> void:
	var teeth: Array = chain()
	var unit := 3.2 if puzzle["kind"] == "direction" else 1.5
	var width := 0.0
	for i in teeth.size():
		var r := float(teeth[i]) * unit
		width += r * 2.0 - (3.0 if i > 0 else 0.0)
	var x := (size.x - width) * 0.5
	var cy := size.y * 0.4
	var prev_angle := _t * 1.2
	var prev_teeth := 0
	for i in teeth.size():
		var t: int = teeth[i]
		var r := float(t) * unit
		var is_last := i == teeth.size() - 1
		var col: Color = TT.TEAL if i == 0 else (TT.BRAND if is_last else TT.BLUE_TINT)
		if t == 0:
			# the empty slot: a dashed ring where the chosen gear will go
			var ghost := 24.0 * unit
			var c := Vector2(x + ghost, cy)
			for k in 24:
				draw_arc(c, ghost, TAU * k / 24.0, TAU * (k + 0.5) / 24.0, 6, TT.BORDER, 3.0)
			_label(c + Vector2(-8, 8), "?", 26, TT.MUTED)
			continue
		var center := Vector2(x + r, cy)
		var angle := _t * 1.2 if i == 0 else PI + PI / float(t) - prev_angle * float(prev_teeth) / float(t)
		var dir := 1 if i % 2 == 0 else -1
		TT.draw_gear(self, center, r, t, angle, col, "%dT" % t if puzzle["kind"] != "direction" else "")
		if reveal or i == 0:
			_arrow(center, r * 0.55, dir)
		if puzzle["kind"] == "direction":
			var tag := "MOTOR" if i == 0 else ("WHEEL" if is_last else "IDLER")
			_label(Vector2(center.x - 24, cy + r + 20), tag, 13, TT.MUTED)
		prev_angle = angle
		prev_teeth = t
		x += r * 2.0 - 3.0
	if reveal and puzzle["kind"] != "direction" and choice != NONE:
		var rpm := 60.0 * float(teeth[0]) / float(teeth[1])
		_label(Vector2(16, 30), "Driver 60 rpm  →  output %d rpm" % int(round(rpm)))


## A curved arrow showing which way a gear turns (1 = clockwise).
func _arrow(c: Vector2, r: float, dir: int) -> void:
	var pts := PackedVector2Array()
	for k in range(0, 13):
		var a := lerpf(-PI * 0.85, -PI * 0.15, k / 12.0)
		pts.append(c + Vector2.from_angle(a) * r)
	if dir < 0:
		pts.reverse()
	draw_polyline(pts, TT.INK, 3.0, true)
	var tip: Vector2 = pts[pts.size() - 1]
	var back: Vector2 = pts[pts.size() - 3]
	var d := (tip - back).normalized()
	var n := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([tip + d * 7.0, tip - d * 3.0 + n * 6.0, tip - d * 3.0 - n * 6.0]), TT.INK)


# --- circuits ----------------------------------------------------------------

func _bulb(c: Vector2, brightness: float) -> void:
	var glow := TT.SUNKEN.lerp(TT.BRAND, brightness)
	if brightness > 0.0:
		for k in 8:
			var a := TAU * k / 8.0
			var reach := 10.0 + 14.0 * brightness
			draw_line(c + Vector2.from_angle(a) * 20.0, c + Vector2.from_angle(a) * (20.0 + reach), TT.BRAND, 3.0)
	draw_circle(c, 17.0, glow)
	draw_arc(c, 17.0, 0.0, TAU, 20, TT.INK, 2.5, true)
	draw_line(c + Vector2(-7, 5), c + Vector2(7, -5), TT.INK, 2.0)
	draw_line(c + Vector2(-7, -5), c + Vector2(7, 5), TT.INK, 2.0)


func _draw_circuit() -> void:
	var cx := _vs.x * 0.5
	var cy := _vs.y * 0.42
	var x0 := cx - 150.0
	var x1 := cx + 150.0
	var top := cy - 48.0
	var bot := cy + 48.0
	# battery on the left wire
	draw_line(Vector2(x0, top), Vector2(x0, cy - 12), TT.INK, 3.0)
	draw_line(Vector2(x0, cy + 12), Vector2(x0, bot), TT.INK, 3.0)
	draw_line(Vector2(x0 - 16, cy - 12), Vector2(x0 + 16, cy - 12), TT.INK, 4.0)
	draw_line(Vector2(x0 - 9, cy + 12), Vector2(x0 + 9, cy + 12), TT.INK, 4.0)
	_label(Vector2(x0 - 62, cy + 5), "Battery", 13, TT.MUTED)
	if choice == NONE:
		_centered(cy + 6, "Pick a way to wire the bulbs", 18, TT.MUTED)
		return
	var bright: float = Puzzles.outcome(puzzle, choice)["brightness"] if reveal else 0.0
	var wire := TT.INK
	if choice == 1:
		# parallel: two rails with a bulb on each branch
		draw_line(Vector2(x0, top), Vector2(x1, top), wire, 3.0)
		draw_line(Vector2(x0, bot), Vector2(x1, bot), wire, 3.0)
		for bx in [cx - 60.0, cx + 60.0]:
			draw_line(Vector2(bx, top), Vector2(bx, cy - 17), wire, 3.0)
			draw_line(Vector2(bx, cy + 17), Vector2(bx, bot), wire, 3.0)
			_bulb(Vector2(bx, cy), bright)
		draw_line(Vector2(x1, top), Vector2(x1, bot), wire, 3.0)
	else:
		# series: both bulbs on the top wire; choice 2 leaves a gap
		draw_line(Vector2(x0, top), Vector2(cx - 90, top), wire, 3.0)
		_bulb(Vector2(cx - 60.0, top), bright)
		if choice == 2:
			draw_line(Vector2(cx - 43, top), Vector2(cx - 8, top), wire, 3.0)
			draw_line(Vector2(cx + 8, top - 14), Vector2(cx + 8, top + 14), TT.DANGER, 4.0)
			draw_line(Vector2(cx + 20, top), Vector2(cx + 43, top), wire, 3.0)
		else:
			draw_line(Vector2(cx - 43, top), Vector2(cx + 43, top), wire, 3.0)
		_bulb(Vector2(cx + 60.0, top), bright)
		draw_line(Vector2(cx + 77, top), Vector2(x1, top), wire, 3.0)
		draw_line(Vector2(x1, top), Vector2(x1, bot), wire, 3.0)
		draw_line(Vector2(x0, bot), Vector2(x1, bot), wire, 3.0)
	if reveal:
		var word := "bright" if bright >= 1.0 else ("dim" if bright > 0.0 else "dark")
		_centered(_vs.y - 24.0, "The bulbs are %s" % word, 18)


# --- energy ------------------------------------------------------------------

func _draw_energy() -> void:
	var sky := Rect2(16, 16, _vs.x - 32, _vs.y - 60)
	var night: bool = puzzle.get("night", false)
	draw_rect(sky, Color("#10243E") if night else TT.BLUE_TINT)
	if night:
		draw_circle(Vector2(sky.position.x + 60, sky.position.y + 50), 24, Color("#F4EFD0"))
		draw_circle(Vector2(sky.position.x + 72, sky.position.y + 44), 22, Color("#10243E"))
		for p in [Vector2(140, 40), Vector2(230, 90), Vector2(330, 36), Vector2(450, 70), Vector2(560, 44), Vector2(660, 90)]:
			draw_circle(sky.position + p, 2.5, Color("#F4EFD0"))
	else:
		draw_circle(Vector2(sky.position.x + 60, sky.position.y + 50), 26, TT.BRAND)
	if puzzle.get("wind", false):
		for row in 3:
			var y := sky.position.y + 70 + row * 26
			var x := sky.position.x + 180 + fposmod(_t * 90.0 + row * 60.0, 420.0)
			draw_line(Vector2(x, y), Vector2(x + 50, y), Color("#DCE7FB"), 3.0)
	var base := Vector2(_vs.x * 0.5, sky.end.y)
	if choice == NONE:
		_label(base + Vector2(-80, -40), "Pick a power source", 18, Color("#DCE7FB") if night else TT.MUTED)
		return
	var power: float = Puzzles.outcome(puzzle, choice)["power"] if reveal else 0.0
	match choice:
		0:
			draw_colored_polygon(PackedVector2Array([base + Vector2(-50, 0), base + Vector2(50, 0), base + Vector2(36, -42), base + Vector2(-36, -42)]), TT.TEAL if power > 0.0 else TT.MUTED)
			draw_polyline(PackedVector2Array([base + Vector2(-50, 0), base + Vector2(50, 0), base + Vector2(36, -42), base + Vector2(-36, -42), base + Vector2(-50, 0)]), TT.INK, 2.5)
			for k in range(1, 4):
				draw_line(base + Vector2(-50 + k * 25.0, 0) + Vector2(0, 0), base + Vector2(-36 + k * 18.0, -42), TT.ON_TEAL, 1.5)
		1:
			draw_line(base, base + Vector2(0, -80), Color("#F4EFD0") if night else TT.INK, 5.0)
			var hub := base + Vector2(0, -80)
			for k in 3:
				var a := TAU * k / 3.0 + _t * 4.0 * power
				draw_line(hub, hub + Vector2.from_angle(a) * 40.0, Color("#F4EFD0") if night else TT.INK, 6.0)
			draw_circle(hub, 6, TT.BRAND)
		2:
			_label(base + Vector2(-100, -30), "Zzz... waiting for morning", 20, Color("#DCE7FB"))
	if reveal:
		_centered(_vs.y - 22.0, "Power: %d%%" % int(power * 100.0), 20)


# --- magnets -----------------------------------------------------------------

func _magnet(rect: Rect2, left_pole: String) -> void:
	var right_pole := "S" if left_pole == "N" else "N"
	var half := rect.size.x * 0.5
	for i in 2:
		var pole := left_pole if i == 0 else right_pole
		var r := Rect2(rect.position + Vector2(half * i, 0), Vector2(half, rect.size.y))
		draw_rect(r, TT.DANGER if pole == "N" else TT.BLUE)
		_label(r.position + Vector2(half * 0.5 - 8, rect.size.y * 0.5 + 9), pole, 26, TT.ON_DANGER if pole == "N" else TT.ON_BLUE)
	draw_rect(rect, TT.INK, false, 3.0)


func _draw_magnets() -> void:
	var cy := _vs.y * 0.4
	var w := 150.0
	var gap := 120.0
	var left := Rect2(_vs.x * 0.5 - gap * 0.5 - w, cy - 24, w, 48)
	_magnet(left, "N")
	if choice == NONE:
		var ghost := Rect2(_vs.x * 0.5 + gap * 0.5, cy - 24, w, 48)
		draw_rect(ghost, TT.BORDER, false, 3.0)
		_label(ghost.position + Vector2(w * 0.5 - 8, 33), "?", 26, TT.MUTED)
		return
	var attract: bool = Puzzles.outcome(puzzle, choice)["attract"]
	var shift := 0.0
	if reveal:
		# pulled in until they touch, or pushed away
		shift = -(gap - 4.0) * _rt if attract else 80.0 * _rt
	var right := Rect2(_vs.x * 0.5 + gap * 0.5 + shift, cy - 24, w, 48)
	_magnet(right, "N" if choice == 0 else "S")
	if reveal and _rt > 0.9:
		_centered(_vs.y - 24.0, "They pull together" if attract else "They push apart", 20)


# --- lever -------------------------------------------------------------------

func _draw_balance() -> void:
	var pivot := Vector2(_vs.x * 0.5, _vs.y * 0.66)
	var step := 34.0
	var tilt := 0.0
	var tl := 0
	var tr := 0
	if choice != NONE:
		var o := Puzzles.outcome(puzzle, choice)
		tl = o["torque_l"]
		tr = o["torque_r"]
		if reveal:
			tilt = clampf(float(tr - tl) / float(maxi(maxi(tl, tr), 1)), -1.0, 1.0) * 0.28 * _rt
	# stand
	draw_colored_polygon(PackedVector2Array([pivot + Vector2(-26, 46), pivot + Vector2(26, 46), pivot + Vector2(0, 0)]), TT.SUNKEN)
	draw_polyline(PackedVector2Array([pivot + Vector2(-26, 46), pivot + Vector2(0, 0), pivot + Vector2(26, 46)]), TT.INK, 3.0)
	draw_set_transform(pivot * _k, tilt, Vector2(_k, _k))
	draw_rect(Rect2(-8.0 * step, -8, 16.0 * step, 8), TT.BRAND)
	draw_rect(Rect2(-8.0 * step, -8, 16.0 * step, 8), TT.INK, false, 2.5)
	for k in range(-7, 8):
		if k != 0:
			draw_line(Vector2(k * step, -8), Vector2(k * step, -2), TT.INK, 1.5)
	# left weight
	_weight(Vector2(-float(puzzle["left"][1]) * step, -8), "%d kg" % puzzle["left"][0], TT.BLUE, TT.ON_BLUE)
	# right weight: what the player is choosing
	var fixed: int = puzzle["fixed"]
	if choice == NONE:
		_weight(Vector2(float(fixed if puzzle["vary"] == "distance" else 4) * step, -8), "?", TT.SUNKEN, TT.INK)
	elif puzzle["vary"] == "weight":
		_weight(Vector2(float(fixed) * step, -8), "%d kg" % choice, TT.TEAL, TT.ON_TEAL)
	else:
		_weight(Vector2(float(choice) * step, -8), "%d kg" % fixed, TT.TEAL, TT.ON_TEAL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_k, _k))
	if reveal and _rt > 0.8:
		var word := "Balanced!" if tl == tr else ("The left side goes down" if tl > tr else "The right side goes down")
		_centered(30.0, "%d  vs  %d.  %s" % [tl, tr, word], 20)


func _weight(at: Vector2, text: String, fill: Color, ink: Color) -> void:
	var r := Rect2(at + Vector2(-26, -50), Vector2(52, 42))
	draw_rect(r, fill)
	draw_rect(r, TT.INK, false, 2.5)
	draw_line(at + Vector2(0, -8), at + Vector2(0, -50), TT.INK, 2.0)
	var w := TT.bold_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(TT.bold_font(), r.position + Vector2((52.0 - w) * 0.5, 27), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
