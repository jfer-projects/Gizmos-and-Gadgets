extends Control
## Look, sound and comfort settings. Every change applies and saves at once.

const TT = preload("res://scripts/tt.gd")

var main
var _confirm_erase := false

const TOGGLES := [
	["sfx", "Sound effects"],
	["music", "Music"],
	["read_aloud", "Read aloud"],
	["large_text", "Large text"],
	["reduced_motion", "Reduced motion"],
	["pests", "Pests in the workshop"],
	["walk", "Walk around workshop"],
]
const THEME_NAMES := {"day": "Day", "night": "Night Shift", "hc": "High Contrast"}


func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_top = 12
	root.offset_right = -20
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	var back := TT.button("<")
	back.pressed.connect(func(): main.go(main.back_target()))
	head.add_child(back)
	var title := TT.label("Settings", 28, TT.INK, true)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)

	root.add_child(TT.label("Look", 14, TT.MUTED, true))
	var themes := HBoxContainer.new()
	themes.add_theme_constant_override("separation", 10)
	root.add_child(themes)
	for key in THEME_NAMES:
		var b := TT.button(THEME_NAMES[key], "primary" if main.save.settings["theme"] == key else "plain", 18)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _change("theme", key))
		themes.add_child(b)

	root.add_child(TT.label("Comfort and sound", 14, TT.MUTED, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	root.add_child(grid)
	for t in TOGGLES:
		var on: bool = main.save.settings[t[0]]
		var b := TT.button("%s: %s" % [t[1], "On" if on else "Off"], "energy" if on else "plain", 17)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _change(t[0], not main.save.settings[t[0]]))
		grid.add_child(b)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var erase := HBoxContainer.new()
	erase.add_theme_constant_override("separation", 10)
	root.add_child(erase)
	if _confirm_erase:
		var ask := TT.label("Erase all stars and gears?", 18, TT.DANGER, true)
		ask.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		erase.add_child(ask)
		var yes := TT.button("Yes, erase", "plain")
		yes.pressed.connect(func():
			main.save.reset_progress()
			main.motor_teeth = 16
			main.wheel_teeth = 16
			_confirm_erase = false
			main.go("settings"))
		erase.add_child(yes)
		var no := TT.button("Keep it", "primary")
		no.pressed.connect(func():
			_confirm_erase = false
			main.go("settings"))
		erase.add_child(no)
	else:
		var wipe := TT.button("Erase my progress", "ghost")
		wipe.pressed.connect(func():
			_confirm_erase = true
			_rebuild())
		erase.add_child(wipe)


func _change(key: String, value) -> void:
	main.save.settings[key] = value
	main.save.write()
	main.apply_settings()
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_ready()
	queue_redraw()
