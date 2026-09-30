extends Control
## Pick a motor gear and a wheel gear. The ratio, torque and speed update live.

const TT = preload("res://scripts/tt.gd")
const Drivetrain = preload("res://scripts/drivetrain.gd")
const Analysis = preload("res://scripts/analysis.gd")

var main
var _ratio_label: Label
var _formula_label: Label
var _hint_label: Label
var _motor_value: Label
var _wheel_value: Label
var _torque_bar: Control
var _speed_bar: Control
var _stage: Control


## Draws the two gears meshing, sized by tooth count, so the ratio can be seen.
class GearStage extends Control:
	var motor_teeth := 16
	var wheel_teeth := 16
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var TT = preload("res://scripts/tt.gd")
		draw_style_box(TT.box(TT.RAISED, TT.INK, 20, 2, true), Rect2(Vector2.ZERO, size - Vector2(0, 4)))
		var unit := minf(3.4, minf((size.x - 40.0) / (2.0 * float(motor_teeth + wheel_teeth)), (size.y - 90.0) / (2.0 * float(wheel_teeth))))
		var rm := motor_teeth * unit
		var rw := wheel_teeth * unit
		var gap := rm + rw - 3.0
		var start_x := (size.x - (rm + gap + rw)) * 0.5
		var cy := size.y * 0.52
		var cm := Vector2(start_x + rm, cy)
		var cw := Vector2(cm.x + gap, cy)
		var spin := _t * 1.6
		TT.draw_gear(self, cm, rm, motor_teeth, spin, TT.TEAL, "%dT" % motor_teeth)
		var mesh_offset := PI / float(wheel_teeth)
		TT.draw_gear(self, cw, rw, wheel_teeth, PI - spin * float(motor_teeth) / float(wheel_teeth) + mesh_offset, TT.BRAND, "%dT" % wheel_teeth)
		var f := TT.bold_font()
		draw_string(f, Vector2(cm.x - rm, 30), "MOTOR GEAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TT.TEAL)
		draw_string(f, Vector2(cw.x - rw * 0.4, size.y - 14), "WHEEL GEAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TT.INK)


## A labelled gauge: the number is always shown, colour is not the only cue.
class Gauge extends Control:
	var value := 50
	var fill := Color.BLUE
	var caption := ""

	func _init() -> void:
		custom_minimum_size = Vector2(0, 26)

	func _draw() -> void:
		var TT = preload("res://scripts/tt.gd")
		var f := TT.bold_font()
		draw_string(f, Vector2(0, 19), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TT.INK)
		var track := Rect2(72, 2, size.x - 72 - 44, 22)
		draw_style_box(TT.box(TT.SUNKEN, TT.INK, 6, 2), track)
		var w := (track.size.x - 4) * clampf(value / 100.0, 0.0, 1.0)
		draw_rect(Rect2(track.position + Vector2(2, 2), Vector2(w, track.size.y - 4)), fill)
		draw_string(f, Vector2(size.x - 40, 20), str(value), HORIZONTAL_ALIGNMENT_RIGHT, 40, 20, TT.INK)


func _ready() -> void:
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 16
	root.offset_right = -16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	left.add_theme_constant_override("separation", 8)
	root.add_child(left)
	_stage = GearStage.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_stage)
	_hint_label = TT.label("", 16, TT.MUTED)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.custom_minimum_size = Vector2(0, 46)
	left.add_child(_hint_label)

	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 8)
	root.add_child(side)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var back := TT.button("<", "plain")
	back.custom_minimum_size = Vector2(48, 48)
	back.pressed.connect(func(): main.go("map"))
	head.add_child(back)
	var title := TT.label(Drivetrain.COURSES[main.course]["name"], 24, TT.INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	var found: int = main.save.owned("motor").size() + main.save.owned("wheel").size()
	var total: int = Drivetrain.MOTOR_GEARS.size() + Drivetrain.WHEEL_GEARS.size()
	var more := TT.button("Gears %d/%d" % [found, total], "energy", 16)
	more.pressed.connect(func(): main.go("workshop"))
	head.add_child(more)
	side.add_child(head)

	var motors: Array = main.save.owned("motor")
	var wheels: Array = main.save.owned("wheel")
	if not motors.has(main.motor_teeth):
		main.motor_teeth = motors[0]
	if not wheels.has(main.wheel_teeth):
		main.wheel_teeth = wheels[0]
	side.add_child(_stepper("Motor gear", motors, "motor_teeth", true))
	side.add_child(_stepper("Wheel gear", wheels, "wheel_teeth", false))

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", TT.box(TT.RAISED, TT.INK, 20, 2, true))
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 4)
	card.add_child(cv)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	_ratio_label = TT.label("", 32, TT.INK, true)
	top_row.add_child(_ratio_label)
	_formula_label = TT.label("", 14, TT.MUTED)
	_formula_label.size_flags_vertical = Control.SIZE_SHRINK_END
	top_row.add_child(_formula_label)
	cv.add_child(top_row)
	_torque_bar = Gauge.new()
	_torque_bar.caption = "TORQUE"
	_torque_bar.fill = TT.BLUE
	cv.add_child(_torque_bar)
	_speed_bar = Gauge.new()
	_speed_bar.caption = "SPEED"
	_speed_bar.fill = TT.TEAL
	cv.add_child(_speed_bar)
	side.add_child(card)

	var go := TT.button("Start race", "primary", 22)
	go.custom_minimum_size = Vector2(0, 56)
	go.pressed.connect(func(): main.start_race())
	side.add_child(go)
	go.grab_focus()
	_refresh()


func _stepper(title: String, gears: Array, prop: String, is_motor: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var name_label := TT.label(title, 16, TT.MUTED, true)
	name_label.custom_minimum_size = Vector2(96, 0)
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)
	var minus := TT.button("-", "plain", 24)
	var value := TT.label("", 24, TT.INK, true)
	value.custom_minimum_size = Vector2(64, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var plus := TT.button("+", "plain", 24)
	if is_motor:
		_motor_value = value
	else:
		_wheel_value = value
	minus.pressed.connect(func(): _step(gears, prop, -1))
	plus.pressed.connect(func(): _step(gears, prop, 1))
	row.add_child(minus)
	row.add_child(value)
	row.add_child(plus)
	return row


func _step(gears: Array, prop: String, dir: int) -> void:
	var i := gears.find(main.get(prop))
	i = clampi(i + dir, 0, gears.size() - 1)
	main.set(prop, gears[i])
	_refresh()


func _refresh() -> void:
	var m: int = main.motor_teeth
	var w: int = main.wheel_teeth
	var r: float = main.ratio()
	_motor_value.text = "%dT" % m
	_wheel_value.text = "%dT" % w
	_ratio_label.text = "Ratio %s" % Analysis.format_ratio(r)
	_formula_label.text = "%d ÷ %d" % [w, m]
	_torque_bar.value = Drivetrain.torque_score(r)
	_speed_bar.value = Drivetrain.speed_score(r)
	_torque_bar.queue_redraw()
	_speed_bar.queue_redraw()
	_stage.motor_teeth = m
	_stage.wheel_teeth = w
	var blurb: String = Drivetrain.COURSES[main.course]["blurb"]
	if r < 1.7:
		_hint_label.text = "%s Low pull. Try a bigger ratio, or find bigger gears in the Workshop." % blurb
	elif r > 6.0:
		_hint_label.text = "%s Lots of pull, but the wheels will top out." % blurb
	else:
		_hint_label.text = "%s A bigger ratio pulls harder. A smaller one is faster." % blurb
