extends Control
## One crate puzzle: read the goal, choose a part, press Try it.

const TT = preload("res://scripts/tt.gd")
const Puzzles = preload("res://scripts/puzzles.gd")

const NONE := -999

var main
var puzzle: Dictionary
var choice: int = NONE
var tries: int = 0
var _diagram: Control
var _option_buttons: Array = []
var _try_button: Button
var _overlay: Control
var _busy := false


## Draws the gears in a row. The first gear is the driver and spins; every
## other gear follows it, so direction and speed can be seen, not just read.
class Diagram extends Control:
	var puzzle: Dictionary
	var choice: int = -999
	var reveal := false
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	## Teeth of each gear in the row, driver first.
	func chain() -> Array:
		match puzzle["kind"]:
			"direction":
				var n := 0 if choice == -999 else choice
				var row: Array = [12]
				for i in n:
					row.append(12)
				row.append(12)
				return row
			"speed":
				return [puzzle["driver"], choice if choice != -999 else 0]
			"ratio":
				return [puzzle["motor"], choice if choice != -999 else 0]
		return []

	func _draw() -> void:
		var TT = preload("res://scripts/tt.gd")
		draw_style_box(TT.box(TT.RAISED, TT.INK, 20, 2, true), Rect2(Vector2.ZERO, size - Vector2(0, 4)))
		var teeth: Array = chain()
		var unit := 3.2 if puzzle["kind"] == "direction" else 1.5
		# total width so the row can be centred
		var width := 0.0
		for i in teeth.size():
			var r := float(teeth[i]) * unit
			width += r * 2.0 - (3.0 if i > 0 else 0.0)
		var x := (size.x - width) * 0.5
		var cy := size.y * 0.4
		var prev_angle := _t * 1.2
		var prev_teeth := 0
		var f := TT.bold_font()
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
				draw_string(f, c + Vector2(-8, 8), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, TT.MUTED)
				continue
			var center := Vector2(x + r, cy)
			var angle := _t * 1.2 if i == 0 else PI + PI / float(t) - prev_angle * float(prev_teeth) / float(t)
			var dir := 1 if i % 2 == 0 else -1
			TT.draw_gear(self, center, r, t, angle, col, "%dT" % t if puzzle["kind"] != "direction" else "")
			if reveal or i == 0:
				_arrow(center, r * 0.55, dir)
			if puzzle["kind"] == "direction":
				var tag := "MOTOR" if i == 0 else ("WHEEL" if is_last else "IDLER")
				draw_string(f, Vector2(center.x - 24, cy + r + 20), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, TT.MUTED)
			prev_angle = angle
			prev_teeth = t
			x += r * 2.0 - 3.0
		if reveal and puzzle["kind"] != "direction" and choice != -999:
			var rpm := 60.0 * float(teeth[0]) / float(teeth[1])
			draw_string(f, Vector2(16, 30), "Driver 60 rpm  →  output %s rpm" % ("%d" % int(round(rpm))), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TT.INK)

	## A curved arrow showing which way a gear turns (1 = clockwise).
	func _arrow(c: Vector2, r: float, dir: int) -> void:
		var TT = preload("res://scripts/tt.gd")
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


func _ready() -> void:
	puzzle = Puzzles.by_id(main.puzzle_id)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 12
	root.offset_right = -16
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	var back := TT.button("<")
	back.pressed.connect(func(): main.go("workshop"))
	top.add_child(back)
	var goal_card := PanelContainer.new()
	goal_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_card.add_theme_stylebox_override("panel", TT.box(TT.RAISED, TT.INK, 12, 2))
	var goal := TT.label("Goal: " + puzzle["goal"], 18, TT.INK, true)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_card.add_child(goal)
	top.add_child(goal_card)
	var listen := TT.button("Listen", "info", 16)
	listen.pressed.connect(func(): main.audio.speak(puzzle["goal"]))
	top.add_child(listen)
	main.say(puzzle["goal"])

	_diagram = Diagram.new()
	_diagram.puzzle = puzzle
	_diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_diagram)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	root.add_child(bottom)
	var pick := TT.label("Pick one", 14, TT.MUTED, true)
	pick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(pick)
	for o in puzzle["options"]:
		var b := TT.button(Puzzles.option_label(puzzle, o), "plain", 20)
		b.custom_minimum_size = Vector2(96, 56)
		b.pressed.connect(func(): _pick(o))
		bottom.add_child(b)
		_option_buttons.append([o, b])
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)
	_try_button = TT.button("Try it", "energy", 22)
	_try_button.custom_minimum_size = Vector2(150, 56)
	_try_button.disabled = true
	_try_button.pressed.connect(_try)
	bottom.add_child(_try_button)
	_option_buttons[0][1].grab_focus()


