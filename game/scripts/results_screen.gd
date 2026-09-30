extends Control
## Win, or "why did I lose?": time margin, where it went wrong, and a hint.

const TT = preload("res://scripts/tt.gd")
const Drivetrain = preload("res://scripts/drivetrain.gd")
const Analysis = preload("res://scripts/analysis.gd")

var main


## Speed over time for you and the rival, with the problem moments marked.
class Replay extends Control:
	var player: Dictionary
	var rival: Dictionary
	var marks: Array = []
	var span := 40.0
	var top_speed := 22.0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 76)

	func _draw() -> void:
		var TT = preload("res://scripts/tt.gd")
		var DT = preload("res://scripts/drivetrain.gd")
		draw_style_box(TT.box(TT.RAISED, TT.INK, 12, 2), Rect2(Vector2.ZERO, size))
		var pad := Vector2(12, 10)
		var area := Rect2(pad, size - pad * 2.0)
		var top := top_speed
		_line(rival, TT.BLUE, area, top, 2.5)
		_line(player, TT.INK, area, top, 3.5)
		for m in marks:
			var x := area.position.x + area.size.x * clampf(float(m) / span, 0.0, 1.0)
			draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), TT.DANGER, 2.0)
			draw_circle(Vector2(x, area.position.y + 6), 7, TT.DANGER)
			draw_string(TT.bold_font(), Vector2(x - 3, area.position.y + 11), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TT.ON_DANGER)

	func _line(res: Dictionary, col: Color, area: Rect2, top_speed: float, w: float) -> void:
		var DT = preload("res://scripts/drivetrain.gd")
		var vs: PackedFloat32Array = res["vs"]
		var pts := PackedVector2Array()
		var step := 6
		var cut := vs.size()
		for i in range(0, cut, step):
			var t: float = i * DT.DT
			if t > span:
				break
			pts.append(Vector2(area.position.x + area.size.x * clampf(t / span, 0.0, 1.0), area.end.y - area.size.y * clampf(vs[i] / top_speed, 0.0, 1.0)))
		if pts.size() > 1:
			draw_polyline(pts, col, w, true)


func _ready() -> void:
	var res: Dictionary = main.result
	var ci: int = main.course
	var rival: Dictionary = Drivetrain.rival_result(ci)
	var won: bool = res["finished"] and res["time"] <= rival["time"]
	var notes: Array = Analysis.explain(res)
	main.audio.sfx("win" if won else "lose")
	var stars := Drivetrain.stars_for(ci, res["time"], res["finished"])
	main.save.record_stars(Drivetrain.COURSES[ci]["id"], stars)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_top = 14
	root.offset_right = -24
	root.offset_bottom = -14
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(titles)
	if won:
		titles.add_child(TT.label("You won!", 36, TT.INK, true))
		titles.add_child(TT.label("%.1f s vs the rival's %.1f s. Ratio %s." % [res["time"], rival["time"], Analysis.format_ratio(res["ratio"])], 18, TT.MUTED))
	elif res["finished"]:
		titles.add_child(TT.label("%.1f s behind" % (res["time"] - rival["time"]), 36, TT.INK, true))
		titles.add_child(TT.label("So close. Here is what happened." if res["time"] - rival["time"] < 2.0 else "Here is what happened.", 18, TT.MUTED))
	else:
		titles.add_child(TT.label("Not this time", 36, TT.INK, true))
		titles.add_child(TT.label("The car could not finish. Here is what happened.", 18, TT.MUTED))
	top.add_child(_stars(stars))
	var home := TT.button("Home", "ghost")
	home.text = "Courses"
	home.pressed.connect(func(): main.go("map"))
	top.add_child(home)
	var has_next: bool = won and ci + 1 < Drivetrain.course_count()
	var retry := TT.button("Next course" if has_next else ("Play again" if won else "Tweak and retry"), "primary", 20)
	retry.custom_minimum_size = Vector2(170, 52)
	retry.pressed.connect(func():
		if has_next:
			main.course = ci + 1
		main.go("garage"))
	top.add_child(retry)
	retry.grab_focus()

	var replay := Replay.new()
	replay.player = res
	replay.rival = rival
	replay.span = maxf(30.0, minf(rival["time"] + 6.0, 45.0))
	var peak := 5.0
	for arr in [res["vs"], rival["vs"]]:
		for k in range(0, arr.size(), 6):
			peak = maxf(peak, arr[k])
	replay.top_speed = peak * 1.05
	for n in notes:
		replay.marks.append(n["time"])
	root.add_child(replay)

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 12)
	root.add_child(mid)
	if notes.is_empty():
		var ok := TT.label("Nice build. Try other gears and see what changes.", 20, TT.INK)
		ok.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.add_child(ok)
	for n in notes:
		mid.add_child(_note_card(n))


func _stars(count: int) -> Control:
	var l := Label.new()
	l.text = "%s%s" % ["★".repeat(count), "☆".repeat(3 - count)]
	l.add_theme_font_size_override("font_size", 36)
	l.add_theme_color_override("font_color", TT.BRAND if count > 0 else TT.BORDER)
	l.add_theme_color_override("font_outline_color", TT.INK)
	l.add_theme_constant_override("outline_size", 6)
	l.tooltip_text = "%d of 3 stars" % count
	return l


func _note_card(n: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", TT.box(TT.DANGER_TINT, TT.DANGER, 20, 2))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(TT.label("%s · %s" % [Analysis.format_time(n["time"]), n["place"]], 14, TT.DANGER, true))
	v.add_child(TT.label(n["title"], 22, TT.INK, true))
	main.say("%s. %s" % [n["title"], n["body"]])
	var body := TT.label(n["body"], 16, TT.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	# Only suggest gears the player has actually found.
	var pair := Analysis.nearest_gears(n["suggested_ratio"], main.save.owned("motor"), main.save.owned("wheel"))
	var same: bool = pair[0] == main.motor_teeth and pair[1] == main.wheel_teeth
	var btn := TT.button("Find gears" if same else "Try %s" % Analysis.format_ratio(Drivetrain.ratio_of(pair[0], pair[1])), "energy" if same else "info")
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.pressed.connect(func():
		if same:
			main.go("workshop")
			return
		main.motor_teeth = pair[0]
		main.wheel_teeth = pair[1]
		main.go("garage"))
	v.add_child(btn)
	return p
