extends Control

const TT = preload("res://scripts/tt.gd")

var main
var _t := 0.0


func _ready() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 48
	box.offset_top = 120
	box.offset_right = -300
	box.offset_bottom = -90
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	box.add_child(TT.label("Tinker Track", 56, TT.INK, true))
	box.add_child(TT.label("Pick the right gears. Win the race. Learn why.", 18, TT.MUTED))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	box.add_child(spacer)
	var play := TT.button("Play", "primary", 24)
	play.custom_minimum_size = Vector2(180, 64)
	play.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	play.pressed.connect(func(): main.go("map"))
	box.add_child(play)
	play.grab_focus()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var settings := TT.button("Settings", "ghost")
	settings.pressed.connect(func(): main.go_with_back("settings", "title"))
	row.add_child(settings)
	var parent := TT.button("Parent zone", "ghost")
	parent.pressed.connect(func(): main.go("gate"))
	row.add_child(parent)


func _process(delta: float) -> void:
	if TT.motion:
		_t += delta
		queue_redraw()


func _draw() -> void:
	TT.draw_grid(self, size)
	TT.draw_gear(self, Vector2(30, 30), 88, 18, _t * 0.4, TT.BRAND)
	TT.draw_gear(self, Vector2(150, -4), 40, 8, -_t * 0.4 * 18.0 / 8.0 + 0.2, TT.TEAL)
	var ground := Rect2(0, size.y - 70, size.x, 70)
	draw_rect(ground, TT.SUNKEN)
	draw_line(ground.position, ground.position + Vector2(size.x, 0), TT.INK, 2.5)
	TT.draw_car(self, Vector2(size.x - 190, size.y - 68), 2.4, 0.0, TT.BRAND, _t * 3.0, 8, 32)