func _pick(o: int) -> void:
	if _busy:
		return
	choice = o
	_diagram.choice = o
	_diagram.reveal = false
	_try_button.disabled = false
	for pair in _option_buttons:
		var picked: bool = pair[0] == o
		pair[1].add_theme_stylebox_override("normal", TT.box(TT.BRAND_TINT if picked else TT.RAISED, TT.INK, 12, 4 if picked else 2, not picked))
		pair[1].add_theme_stylebox_override("hover", TT.box(TT.BRAND_TINT if picked else TT.RAISED, TT.INK, 12, 4 if picked else 2, not picked))


func _try() -> void:
	if _busy or choice == NONE:
		return
	_busy = true
	tries += 1
	_diagram.reveal = true
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	if Puzzles.is_correct(puzzle, choice):
		_show_success()
	else:
		_show_miss()


func _overlay_shell(fill: Color, border: Color) -> VBoxContainer:
	_clear_overlay()
	_overlay = PanelContainer.new()
	_overlay.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_overlay.offset_left = 16
	_overlay.offset_right = -16
	_overlay.offset_bottom = -12
	_overlay.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_overlay.add_theme_stylebox_override("panel", TT.box(fill, border, 20, 3, true))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_overlay.add_child(v)
	add_child(_overlay)
	return v


func _clear_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null


func _show_success() -> void:
	main.audio.sfx("success")
	var concept: Dictionary = Puzzles.CONCEPTS[puzzle["concept"]]
	var reward: Dictionary = puzzle["reward"]
	var already: bool = main.save.is_solved(puzzle["id"])
	var v := _overlay_shell(TT.TEAL_TINT, TT.INK)
	v.add_child(TT.label("It works!   New concept: %s" % concept["title"], 22, TT.TEAL, true))
	var body := TT.label(concept["body"], 16, TT.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	var row := HBoxContainer.new()
	v.add_child(row)
	var formula := TT.label(concept["formula"], 16, TT.INK, true)
	formula.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	formula.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(formula)
	var label := "Back to the shelf" if already else "Collect the %dT %s gear" % [reward["teeth"], reward["kind"]]
	var collect := TT.button(label, "primary", 20)
	collect.custom_minimum_size = Vector2(240, 52)
	collect.pressed.connect(func():
		main.audio.sfx("collect")
		main.save.mark_solved(puzzle["id"])
		main.go("workshop"))
	row.add_child(collect)
	collect.grab_focus()


func _show_miss() -> void:
	main.audio.sfx("miss")
	main.say(Puzzles.describe(puzzle, choice))
	var v := _overlay_shell(TT.DANGER_TINT, TT.DANGER)
	v.add_child(TT.label("Not yet", 24, TT.INK, true))
	var what := TT.label(Puzzles.describe(puzzle, choice), 18, TT.INK)
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(what)
	if tries >= 2:
		var hint := TT.label("Hint: " + puzzle["hint"], 16, TT.MUTED, true)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)
	var again := TT.button("Try again", "info", 20)
	again.custom_minimum_size = Vector2(160, 52)
	again.pressed.connect(func():
		_clear_overlay()
		_busy = false
		_diagram.reveal = false)
	row.add_child(again)
	again.grab_focus()
