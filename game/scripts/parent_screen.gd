extends Control
## The Parent zone: what the child has learned, and how the game treats data.

const TT = preload("res://scripts/tt.gd")
const Drivetrain = preload("res://scripts/drivetrain.gd")
const Puzzles = preload("res://scripts/puzzles.gd")

var main


func _ready() -> void:
	var root := TT.screen_column(self, 20, 12, 20, 12)
	root.add_theme_constant_override("separation", 8)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	var back := TT.button("<")
	back.pressed.connect(func(): main.go("title"))
	head.add_child(back)
	var title := TT.label("Parent zone", 28, TT.INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	var settings := TT.button("Settings")
	settings.pressed.connect(func(): main.go_with_back("settings", "parent"))
	head.add_child(settings)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	scroll.add_child(col)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	col.add_child(stats)
	stats.add_child(_stat("Time played", _duration(main.save.play_seconds)))
	stats.add_child(_stat("Courses won", "%d / %d" % [_won(), Drivetrain.course_count()]))
	stats.add_child(_stat("Stars", "%d / %d" % [_stars(), Drivetrain.course_count() * 3]))
	stats.add_child(_stat("Crates solved", "%d / %d" % [main.save.solved.size(), Puzzles.count()]))

	col.add_child(TT.label("What your child has learned", 18, TT.INK, true))
	var learned: Array = main.save.learned_concepts()
	if learned.is_empty():
		col.add_child(_para("Nothing yet. Each crate teaches one idea and shows up here."))
	for id in learned:
		var c: Dictionary = Puzzles.CONCEPTS[id]
		col.add_child(_para("%s (NGSS %s): %s" % [c["title"], c["ngss"], c["body"]]))

	col.add_child(TT.label("How the game treats your family", 18, TT.INK, true))
	col.add_child(_para("No ads. No accounts. No chat. No links out. No purchases in this version. The game collects no personal information and sends nothing over the network. Progress and settings are stored on this device only."))
	col.add_child(TT.label("Where this fits in school science", 18, TT.INK, true))
	col.add_child(_para("Forces and motion, simple machines and gears, energy, and the engineering design cycle (build, test, improve) in grades 4 to 5."))


func _stat(caption: String, value: String) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", TT.box(TT.RAISED, TT.INK, 12, 2))
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(TT.label(caption.to_upper(), 12, TT.MUTED, true))
	v.add_child(TT.label(value, 24, TT.INK, true))
	return p


func _para(text: String) -> Label:
	var l := TT.label(text, 16, TT.INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _duration(seconds: float) -> String:
	var minutes := int(seconds / 60.0)
	if minutes < 60:
		return "%d min" % minutes
	return "%dh %02dm" % [minutes / 60, minutes % 60]


func _won() -> int:
	var n := 0
	for c in Drivetrain.COURSES:
		if main.save.stars_for(c["id"]) > 0:
			n += 1
	return n


func _stars() -> int:
	var n := 0
	for c in Drivetrain.COURSES:
		n += main.save.stars_for(c["id"])
	return n
