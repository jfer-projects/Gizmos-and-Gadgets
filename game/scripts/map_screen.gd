extends Control
## Pick a course. Each opens when you win the one before it.

const TT = preload("res://scripts/tt.gd")
const Drivetrain = preload("res://scripts/drivetrain.gd")
const Puzzles = preload("res://scripts/puzzles.gd")

var main


func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_top = 14
	root.offset_right = -20
	root.offset_bottom = -14
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	var back := TT.button("<")
	back.pressed.connect(func(): main.go("title"))
	head.add_child(back)
	var title := TT.label("Choose a course", 28, TT.INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	var solved: int = main.save.solved.size()
	var codex := TT.button("Codex", "plain", 16)
	codex.pressed.connect(func(): main.go_with_back("codex", "map"))
	head.add_child(codex)
	var options := TT.button("Settings", "plain", 16)
	options.pressed.connect(func(): main.go_with_back("settings", "map"))
	head.add_child(options)
	var shop := TT.button("Workshop  %d / %d" % [solved, Puzzles.count()], "energy", 16)
	shop.pressed.connect(func(): main.go("workshop"))
	head.add_child(shop)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)
	var first_open: Button = null
	for i in Drivetrain.course_count():
		var card := _course_card(i)
		grid.add_child(card[0])
		if first_open == null and card[1] != null and main.save.stars_for(Drivetrain.COURSES[i]["id"]) == 0:
			first_open = card[1]
	if first_open != null:
		first_open.grab_focus()


## Returns [card, race_button_or_null].
func _course_card(i: int) -> Array:
	var c: Dictionary = Drivetrain.COURSES[i]
	var open: bool = main.save.course_unlocked(Drivetrain.COURSES, i)
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", TT.box(TT.RAISED if open else TT.SUNKEN, TT.INK if open else TT.BORDER, 20, 2, open))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var name_label := TT.label("%d  %s" % [i + 1, c["name"]], 20, TT.INK if open else TT.MUTED, true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var stars: int = main.save.stars_for(c["id"])
	top.add_child(TT.label("%s%s" % ["★".repeat(stars), "☆".repeat(3 - stars)], 20, TT.BRAND if stars > 0 else TT.BORDER, true))
	var blurb := TT.label(c["blurb"], 15, TT.MUTED)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(blurb)
	var btn: Button = null
	if open:
		btn = TT.button("Race", "primary")
		btn.pressed.connect(func():
			main.course = i
			main.go("garage"))
		v.add_child(btn)
	else:
		v.add_child(TT.label("Win course %d to open" % i, 15, TT.MUTED, true))
	return [p, btn]
