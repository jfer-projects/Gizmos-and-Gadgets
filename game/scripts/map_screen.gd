extends Control
## Pick a course. Each opens when you win the one before it.

const TT = preload("res://scripts/tt.gd")
const Drivetrain = preload("res://scripts/drivetrain.gd")
const Puzzles = preload("res://scripts/puzzles.gd")

var main

const FAMILIES := [["ground", "Cars"], ["energy", "Green"], ["air", "Planes"]]


func _ready() -> void:
	var root := TT.screen_column(self, 20, 14, 20, 14)
	root.add_theme_constant_override("separation", 10)

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

	# one tab per vehicle family
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	root.add_child(tabs)
	if main.map_family == "":
		main.map_family = _default_family()
	for fam in FAMILIES:
		var count := _won_in(fam[0])
		var t := TT.button("%s  %d/5" % [fam[1], count], "plain", 16)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var picked: bool = main.map_family == fam[0]
		var fill: Color = TT.BRAND if fam[0] == "ground" else (TT.TEAL if fam[0] == "energy" else TT.BLUE)
		var fg: Color = TT.ON_BRAND if fam[0] == "ground" else (TT.ON_TEAL if fam[0] == "energy" else TT.ON_BLUE)
		if picked:
			for state in ["normal", "hover", "focus", "pressed"]:
				t.add_theme_stylebox_override(state, TT.box(fill, TT.INK, 12, 4, true))
			for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				t.add_theme_color_override(c, fg)
		t.pressed.connect(func():
			main.map_family = fam[0]
			main.go("map"))
		tabs.add_child(t)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)
	var first_open: Button = null
	for i in Drivetrain.course_count():
		if Drivetrain.family_of(i) != main.map_family:
			continue
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
	var name_label := TT.label("%d  %s" % [i + 1, c["name"]], 19, TT.INK if open else TT.MUTED, true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(90, 0)
	v.add_child(name_label)
	var stars: int = main.save.stars_for(c["id"])
	v.add_child(TT.label("%s%s" % ["★".repeat(stars), "☆".repeat(3 - stars)], 18, TT.BRAND if stars > 0 else TT.BORDER, true))
	var blurb := TT.label(c["blurb"], 15, TT.MUTED)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	blurb.custom_minimum_size = Vector2(90, 0)
	v.add_child(blurb)
	var btn: Button = null
	if open:
		btn = TT.button("Race", "primary")
		btn.pressed.connect(func():
			main.course = i
			main.go("garage"))
		v.add_child(btn)
	else:
		var need := TT.label(_lock_reason(i), 14, TT.MUTED, true)
		need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		need.custom_minimum_size = Vector2(90, 0)
		v.add_child(need)
	return [p, btn]


func _won_in(family: String) -> int:
	var n := 0
	for i in Drivetrain.course_count():
		if Drivetrain.family_of(i) == family and main.save.stars_for(Drivetrain.COURSES[i]["id"]) > 0:
			n += 1
	return n


## Open on the family that holds the next course to race.
func _default_family() -> String:
	for i in Drivetrain.course_count():
		if main.save.course_unlocked(Drivetrain.COURSES, i) and main.save.stars_for(Drivetrain.COURSES[i]["id"]) == 0:
			return Drivetrain.family_of(i)
	return "ground"


## Why a course is shut, in words a child can act on.
func _lock_reason(i: int) -> String:
	var missing: Array = main.save.missing_parts(Drivetrain.COURSES[i]["family"])
	if not missing.is_empty():
		return "Find the %s in the Workshop." % " and the ".join(_part_names(missing))
	return "Win %s to open." % Drivetrain.COURSES[i - 1]["name"]


func _part_names(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append(String(id).replace("_", " "))
	return out
